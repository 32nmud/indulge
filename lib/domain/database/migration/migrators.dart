// Migration helpers and migrators
// This file implements typed migrators for v1->v2 and v2->v3 model transitions.
// The goal is to keep strong typing for migrators while retaining the layout
// and registry shape previously used.

import 'package:logging/logging.dart';

import '../../../data/models/v1/property_count/property_count.dart'
    as v1_property_count;
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
import '../../../data/models/v2/reference/reference.dart';
import '../../../data/models/v2/event_activity/event_activity.dart';
import '../../../data/models/v2/activity_participant/activity_participant.dart';

import '../../../data/models/v3/sexual_activity/sexual_activity.dart'
    as v3_sexual_activity;

/// Base class for migrators
abstract class ModelMigrator<F, T> {
  int get fromVersion;
  int get toVersion;
  String get resourceType;

  T migrate(F oldModel);

  bool validate(T newModel);

  // JSON helpers used by the JSON-based migration flows
  F deserializeV1(Map<String, dynamic> json);
  Map<String, dynamic> serializeV2(T model);
}

// -----------------------------------------------------------------
// v1 -> v2 migrators (typed implementations)
// -----------------------------------------------------------------

/// Migrator: PropertyCount (v1) -> ActivityCount (v2)
class PropertyCountToActivityCountMigrator
    extends ModelMigrator<v1_property_count.PropertyCount, ActivityCount> {
  static final Logger _logger = Logger('PropertyCountToActivityCountMigrator');

  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get resourceType => 'PropertyCount';

  @override
  ActivityCount migrate(v1_property_count.PropertyCount oldModel) {
    _logger.info('Migrating PropertyCount to ActivityCount');

    final activityCount = ActivityCount(
      activityReference: Reference(
        reference: oldModel.propertyReference.reference,
      ),
      count: oldModel.count,
      version: 2,
    );

    if (!validate(activityCount)) {
      throw Exception('Validation failed after ActivityCount migration');
    }

    return activityCount;
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
  v1_property_count.PropertyCount deserializeV1(Map<String, dynamic> json) {
    return v1_property_count.PropertyCount.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(ActivityCount model) {
    return model.toJson();
  }
}

/// Person v1 -> v2 migrator
class PersonMigrator extends ModelMigrator<v1_person.Person, Person> {
  static final Logger _logger = Logger('PersonMigrator');

  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get resourceType => 'Person';

  @override
  Person migrate(v1_person.Person oldModel) {
    _logger.info(
      'Migrating Person v1 to v2 (populate new optional fields as null)',
    );

    final person = Person(
      id: oldModel.id,
      date: oldModel.date,
      lastUpdateDate: oldModel.lastUpdateDate,
      name: oldModel.name,
      location: oldModel.location,
      birthday: oldModel.birthday,
      isSelf: oldModel.isSelf,
      // v2-specific optional fields left null/default
    );

    if (!validate(person)) {
      throw Exception('Validation failed after Person migration');
    }

    return person;
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
  v1_person.Person deserializeV1(Map<String, dynamic> json) {
    return v1_person.Person.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(Person model) {
    return model.toJson();
  }
}

/// SexualActivityType (v1) -> SexualActivityCategory (v2)
class SexualActivityTypeToSexualActivityCategoryMigrator
    extends
        ModelMigrator<
          v1_activity_type.SexualActivityType,
          SexualActivityCategory
        > {
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
  SexualActivityCategory migrate(v1_activity_type.SexualActivityType oldModel) {
    _logger.info('Migrating SexualActivityType to SexualActivityCategory');

    final activities = oldModel.properties
        .map(
          (r) =>
              Reference(reference: r.reference, resourceType: 'SexualActivity'),
        )
        .toList();

    final category = SexualActivityCategory(
      id: oldModel.id,
      lastUpdateDate: oldModel.lastUpdateDate,
      name: oldModel.name,
      displayCharacter: oldModel.displayCharacter,
      minParticipants: oldModel.minParticipants,
      maxParticipants: oldModel.maxParticipants,
      activities: activities,
      requiresPartner: oldModel.requiresPartner,
    );

    if (!validate(category)) {
      throw Exception(
        'Validation failed after SexualActivityCategory migration',
      );
    }
    return category;
  }

  @override
  bool validate(SexualActivityCategory newModel) {
    if (newModel.id.isEmpty) return false;
    if (newModel.name.isEmpty) return false;
    return true;
  }

  @override
  v1_activity_type.SexualActivityType deserializeV1(Map<String, dynamic> json) {
    return v1_activity_type.SexualActivityType.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(SexualActivityCategory model) {
    return model.toJson();
  }
}

/// SexualActivityTypeProperty (v1) -> SexualActivity (v2)
class SexualActivityTypePropertyToSexualActivityMigrator
    extends
        ModelMigrator<
          v1_activity_prop.SexualActivityTypeProperty,
          SexualActivity
        > {
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
  SexualActivity migrate(v1_activity_prop.SexualActivityTypeProperty oldModel) {
    _logger.info('Migrating SexualActivityTypeProperty to SexualActivity');

    final activity = SexualActivity(
      id: oldModel.id,
      name: oldModel.name,
      displayCharacter: oldModel.displayCharacter,
      canHaveMultipleParticipants: oldModel.canHaveMultipleParticipants,
      isRisky: oldModel.isRisky,
      requiresPartner: oldModel.requiresPartner,
    );

    if (!validate(activity))
      throw Exception('Validation failed after SexualActivity migration');
    return activity;
  }

  @override
  bool validate(SexualActivity newModel) {
    if (newModel.id.isEmpty) return false;
    if (newModel.name.isEmpty) return false;
    return true;
  }

  @override
  v1_activity_prop.SexualActivityTypeProperty deserializeV1(
    Map<String, dynamic> json,
  ) {
    return v1_activity_prop.SexualActivityTypeProperty.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(SexualActivity model) {
    return model.toJson();
  }
}

/// SexualEvent v1 -> v2 migrator
class SexualEventMigrator
    extends ModelMigrator<v1_event.SexualEvent, SexualEvent> {
  static final Logger _logger = Logger('SexualEventMigrator');

  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get resourceType => 'SexualEvent';

  @override
  SexualEvent migrate(v1_event.SexualEvent oldModel) {
    _logger.info('Migrating SexualEvent v1 to v2');

    final activities = oldModel.activities.map((a) {
      // Convert v1.SexualActivity -> v2.EventActivity
      final participants = a.participants.map((p) {
        final counts = p.propertyCounts.map((pc) {
          return ActivityCount(
            activityReference: Reference(
              reference: pc.propertyReference.reference,
              resourceType: 'SexualActivity',
            ),
            count: pc.count,
            version: 2,
          );
        }).toList();

        return ActivityParticipant(
          participant: Reference(
            reference: p.participant.reference,
            resourceType: p.participant.resourceType,
          ),
          activityCounts: counts,
        );
      }).toList();

      return EventActivity(
        category: Reference(
          reference: a.type.reference,
          resourceType: 'SexualActivityCategory',
        ),
        participants: participants,
      );
    }).toList();

    final migrated = SexualEvent(
      id: oldModel.id,
      date: oldModel.date,
      lastModifiedDate: oldModel.lastModifiedDate,
      activities: activities,
      // v1 event shape does not include `notes`; set notes to null for v2 objects
      notes: null,
    );

    if (!validate(migrated))
      throw Exception('Validation failed after SexualEvent migration');
    return migrated;
  }

  @override
  bool validate(SexualEvent newModel) {
    if (newModel.id.isEmpty) return false;
    if (newModel.activities.isEmpty) return false;
    return true;
  }

  @override
  v1_event.SexualEvent deserializeV1(Map<String, dynamic> json) {
    return v1_event.SexualEvent.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(SexualEvent model) {
    return model.toJson();
  }
}

// -----------------------------------------------------------------
// v2 -> v3 migrators (typed where appropriate)
// -----------------------------------------------------------------

/// SexualActivity v2 -> v3 migrator (typed)
class SexualActivityV2ToV3Migrator
    extends ModelMigrator<SexualActivity, v3_sexual_activity.SexualActivity> {
  static final Logger _logger = Logger('SexualActivityV2ToV3Migrator');

  @override
  int get fromVersion => 2;

  @override
  int get toVersion => 3;

  @override
  String get resourceType => 'SexualActivity';

  @override
  v3_sexual_activity.SexualActivity migrate(SexualActivity oldModel) {
    _logger.info(
      'Migrating SexualActivity v2 to v3 (split isRisky into stiRisk and healthRisk)',
    );

    final activity = v3_sexual_activity.SexualActivity(
      id: oldModel.id,
      name: oldModel.name,
      displayCharacter: oldModel.displayCharacter,
      canHaveMultipleParticipants: oldModel.canHaveMultipleParticipants,
      requiresPartner: oldModel.requiresPartner,
      stiRisk: oldModel.isRisky,
      healthRisk: oldModel.isRisky,
    );

    if (!validate(activity))
      throw Exception('Validation failed after SexualActivity v2->v3');
    return activity;
  }

  @override
  bool validate(v3_sexual_activity.SexualActivity newModel) {
    if (newModel.id.isEmpty) return false;
    if (newModel.name.isEmpty) return false;
    return true;
  }

  @override
  SexualActivity deserializeV1(Map<String, dynamic> json) {
    return SexualActivity.fromJson(json);
  }

  @override
  Map<String, dynamic> serializeV2(v3_sexual_activity.SexualActivity model) {
    return model.toJson();
  }
}

/// Identity migrator for ActivityCount v2 -> v3
class ActivityCountV2ToV3Migrator
    extends ModelMigrator<ActivityCount, ActivityCount> {
  static final Logger _logger = Logger('ActivityCountV2ToV3Migrator');

  @override
  int get fromVersion => 2;

  @override
  int get toVersion => 3;

  @override
  String get resourceType => 'ActivityCount';

  @override
  ActivityCount migrate(ActivityCount oldModel) {
    _logger.info('Migrating ActivityCount v2 to v3 (identity)');

    final migrated = ActivityCount(
      activityReference: oldModel.activityReference,
      count: oldModel.count,
      version: 3,
    );

    if (!validate(migrated))
      throw Exception('Validation failed for ActivityCount v2->v3');
    return migrated;
  }

  @override
  bool validate(ActivityCount newModel) {
    if (newModel.count < 0) return false;
    if (newModel.version != 3) return false;
    if (newModel.activityReference.reference.isEmpty) return false;
    return true;
  }

  @override
  ActivityCount deserializeV1(Map<String, dynamic> json) =>
      ActivityCount.fromJson(json);

  @override
  Map<String, dynamic> serializeV2(ActivityCount model) => model.toJson();
}

/// ClinicalEvent v1 -> v2 identity migrator
class ClinicalEventV1ToV2Migrator
    extends ModelMigrator<ClinicalEvent, ClinicalEvent> {
  static final Logger _logger = Logger('ClinicalEventV1ToV2Migrator');

  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get resourceType => 'ClinicalEvent';

  @override
  ClinicalEvent migrate(ClinicalEvent oldModel) {
    _logger.info('Migrating ClinicalEvent v1 to v2 (identity)');
    return oldModel;
  }

  @override
  bool validate(ClinicalEvent newModel) => true;

  @override
  ClinicalEvent deserializeV1(Map<String, dynamic> json) =>
      ClinicalEvent.fromJson(json);

  @override
  Map<String, dynamic> serializeV2(ClinicalEvent model) => model.toJson();
}

/// ClinicalEvent v2 -> v3 migrator (identity)
class ClinicalEventV2ToV3Migrator
    extends ModelMigrator<ClinicalEvent, ClinicalEvent> {
  static final Logger _logger = Logger('ClinicalEventV2ToV3Migrator');

  @override
  int get fromVersion => 2;

  @override
  int get toVersion => 3;

  @override
  String get resourceType => 'ClinicalEvent';

  @override
  ClinicalEvent migrate(ClinicalEvent oldModel) {
    _logger.info('Migrating ClinicalEvent v2 to v3 (identity)');
    return ClinicalEvent(
      id: oldModel.id,
      date: oldModel.date,
      lastModifiedDate: oldModel.lastModifiedDate,
      tests: oldModel.tests,
      facility: oldModel.facility,
      notes: oldModel.notes,
    );
  }

  @override
  bool validate(ClinicalEvent newModel) => true;

  @override
  ClinicalEvent deserializeV1(Map<String, dynamic> json) =>
      ClinicalEvent.fromJson(json);

  @override
  Map<String, dynamic> serializeV2(ClinicalEvent model) => model.toJson();
}

/// SexualEvent v2 -> v3 migrator (preserve embedded location)
class SexualEventV2ToV3Migrator
    extends ModelMigrator<SexualEvent, SexualEvent> {
  static final Logger _logger = Logger('SexualEventV2ToV3Migrator');

  @override
  int get fromVersion => 2;

  @override
  int get toVersion => 3;

  @override
  String get resourceType => 'SexualEvent';

  @override
  SexualEvent migrate(SexualEvent oldModel) {
    _logger.info('Migrating SexualEvent v2 to v3 (preserve location)');

    // v2 and v3 SexualEvent are structurally compatible; ensure location is preserved.
    final migrated = SexualEvent(
      id: oldModel.id,
      date: oldModel.date,
      lastModifiedDate: oldModel.lastModifiedDate,
      activities: oldModel.activities,
      location: oldModel.location,
      notes: oldModel.notes,
    );

    if (!validate(migrated))
      throw Exception('Validation failed after SexualEvent v2->v3');
    return migrated;
  }

  @override
  bool validate(SexualEvent newModel) {
    if (newModel.id.isEmpty) return false;
    if (newModel.activities.isEmpty) return false;
    return true;
  }

  @override
  SexualEvent deserializeV1(Map<String, dynamic> json) =>
      SexualEvent.fromJson(json);

  @override
  Map<String, dynamic> serializeV2(SexualEvent model) => model.toJson();
}

/// Person v2 -> v3 identity migrator
class PersonV2ToV3Migrator extends ModelMigrator<Person, Person> {
  static final Logger _logger = Logger('PersonV2ToV3Migrator');

  @override
  int get fromVersion => 2;

  @override
  int get toVersion => 3;

  @override
  String get resourceType => 'Person';

  @override
  Person migrate(Person oldModel) {
    _logger.info('Migrating Person v2 to v3 (identity)');
    return Person.fromJson(
      ModelMigratorHelper.bumpVersion(oldModel.toJson(), 3),
    );
  }

  @override
  bool validate(Person newModel) => true;

  @override
  Person deserializeV1(Map<String, dynamic> json) => Person.fromJson(json);

  @override
  Map<String, dynamic> serializeV2(Person model) => model.toJson();
}

/// SexualActivityCategory v2 -> v3 identity migrator
class SexualActivityCategoryV2ToV3Migrator
    extends ModelMigrator<SexualActivityCategory, SexualActivityCategory> {
  static final Logger _logger = Logger('SexualActivityCategoryV2ToV3Migrator');

  @override
  int get fromVersion => 2;

  @override
  int get toVersion => 3;

  @override
  String get resourceType => 'SexualActivityCategory';

  @override
  SexualActivityCategory migrate(SexualActivityCategory oldModel) {
    _logger.info('Migrating SexualActivityCategory v2 to v3 (identity)');
    return SexualActivityCategory.fromJson(
      ModelMigratorHelper.bumpVersion(oldModel.toJson(), 3),
    );
  }

  @override
  bool validate(SexualActivityCategory newModel) => true;

  @override
  SexualActivityCategory deserializeV1(Map<String, dynamic> json) =>
      SexualActivityCategory.fromJson(json);

  @override
  Map<String, dynamic> serializeV2(SexualActivityCategory model) =>
      model.toJson();
}

// -----------------------------------------------------------------
// Migrator registry
// -----------------------------------------------------------------

class MigratorRegistry {
  static final Logger _logger = Logger('MigratorRegistry');

  static final Map<String, List<ModelMigrator>> _migrators = {
    'PropertyCount': [
      PropertyCountToActivityCountMigrator(),
      ActivityCountV2ToV3Migrator(),
    ],
    'ActivityCount': [
      PropertyCountToActivityCountMigrator(),
      ActivityCountV2ToV3Migrator(),
    ],
    'Person': [PersonMigrator()],
    'SexualActivityCategory': [
      SexualActivityTypeToSexualActivityCategoryMigrator(),
      SexualActivityCategoryV2ToV3Migrator(),
    ],
    'SexualActivity': [
      SexualActivityTypePropertyToSexualActivityMigrator(),
      SexualActivityV2ToV3Migrator(),
    ],
    'ClinicalEvent': [
      ClinicalEventV1ToV2Migrator(),
      ClinicalEventV2ToV3Migrator(),
    ],
    'SexualActivityType': [
      SexualActivityTypeToSexualActivityCategoryMigrator(),
    ],
    'SexualActivityTypeProperty': [
      SexualActivityTypePropertyToSexualActivityMigrator(),
    ],
    'SexualEvent': [SexualEventMigrator(), SexualEventV2ToV3Migrator()],
  };

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

  static bool canMigrate(String resourceType, int fromVersion, int toVersion) {
    return getMigrator(resourceType, fromVersion, toVersion) != null;
  }

  static List<ModelMigrator> getMigratorsForType(String resourceType) {
    return _migrators[resourceType] ?? [];
  }
}

/// Small helper to manipulate JSON version metadata for typed migrators.
class ModelMigratorHelper {
  static Map<String, dynamic> bumpVersion(
    Map<String, dynamic> json,
    int version,
  ) {
    final copy = Map<String, dynamic>.from(json);
    copy['version'] = version;
    return copy;
  }
}
