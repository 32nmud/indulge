import 'package:logging/logging.dart';
import '../../../data/models/versioned_model.dart';
import '../../../data/models/v1/property_count/property_count.dart' as v1;
import '../../../data/models/v1/reference/reference.dart' as v1;
import '../../../data/models/v1/name/name.dart' as v1;
import '../../../data/models/v1/person/person.dart' as v1;
import '../../../data/models/v1/sexual_activity_type/sexual_activity_type.dart'
    as v1;
import '../../../data/models/v1/sexual_activity_type_property/sexual_activity_type_property.dart'
    as v1;
import '../../../data/models/v1/sexual_event/sexual_event.dart' as v1;
import '../../../data/models/v1/sexual_activity/sexual_activity.dart' as v1;
import '../../../data/models/v1/sexual_activity_participant/sexual_activity_participant.dart'
    as v1;
import '../../../data/models/v2/activity_count/activity_count.dart';
import '../../../data/models/v2/reference/reference.dart';
import '../../../data/models/v2/name/name.dart';
import '../../../data/models/v2/person/person.dart';
import '../../../data/models/v2/sexual_activity_category/sexual_activity_category.dart';
import '../../../data/models/v2/sexual_activity/sexual_activity.dart';
import '../../../data/models/v2/sexual_event/sexual_event.dart';
import '../../../data/models/v2/event_activity/event_activity.dart';
import '../../../data/models/v2/activity_participant/activity_participant.dart';

/// Helper function to convert v1.Reference to v2.Reference
Reference _convertReference(v1.Reference oldRef) {
  return Reference(
    reference: oldRef.reference,
    resourceType: oldRef.resourceType,
  );
}

/// Helper function to convert v1.Name to v2.Name
Name _convertName(v1.Name oldName) {
  return Name(
    given: oldName.given,
    family: oldName.family,
    nickname: oldName.nickname,
  );
}

/// Migrator for PropertyCount (v1) to ActivityCount (v2)
class PropertyCountToActivityCountMigrator
    extends ModelMigrator<v1.PropertyCount, ActivityCount> {
  static final Logger _logger = Logger('PropertyCountToActivityCountMigrator');

  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get resourceType => 'ActivityCount';

  @override
  ActivityCount migrate(v1.PropertyCount oldModel) {
    _logger.info('Migrating PropertyCount to ActivityCount');

    try {
      final activityCount = ActivityCount(
        activityReference: _convertReference(oldModel.propertyReference),
        count: oldModel.count,
        version: 2,
      );

      if (!validate(activityCount)) {
        throw ModelMigrationException(
          message: 'Validation failed after migration',
          resourceType: resourceType,
          fromVersion: fromVersion,
          toVersion: toVersion,
        );
      }

      _logger.fine(
        'Successfully migrated PropertyCount to ActivityCount (count: ${activityCount.count})',
      );

      return activityCount;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to migrate PropertyCount to ActivityCount',
        e,
        stackTrace,
      );

      throw ModelMigrationException(
        message: 'Migration failed',
        resourceType: resourceType,
        fromVersion: fromVersion,
        toVersion: toVersion,
        cause: e,
      );
    }
  }

  @override
  bool validate(ActivityCount newModel) {
    if (newModel.count < 0) {
      _logger.warning('Invalid count value: ${newModel.count}');
      return false;
    }

    if (newModel.version != 2) {
      _logger.warning('Invalid version: ${newModel.version}');
      return false;
    }

    if (newModel.activityReference.reference.isEmpty) {
      _logger.warning('Empty activity reference');
      return false;
    }

    return true;
  }

  @override
  v1.PropertyCount deserializeV1(Map<String, dynamic> json) {
    return v1.PropertyCount.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(ActivityCount model) {
    return model.toJson();
  }
}

/// Migrator for Person (v1) to Person (v2)
/// Adds new optional fields for enhanced contact tracking
class PersonMigrator extends ModelMigrator<v1.Person, Person> {
  static final Logger _logger = Logger('PersonMigrator');

  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get resourceType => 'Person';

  @override
  Person migrate(v1.Person oldModel) {
    _logger.info('Migrating Person v1 to v2 (adding new optional fields)');

    try {
      final person = Person(
        id: oldModel.id,
        date: oldModel.date,
        lastUpdateDate: oldModel.lastUpdateDate,
        name: _convertName(oldModel.name),
        location: oldModel.location != null
            ? _convertReference(oldModel.location!)
            : null,
        birthday: oldModel.birthday,
        isSelf: oldModel.isSelf,
        // All new fields default to null, which is fine
      );

      if (!validate(person)) {
        throw ModelMigrationException(
          message: 'Validation failed after migration',
          resourceType: resourceType,
          fromVersion: fromVersion,
          toVersion: toVersion,
        );
      }

      _logger.fine('Successfully migrated Person to v2');
      return person;
    } catch (e, stackTrace) {
      _logger.severe('Failed to migrate Person', e, stackTrace);

      throw ModelMigrationException(
        message: 'Migration failed',
        resourceType: resourceType,
        fromVersion: fromVersion,
        toVersion: toVersion,
        cause: e,
      );
    }
  }

