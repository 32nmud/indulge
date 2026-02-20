import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import '../../../data/models/versioned_model.dart';
import '../../../data/models/v1/property_count/property_count.dart' as v1;
import '../../../data/models/v1/person/person.dart' as v1_person;

import '../../../data/models/v1/sexual_activity_type/sexual_activity_type.dart'
    as v1_activity_type;
import '../../../data/models/v1/sexual_activity_type_property/sexual_activity_type_property.dart'
    as v1_activity_prop;
import '../../../data/models/v1/sexual_event/sexual_event.dart' as v1_event;
import '../../../data/models/v2/activity_count/activity_count.dart';
import '../../../data/models/v2/person/person.dart';
import '../../../data/models/v2/sexual_activity/sexual_activity.dart';
import '../../../data/models/v2/sexual_activity_category/sexual_activity_category.dart';
import '../../../data/models/v2/sexual_event/sexual_event.dart';
import '../../../data/models/v2/clinical_event/clinical_event.dart';
import 'migrators.dart';

/// Central service for handling model version migrations
class MigrationService {
  static final Logger _logger = Logger('MigrationService');

  /// The current/latest version of all models
  static const int currentVersion = ModelVersionMigration.currentVersion;

  /// Migrates a model to the latest version if needed
  ///
  /// This method:
  /// 1. Checks the version of the incoming JSON data
  /// 2. If already at current version, deserializes directly
  /// 3. If older version, performs iterative migration steps (1->2, 2->3, ...)
  ///    using registered migrators until it reaches `currentVersion`.
  ///
  /// Usage:
  /// ```dart
  /// final activityCount = await MigrationService.migrateIfNeeded<ActivityCount>(
  ///   jsonData,
  ///   'PropertyCount', // or 'ActivityCount'
  /// );
  /// ```
  static Future<T> migrateIfNeeded<T>(
    Map<String, dynamic> json,
    String resourceType,
  ) async {
    int version = ModelVersionMigration.getVersion(json);

    _logger.fine(
      'Processing $resourceType with version $version (current: $currentVersion)',
    );

    // Heuristic: when a document is missing an explicit version (defaults to v1),
    // try to detect whether its JSON shape actually corresponds to a v2 model.
    // If so, treat it as v2 so the v2 deserializer / migrators are used instead
    // of forcing a v1->v2 migrator that may be unnecessary.
    if (version == 1) {
      try {
        final maybe = json;
        bool looksLikeV2 = false;
        switch (resourceType) {
          case 'SexualActivity':
            looksLikeV2 =
                maybe.containsKey('isRisky') ||
                maybe.containsKey('stiRisk') ||
                maybe.containsKey('healthRisk') ||
                maybe.containsKey('canHaveMultipleParticipants');
            break;
          case 'SexualActivityCategory':
            looksLikeV2 =
                maybe.containsKey('activities') ||
                maybe.containsKey('displayCharacter') ||
                maybe.containsKey('requiresPartner');
            break;
          case 'Person':
            // v2 Person uses a singular `name` object and includes fields such
            // as `date`, `isSelf`, or optional `imageBytes`. Check for those
            // keys rather than older v1-style collections.
            looksLikeV2 =
                maybe.containsKey('name') ||
                maybe.containsKey('date') ||
                maybe.containsKey('isSelf') ||
                maybe.containsKey('imageBytes');
            break;
          case 'ClinicalEvent':
            looksLikeV2 =
                maybe.containsKey('tests') && maybe.containsKey('date');
            break;
          case 'SexualEvent':
            looksLikeV2 =
                maybe.containsKey('activities') && maybe.containsKey('date');
            break;
          default:
            looksLikeV2 = false;
        }

        if (looksLikeV2) {
          _logger.fine(
            'Detected v2-shaped JSON for $resourceType despite missing version; treating as v2',
          );
          version = 2;
        }
      } catch (_) {
        // If any detection error occurs, fall back to declared version.
      }
    }

    // Already at current version
    if (version == currentVersion) {
      _logger.fine('$resourceType is already at version $currentVersion');
      return _deserializeV2<T>(json, resourceType);
    }

    // Future version (shouldn't happen, but handle gracefully)
    if (version > currentVersion) {
      _logger.warning(
        '$resourceType has version $version which is newer than current version $currentVersion',
      );

      throw ModelMigrationException(
        message:
            'Model version $version is newer than supported version $currentVersion',
        resourceType: resourceType,
        fromVersion: version,
        toVersion: currentVersion,
      );
    }

    // Needs migration (iterative multi-step support)
    if (version < currentVersion) {
      _logger.info(
        'Migrating $resourceType from v$version to v$currentVersion',
      );

      try {
        // Start by deserializing the incoming JSON into the model at its declared version.
        // For legacy (v1) documents, use _deserializeV1. For v2 documents, use _deserializeV2.
        dynamic currentModel;
        int currentVersionPtr = version;

        if (currentVersionPtr == 1) {
          currentModel = _deserializeV1(json, resourceType);
        } else if (currentVersionPtr == 2) {
          currentModel = _deserializeV2<dynamic>(json, resourceType);
        } else {
          // Unrecognized older version - defensive fallback
          throw ModelMigrationException(
            message: 'Unsupported document version: $currentVersionPtr',
            resourceType: resourceType,
            fromVersion: currentVersionPtr,
            toVersion: currentVersion,
          );
        }

        // Iteratively apply migrators for each version step until we reach currentVersion
        while (currentVersionPtr < currentVersion) {
          final fromVer = currentVersionPtr;
          final toVer = currentVersionPtr + 1;

          _logger.fine(
            'Attempting migration for $resourceType v$fromVer -> v$toVer',
          );

          final migrator = MigratorRegistry.getMigrator(
            resourceType,
            fromVer,
            toVer,
          );

          if (migrator == null) {
            // No migrator available for this step — fail clearly
            throw ModelMigrationException(
              message:
                  'No migrator available for $resourceType v$fromVer -> v$toVer',
              resourceType: resourceType,
              fromVersion: fromVer,
              toVersion: toVer,
            );
          }

          // Preserve the current resource type so we can log the transition if
          // the migrator renames the resource type as part of the upgrade.
          final prevResourceType = resourceType;

          // If the migrator expects a deserialized v1 model via deserializeV1,
          // but our currentModel is still JSON (rare for some flows), ensure
          // we pass the expected object. Our deserializeV1 implementations accept
          // JSON maps and will return the appropriate model; many migrators
          // also accept model instances directly.
          dynamic modelToMigrate = currentModel;
          try {
            final migrated = migrator.migrate(modelToMigrate);
            currentModel = migrated;

            // Update the resourceType for the next migration step in case the
            // migrator changes the canonical name (e.g. PropertyCount -> ActivityCount).
            resourceType = migrator.resourceType;

            currentVersionPtr = toVer;
            _logger.fine(
              'Migrated $prevResourceType -> $resourceType to v$currentVersionPtr',
            );
          } catch (e, st) {
            _logger.severe(
              'Migration failed for $prevResourceType v$fromVer -> v$toVer',
              e,
              st,
            );
            throw ModelMigrationException(
              message: 'Migration failed: $e',
              resourceType: prevResourceType,
              fromVersion: fromVer,
              toVersion: toVer,
              cause: e,
            );
          }
        }

        // Final model should now be at currentVersion; return it
        return currentModel as T;
      } catch (e) {
        if (e is ModelMigrationException) rethrow;

        _logger.severe('Unexpected migration error for $resourceType: $e');
        throw ModelMigrationException(
          message: 'Migration failed',
          resourceType: resourceType,
          fromVersion: version,
          toVersion: currentVersion,
          cause: e,
        );
      }
    }

    // Fallback (should be unreachable)
    throw ModelMigrationException(
      message: 'Unhandled migration path for $resourceType',
      resourceType: resourceType,
      fromVersion: version,
      toVersion: currentVersion,
    );
  }

