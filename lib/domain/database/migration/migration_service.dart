import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import '../../../data/models/versioned_model.dart';
import '../../../data/models/v1/property_count/property_count.dart' as v1;
import '../../../data/models/v2/activity_count/activity_count.dart';
import 'v1_to_v2_migrators.dart';

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
  /// 3. If older version, deserializes as old model, migrates, returns new model
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
    final version = ModelVersionMigration.getVersion(json);

    _logger.fine(
      'Processing $resourceType with version $version (current: $currentVersion)',
    );

    // Already at current version
    if (version == currentVersion) {
      _logger.fine('$resourceType is already at version $currentVersion');
      return _deserializeV2<T>(json, resourceType);
    }

    // Needs migration
    if (version < currentVersion) {
      _logger.info(
        'Migrating $resourceType from v$version to v$currentVersion',
      );

      // Deserialize as v1
      final v1Model = _deserializeV1(json, resourceType);

      // Migrate to v2
      final v2Model = await _migrateToV2(v1Model, resourceType);

      return v2Model as T;
    }

    // Future version (shouldn't happen, but handle gracefully)
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

  /// Deserializes a v1 model from JSON
  static dynamic _deserializeV1(
    Map<String, dynamic> json,
    String resourceType,
  ) {
    switch (resourceType) {
      case 'PropertyCount':
      case 'ActivityCount': // Accept either name for v1
        return v1.PropertyCount.fromJson(json);

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

      default:
        throw ModelMigrationException(
          message: 'Unknown v2 resource type: $resourceType',
          resourceType: resourceType,
          fromVersion: currentVersion,
          toVersion: currentVersion,
        );
    }
  }

  /// Migrates a v1 model to v2
  static Future<dynamic> _migrateToV2(
    dynamic v1Model,
    String resourceType,
  ) async {
    // Get the appropriate migrator
    final migrator = MigratorRegistry.getMigrator(resourceType, 1, 2);

    if (migrator == null) {
      throw ModelMigrationException(
        message: 'No migrator available for $resourceType v1 -> v2',
        resourceType: resourceType,
        fromVersion: 1,
        toVersion: 2,
      );
    }

    try {
      final v2Model = migrator.migrate(v1Model);
      _logger.fine('Successfully migrated $resourceType to v2');
      return v2Model;
    } catch (e, stackTrace) {
      _logger.severe('Migration failed for $resourceType', e, stackTrace);

      if (e is ModelMigrationException) {
        rethrow;
      }

      throw ModelMigrationException(
        message: 'Migration failed',
        resourceType: resourceType,
        fromVersion: 1,
        toVersion: 2,
        cause: e,
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