  @override
  bool validate(Person newModel) {
    if (newModel.id.isEmpty) {
      _logger.warning('Empty person ID');
      return false;
    }
    return true;
  }

  @override
  v1.Person deserializeV1(Map<String, dynamic> json) {
    return v1.Person.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(Person model) {
    return model.toJson();
  }
}

/// Migrator for SexualActivityType (v1) to SexualActivityCategory (v2)
/// Renames 'properties' field to 'activities'
class SexualActivityTypeToSexualActivityCategoryMigrator
    extends ModelMigrator<v1.SexualActivityType, SexualActivityCategory> {
  static final Logger _logger = Logger(
    'SexualActivityTypeToSexualActivityCategoryMigrator',
  );

  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get resourceType => 'SexualActivityCategory';

  @override
  SexualActivityCategory migrate(v1.SexualActivityType oldModel) {
    _logger.info('Migrating SexualActivityType to SexualActivityCategory');

    try {
      final activityCategory = SexualActivityCategory(
        id: oldModel.id,
        lastUpdateDate: oldModel.lastUpdateDate,
        name: oldModel.name,
        displayCharacter: oldModel.displayCharacter,
        minParticipants: oldModel.minParticipants,
        maxParticipants: oldModel.maxParticipants,
        activities: oldModel.properties.map(_convertReference).toList(),
        requiresPartner: oldModel.requiresPartner,
      );

      if (!validate(activityCategory)) {
        throw ModelMigrationException(
          message: 'Validation failed after migration',
          resourceType: resourceType,
          fromVersion: fromVersion,
          toVersion: toVersion,
        );
      }

      _logger.fine(
        'Successfully migrated SexualActivityType to SexualActivityCategory: ${activityCategory.name}',
      );
      return activityCategory;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to migrate SexualActivityType to SexualActivityCategory',
        e,
        stackTrace,
      );

      throw ModelMigrationException(
        message: 'Migration failed',
        resourceType: resourceType,
        fromVersion: fromVersion,
        toVersion: toVersion,
        cause: e,
      );
    }
  }

  @override
  bool validate(SexualActivityCategory newModel) {
    if (newModel.id.isEmpty) {
      _logger.warning('Empty activity category ID');
      return false;
    }

    if (newModel.name.isEmpty) {
      _logger.warning('Empty activity category name');
      return false;
    }

    return true;
  }

  @override
  v1.SexualActivityType deserializeV1(Map<String, dynamic> json) {
    return v1.SexualActivityType.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(SexualActivityCategory model) {
    return model.toJson();
  }
}

/// Migrator for SexualActivityTypeProperty (v1) to SexualActivity (v2)
/// Simple version update - no field changes
class SexualActivityTypePropertyToSexualActivityMigrator
    extends ModelMigrator<v1.SexualActivityTypeProperty, SexualActivity> {
  static final Logger _logger = Logger(
    'SexualActivityTypePropertyToSexualActivityMigrator',
  );

  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get resourceType => 'SexualActivity';

  @override
  SexualActivity migrate(v1.SexualActivityTypeProperty oldModel) {
    _logger.info('Migrating SexualActivityTypeProperty to SexualActivity');

    try {
      final activity = SexualActivity(
        id: oldModel.id,
        name: oldModel.name,
        displayCharacter: oldModel.displayCharacter,
        canHaveMultipleParticipants: oldModel.canHaveMultipleParticipants,
        isRisky: oldModel.isRisky,
        requiresPartner: oldModel.requiresPartner,
      );

      if (!validate(activity)) {
        throw ModelMigrationException(
          message: 'Validation failed after migration',
          resourceType: resourceType,
          fromVersion: fromVersion,
          toVersion: toVersion,
        );
      }

      _logger.fine('Successfully migrated to SexualActivity: ${activity.name}');
      return activity;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to migrate SexualActivityTypeProperty to SexualActivity',
        e,
        stackTrace,
      );

      throw ModelMigrationException(
        message: 'Migration failed',
        resourceType: resourceType,
        fromVersion: fromVersion,
        toVersion: toVersion,
        cause: e,
      );
    }
  }

  @override
  bool validate(SexualActivity newModel) {
    if (newModel.id.isEmpty) {
      _logger.warning('Empty activity ID');
      return false;
    }

    if (newModel.name.isEmpty) {
      _logger.warning('Empty activity name');
      return false;
    }

    return true;
  }