  /// Deserializes a v1 model from JSON
  static dynamic _deserializeV1(
    Map<String, dynamic> json,
    String resourceType,
  ) {
    switch (resourceType) {
      case 'PropertyCount':
      case 'ActivityCount': // Accept either name for v1
        return v1.PropertyCount.fromJson(json);

      // v1 person
      case 'Person':
        return v1_person.Person.fromJson(json);

      // v1 sexual activity property -> v1 model used when migrating to v2
      case 'SexualActivityTypeProperty':
      case 'SexualActivity': // some older backups may reference this name
        return v1_activity_prop.SexualActivityTypeProperty.fromJson(json);

      // v1 sexual activity type
      case 'SexualActivityType':
      case 'SexualActivityCategory': // accept v2 name as a fallback
        return v1_activity_type.SexualActivityType.fromJson(json);

      // v1 sexual event
      case 'SexualEvent':
        return v1_event.SexualEvent.fromJson(json);

      // v1 clinical event (some older backups labeled these as ClinicalEvent)
      case 'ClinicalEvent':
        // Try to deserialize using the v2 ClinicalEvent shape as a pragmatic fallback.
        // This allows import of legacy backups that included clinical records without
        // an explicit v2/v3-specific format. If the JSON differs significantly this
        // may still fail and surface a migration error.
        return ClinicalEvent.fromJson(json);

      default:
        throw ModelMigrationException(
          message: 'Unknown v1 resource type: $resourceType',
          resourceType: resourceType,
          fromVersion: 1,
          toVersion: currentVersion,
        );
    }
  }

  /// Deserializes a v2 model from JSON
  static T _deserializeV2<T>(Map<String, dynamic> json, String resourceType) {
    switch (resourceType) {
      case 'ActivityCount':
        return ActivityCount.fromJson(json) as T;

      case 'Person':
        return Person.fromJson(json) as T;

      case 'SexualActivity':
        return SexualActivity.fromJson(json) as T;

      case 'SexualActivityCategory':
        return SexualActivityCategory.fromJson(json) as T;

      case 'SexualEvent':
        return SexualEvent.fromJson(json) as T;

      case 'ClinicalEvent':
        return ClinicalEvent.fromJson(json) as T;

      default:
        throw ModelMigrationException(
          message: 'Unknown v2 resource type: $resourceType',
          resourceType: resourceType,
          fromVersion: currentVersion,
          toVersion: currentVersion,
        );
    }
  }

  /// Checks if a JSON document needs migration
  static bool needsMigration(Map<String, dynamic> json) {
    return ModelVersionMigration.needsMigration(json);
  }

  /// Gets the version of a JSON document
  static int getVersion(Map<String, dynamic> json) {
    return ModelVersionMigration.getVersion(json);
  }

  /// Migrates a list of models
  static Future<List<T>> migrateListIfNeeded<T>(
    List<Map<String, dynamic>> jsonList,
    String resourceType,
  ) async {
    final results = <T>[];

    for (final json in jsonList) {
      final migrated = await migrateIfNeeded<T>(json, resourceType);
      results.add(migrated);
    }

    return results;
  }

  /// Creates migration metadata to attach to migrated documents
  static Map<String, dynamic> createMigrationMetadata(
    int fromVersion,
    int toVersion,
  ) {
    return ModelVersionMigration.createMigrationMetadata(
      fromVersion,
      toVersion,
    );
  }

  /// -------------------------------------------------------------------------
  /// Database schema helpers
  ///
  /// These helpers allow callers to ensure that required schema elements for
  /// v2 models (e.g. `clinical_event` table and metadata table) exist. This is
  /// useful as a defensive fallback in environments where automatic migration
  /// may not have executed (or failed) before repository operations run.
  /// -------------------------------------------------------------------------

  /// Ensure the `clinical_event` table and an index on `date` exist.
  /// This is idempotent and safe to call on newer databases.
  static Future<void> ensureClinicalEventTableExists(Database db) async {
    // Create the clinical_event table if it doesn't exist.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clinical_event (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        last_modified TEXT,
        json TEXT NOT NULL
      )
    ''');

    // Create an index on date to speed up queries used by the UI.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clinical_event_date ON clinical_event(date)',
    );
  }

  /// Ensure a lightweight metadata table exists to track schema/migration state.
  /// Some code paths rely on this table being present; creating it here is
  /// defensive and idempotent.
  static Future<void> ensureDatabaseMetadataTableExists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS database_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  /// Combined helper that attempts to ensure v2 schema elements are present.
  /// Callers (e.g. DB open logic) should call this after opening the DB to
  /// guarantee required tables exist even if migrations did not run.
  static Future<void> ensureV2SchemaElements(Database db) async {
    await ensureDatabaseMetadataTableExists(db);
    await ensureClinicalEventTableExists(db);
  }
}