  @override
  v1.SexualActivityTypeProperty deserializeV1(Map<String, dynamic> json) {
    return v1.SexualActivityTypeProperty.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(SexualActivity model) {
    return model.toJson();
  }
}

/// Migrator for SexualEvent (v1) to SexualEvent (v2)
/// Complex nested transformation of activities and participants
class SexualEventMigrator extends ModelMigrator<v1.SexualEvent, SexualEvent> {
  static final Logger _logger = Logger('SexualEventMigrator');

  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get resourceType => 'SexualEvent';

  @override
  SexualEvent migrate(v1.SexualEvent oldModel) {
    _logger.info('Migrating SexualEvent v1 to v2');

    try {
      final sexualEvent = SexualEvent(
        id: oldModel.id,
        date: oldModel.date,
        lastModifiedDate: oldModel.lastModifiedDate,
        activities: oldModel.activities
            .map((a) => _migrateActivity(a))
            .toList(),
        notes: null, // New field in v2, defaults to null
      );

      if (!validate(sexualEvent)) {
        throw ModelMigrationException(
          message: 'Validation failed after migration',
          resourceType: resourceType,
          fromVersion: fromVersion,
          toVersion: toVersion,
        );
      }

      _logger.fine('Successfully migrated SexualEvent to v2');
      return sexualEvent;
    } catch (e, stackTrace) {
      _logger.severe('Failed to migrate SexualEvent', e, stackTrace);

      throw ModelMigrationException(
        message: 'Migration failed',
        resourceType: resourceType,
        fromVersion: fromVersion,
        toVersion: toVersion,
        cause: e,
      );
    }
  }

  EventActivity _migrateActivity(v1.SexualActivity oldActivity) {
    return EventActivity(
      category: _convertReference(oldActivity.type),
      participants: oldActivity.participants
          .map((p) => _migrateParticipant(p))
          .toList(),
    );
  }

  ActivityParticipant _migrateParticipant(
    v1.SexualActivityParticipant oldParticipant,
  ) {
    return ActivityParticipant(
      participant: _convertReference(oldParticipant.participant),
      activityCounts: oldParticipant.propertyCounts
          .map((c) => _migratePropertyCount(c))
          .toList(),
    );
  }

  ActivityCount _migratePropertyCount(v1.PropertyCount oldCount) {
    return ActivityCount(
      activityReference: _convertReference(oldCount.propertyReference),
      count: oldCount.count,
      version: 2,
    );
  }

  @override
  bool validate(SexualEvent newModel) {
    if (newModel.id.isEmpty) {
      _logger.warning('Empty sexual event ID');
      return false;
    }

    if (newModel.activities.isEmpty) {
      _logger.warning('Sexual event has no activities');
      return false;
    }

    return true;
  }

  @override
  v1.SexualEvent deserializeV1(Map<String, dynamic> json) {
    return v1.SexualEvent.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(SexualEvent model) {
    return model.toJson();
  }
}

/// Registry of all available migrators
class MigratorRegistry {
  static final Logger _logger = Logger('MigratorRegistry');

  static final Map<String, List<ModelMigrator>> _migrators = {
    'PropertyCount': [PropertyCountToActivityCountMigrator()],
    'ActivityCount': [PropertyCountToActivityCountMigrator()],
    'Person': [PersonMigrator()],
    // New v2 resourceType names
    'SexualActivityCategory': [
      SexualActivityTypeToSexualActivityCategoryMigrator(),
    ],
    'SexualActivity': [SexualActivityTypePropertyToSexualActivityMigrator()],
    // Old v1 resourceType names (for backwards compatibility during migration)
    'SexualActivityType': [
      SexualActivityTypeToSexualActivityCategoryMigrator(),
    ],
    'SexualActivityTypeProperty': [
      SexualActivityTypePropertyToSexualActivityMigrator(),
    ],
    'SexualEvent': [SexualEventMigrator()],
  };

  /// Gets the appropriate migrator for a given resource type and version jump
  static ModelMigrator? getMigrator(
    String resourceType,
    int fromVersion,
    int toVersion,
  ) {
    final migrators = _migrators[resourceType];
    if (migrators == null) {
      _logger.warning('No migrators found for resource type: $resourceType');
      return null;
    }

    for (final migrator in migrators) {
      if (migrator.fromVersion == fromVersion &&
          migrator.toVersion == toVersion) {
        return migrator;
      }
    }

    _logger.warning(
      'No migrator found for $resourceType from v$fromVersion to v$toVersion',
    );
    return null;
  }

  /// Checks if migration is available for a resource type
  static bool canMigrate(String resourceType, int fromVersion, int toVersion) {
    return getMigrator(resourceType, fromVersion, toVersion) != null;
  }

  /// Gets all available migrators for a resource type
  static List<ModelMigrator> getMigratorsForType(String resourceType) {
    return _migrators[resourceType] ?? [];
  }
}
