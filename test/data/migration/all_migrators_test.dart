import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models/v1/person/person.dart' as v1;
import 'package:indulge/data/models/v1/name/name.dart' as v1;
import 'package:indulge/data/models/v1/reference/reference.dart' as v1;
import 'package:indulge/data/models/v1/sexual_activity_type/sexual_activity_type.dart'
    as v1;
import 'package:indulge/data/models/v1/sexual_activity_type_property/sexual_activity_type_property.dart'
    as v1;
import 'package:indulge/data/models/v1/sexual_event/sexual_event.dart' as v1;
import 'package:indulge/data/models/v1/sexual_activity/sexual_activity.dart'
    as v1;
import 'package:indulge/data/models/v1/sexual_activity_participant/sexual_activity_participant.dart'
    as v1;
import 'package:indulge/data/models/v1/property_count/property_count.dart'
    as v1;
import 'package:indulge/data/models/v2/person/person.dart';
import 'package:indulge/data/models/v2/sexual_activity_category/sexual_activity_category.dart';
import 'package:indulge/data/models/v2/sexual_activity/sexual_activity.dart';
import 'package:indulge/data/models/v2/sexual_event/sexual_event.dart';
import 'package:indulge/domain/database/migration/v1_to_v2_migrators.dart';

void main() {
  group('PersonMigrator', () {
    late PersonMigrator migrator;

    setUp(() {
      migrator = PersonMigrator();
    });

    test('migrates Person v1 to v2 with all required fields', () {
      final v1Person = v1.Person(
        id: 'person-123',
        date: DateTime(2024, 1, 1),
        name: const v1.Name(given: 'John', family: 'Doe'),
        isSelf: false,
      );

      final v2Person = migrator.migrate(v1Person);

      expect(v2Person.id, 'person-123');
      expect(v2Person.date, DateTime(2024, 1, 1));
      expect(v2Person.name.given, 'John');
      expect(v2Person.name.family, 'Doe');
      expect(v2Person.isSelf, false);

      // New optional fields should be null
      expect(v2Person.bodyType, isNull);
      expect(v2Person.endowment, isNull);
      expect(v2Person.cutStatus, isNull);
      expect(v2Person.breastSize, isNull);
      expect(v2Person.assignedSexAtBirth, isNull);
      expect(v2Person.height, isNull);
      expect(v2Person.gender, isNull);
      expect(v2Person.hivStatus, isNull);
      expect(v2Person.herpesStatus, isNull);
      expect(v2Person.pronouns, isNull);
      expect(v2Person.socialLinks, isEmpty);
      expect(v2Person.notes, isNull);
      expect(v2Person.imageBytes, isNull);
    });

    test('migrates Person with optional fields', () {
      final v1Person = v1.Person(
        id: 'person-456',
        date: DateTime(2024, 2, 15),
        name: const v1.Name(given: 'Jane', nickname: 'J'),
        location: const v1.Reference(
          reference: 'location-789',
          resourceType: 'Location',
        ),
        birthday: DateTime(1990, 5, 20),
        isSelf: true,
      );

      final v2Person = migrator.migrate(v1Person);

      expect(v2Person.id, 'person-456');
      expect(v2Person.location?.reference, 'location-789');
      expect(v2Person.birthday, DateTime(1990, 5, 20));
      expect(v2Person.isSelf, true);
    });

    test('validates migrated Person', () {
      final v1Person = v1.Person(
        id: 'person-valid',
        date: DateTime.now(),
        name: const v1.Name(given: 'Test'),
        isSelf: false,
      );

      final v2Person = migrator.migrate(v1Person);
      expect(migrator.validate(v2Person), true);
    });

    test('has correct version metadata', () {
      expect(migrator.fromVersion, 1);
      expect(migrator.toVersion, 2);
      expect(migrator.resourceType, 'Person');
    });
  });

  group('SexualActivityTypeToSexualActivityCategoryMigrator', () {
    late SexualActivityTypeToSexualActivityCategoryMigrator migrator;

    setUp(() {
      migrator = SexualActivityTypeToSexualActivityCategoryMigrator();
    });

    test('migrates SexualActivityType to ActivityCategory', () {
      final v1Type = v1.SexualActivityType(
        id: 'type-123',
        name: 'Bottoming',
        displayCharacter: '⬇️',
        minParticipants: 1,
        maxParticipants: 2,
        properties: const [
          v1.Reference(
            reference: 'prop-1',
            resourceType: 'SexualActivityTypeProperty',
          ),
          v1.Reference(
            reference: 'prop-2',
            resourceType: 'SexualActivityTypeProperty',
          ),
        ],
        requiresPartner: true,
      );

      final v2Category = migrator.migrate(v1Type);

      expect(v2Category.id, 'type-123');
      expect(v2Category.name, 'Bottoming');
      expect(v2Category.displayCharacter, '⬇️');
      expect(v2Category.minParticipants, 1);
      expect(v2Category.maxParticipants, 2);
      expect(v2Category.requiresPartner, true);

      // Verify 'properties' was renamed to 'activities'
      expect(v2Category.activities.length, 2);
      expect(v2Category.activities[0].reference, 'prop-1');
      expect(v2Category.activities[1].reference, 'prop-2');
    });

    test('migrates with empty properties list', () {
      final v1Type = v1.SexualActivityType(
        id: 'type-empty',
        name: 'Empty Category',
      );

      final v2Category = migrator.migrate(v1Type);

      expect(v2Category.id, 'type-empty');
      expect(v2Category.name, 'Empty Category');
      expect(v2Category.activities, isEmpty);
    });

    test('validates migrated ActivityCategory', () {
      final v1Type = v1.SexualActivityType(id: 'valid-id', name: 'Valid Name');

      final v2Category = migrator.migrate(v1Type);
      expect(migrator.validate(v2Category), true);
    });

    test('validation fails with empty ID', () {
      final invalidCategory = SexualActivityCategory(id: '', name: 'Test');

      expect(migrator.validate(invalidCategory), false);
    });

    test('validation fails with empty name', () {
      final invalidCategory = SexualActivityCategory(id: 'test-id', name: '');

      expect(migrator.validate(invalidCategory), false);
    });

    test('has correct version metadata', () {
      expect(migrator.fromVersion, 1);
      expect(migrator.toVersion, 2);
      expect(migrator.resourceType, 'SexualActivityCategory');
    });
  });

  group('SexualActivityTypePropertyToSexualActivityMigrator', () {
    late SexualActivityTypePropertyToSexualActivityMigrator migrator;

    setUp(() {
      migrator = SexualActivityTypePropertyToSexualActivityMigrator();
    });

    test('migrates SexualActivityTypeProperty to Activity', () {
      final v1Property = v1.SexualActivityTypeProperty(
        id: 'prop-123',
        name: 'Topping',
        displayCharacter: '🔝',
        canHaveMultipleParticipants: true,
        isRisky: false,
        requiresPartner: true,
      );

      final v2Activity = migrator.migrate(v1Property);

      expect(v2Activity.id, 'prop-123');
      expect(v2Activity.name, 'Topping');
      expect(v2Activity.displayCharacter, '🔝');
      expect(v2Activity.canHaveMultipleParticipants, true);
      expect(v2Activity.isRisky, false);
      expect(v2Activity.requiresPartner, true);
    });

    test('migrates with default values', () {
      final v1Property = v1.SexualActivityTypeProperty(
        id: 'prop-default',
        name: 'Default Activity',
      );

      final v2Activity = migrator.migrate(v1Property);

      expect(v2Activity.id, 'prop-default');
      expect(v2Activity.name, 'Default Activity');
      expect(v2Activity.displayCharacter, '❔');
      expect(v2Activity.canHaveMultipleParticipants, true);
      expect(v2Activity.isRisky, false);
      expect(v2Activity.requiresPartner, false);
    });

    test('validates migrated Activity', () {
      final v1Property = v1.SexualActivityTypeProperty(
        id: 'valid-id',
        name: 'Valid Activity',
      );

      final v2Activity = migrator.migrate(v1Property);
      expect(migrator.validate(v2Activity), true);
    });

    test('validation fails with empty ID', () {
      final invalidActivity = SexualActivity(id: '', name: 'Test');
      expect(migrator.validate(invalidActivity), false);
    });

    test('validation fails with empty name', () {
      final invalidActivity = SexualActivity(id: 'test-id', name: '');
      expect(migrator.validate(invalidActivity), false);
    });

    test('has correct version metadata', () {
      expect(migrator.fromVersion, 1);
      expect(migrator.toVersion, 2);
      expect(migrator.resourceType, 'SexualActivity');
    });
  });

  group('SexualEventMigrator', () {
    late SexualEventMigrator migrator;

    setUp(() {
      migrator = SexualEventMigrator();
    });

    test('migrates simple SexualEvent with one activity', () {
      final v1Event = v1.SexualEvent(
        id: 'event-123',
        date: DateTime(2024, 3, 15),
        activities: [
          v1.SexualActivity(
            type: const v1.Reference(
              reference: 'type-oral',
              resourceType: 'SexualActivityType',
            ),
            participants: const [],
          ),
        ],
      );

      final v2Event = migrator.migrate(v1Event);

      expect(v2Event.id, 'event-123');
      expect(v2Event.date, DateTime(2024, 3, 15));
      expect(v2Event.activities.length, 1);

      // Verify 'type' was renamed to 'category'
      expect(v2Event.activities[0].category.reference, 'type-oral');
      expect(v2Event.activities[0].category.resourceType, 'SexualActivityType');
    });

    test('migrates SexualEvent with participants', () {
      final v1Event = v1.SexualEvent(
        id: 'event-456',
        date: DateTime(2024, 3, 20),
        activities: [
          v1.SexualActivity(
            type: const v1.Reference(
              reference: 'type-anal',
              resourceType: 'SexualActivityType',
            ),
            participants: const [
              v1.SexualActivityParticipant(
                participant: v1.Reference(
                  reference: 'person-1',
                  resourceType: 'Person',
                ),
                propertyCounts: [],
              ),
            ],
          ),
        ],
      );

      final v2Event = migrator.migrate(v1Event);

      expect(v2Event.activities[0].participants.length, 1);
      expect(
        v2Event.activities[0].participants[0].participant.reference,
        'person-1',
      );
    });

    test('migrates nested propertyCounts to activityCounts', () {
      final v1Event = v1.SexualEvent(
        id: 'event-789',
        date: DateTime(2024, 3, 25),
        activities: [
          v1.SexualActivity(
            type: const v1.Reference(
              reference: 'type-vaginal',
              resourceType: 'SexualActivityType',
            ),
            participants: const [
              v1.SexualActivityParticipant(
                participant: v1.Reference(
                  reference: 'person-2',
                  resourceType: 'Person',
                ),
                propertyCounts: [
                  v1.PropertyCount(
                    propertyReference: v1.Reference(
                      reference: 'prop-condom',
                      resourceType: 'SexualActivityTypeProperty',
                    ),
                    count: 3,
                  ),
                  v1.PropertyCount(
                    propertyReference: v1.Reference(
                      reference: 'prop-lube',
                      resourceType: 'SexualActivityTypeProperty',
                    ),
                    count: 1,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final v2Event = migrator.migrate(v1Event);

      // Verify 'propertyCounts' was renamed to 'activityCounts'
      final participant = v2Event.activities[0].participants[0];
      expect(participant.activityCounts.length, 2);

      // Verify 'propertyReference' was renamed to 'activityReference'
      expect(
        participant.activityCounts[0].activityReference.reference,
        'prop-condom',
      );
      expect(participant.activityCounts[0].count, 3);
      expect(participant.activityCounts[0].version, 2);

      expect(
        participant.activityCounts[1].activityReference.reference,
        'prop-lube',
      );
      expect(participant.activityCounts[1].count, 1);
      expect(participant.activityCounts[1].version, 2);
    });

    test(
      'migrates complex SexualEvent with multiple activities and participants',
      () {
        final v1Event = v1.SexualEvent(
          id: 'event-complex',
          date: DateTime(2024, 4, 1),
          lastModifiedDate: DateTime(2024, 4, 2),
          activities: [
            v1.SexualActivity(
              type: const v1.Reference(
                reference: 'type-oral',
                resourceType: 'SexualActivityType',
              ),
              participants: const [
                v1.SexualActivityParticipant(
                  participant: v1.Reference(
                    reference: 'person-a',
                    resourceType: 'Person',
                  ),
                  propertyCounts: [
                    v1.PropertyCount(
                      propertyReference: v1.Reference(
                        reference: 'prop-giving',
                        resourceType: 'SexualActivityTypeProperty',
                      ),
                      count: 2,
                    ),
                  ],
                ),
                v1.SexualActivityParticipant(
                  participant: v1.Reference(
                    reference: 'person-b',
                    resourceType: 'Person',
                  ),
                  propertyCounts: [
                    v1.PropertyCount(
                      propertyReference: v1.Reference(
                        reference: 'prop-receiving',
                        resourceType: 'SexualActivityTypeProperty',
                      ),
                      count: 2,
                    ),
                  ],
                ),
              ],
            ),
            v1.SexualActivity(
              type: const v1.Reference(
                reference: 'type-manual',
                resourceType: 'SexualActivityType',
              ),
              participants: const [
                v1.SexualActivityParticipant(
                  participant: v1.Reference(
                    reference: 'person-a',
                    resourceType: 'Person',
                  ),
                  propertyCounts: [],
                ),
              ],
            ),
          ],
        );

        final v2Event = migrator.migrate(v1Event);

        expect(v2Event.id, 'event-complex');
        expect(v2Event.date, DateTime(2024, 4, 1));
        expect(v2Event.lastModifiedDate, DateTime(2024, 4, 2));
        expect(v2Event.activities.length, 2);

        // First activity
        expect(v2Event.activities[0].category.reference, 'type-oral');
        expect(v2Event.activities[0].participants.length, 2);
        expect(
          v2Event.activities[0].participants[0].participant.reference,
          'person-a',
        );
        expect(v2Event.activities[0].participants[0].activityCounts.length, 1);
        expect(
          v2Event.activities[0].participants[1].participant.reference,
          'person-b',
        );
        expect(v2Event.activities[0].participants[1].activityCounts.length, 1);

        // Second activity
        expect(v2Event.activities[1].category.reference, 'type-manual');
        expect(v2Event.activities[1].participants.length, 1);
        expect(v2Event.activities[1].participants[0].activityCounts, isEmpty);
      },
    );

    test('validates migrated SexualEvent', () {
      final v1Event = v1.SexualEvent(
        id: 'valid-event',
        date: DateTime.now(),
        activities: [
          v1.SexualActivity(
            type: const v1.Reference(reference: 'type-1'),
            participants: const [],
          ),
        ],
      );

      final v2Event = migrator.migrate(v1Event);
      expect(migrator.validate(v2Event), true);
    });

    test('validation fails with empty ID', () {
      final invalidEvent = SexualEvent(
        id: '',
        date: DateTime.now(),
        activities: const [],
      );

      expect(migrator.validate(invalidEvent), false);
    });

    test('validation fails with no activities', () {
      final invalidEvent = SexualEvent(
        id: 'test-id',
        date: DateTime.now(),
        activities: const [],
      );

      expect(migrator.validate(invalidEvent), false);
    });

    test('has correct version metadata', () {
      expect(migrator.fromVersion, 1);
      expect(migrator.toVersion, 2);
      expect(migrator.resourceType, 'SexualEvent');
    });
  });

  group('MigratorRegistry', () {
    test('returns correct migrator for PropertyCount', () {
      final migrator = MigratorRegistry.getMigrator('PropertyCount', 1, 2);
      expect(migrator, isNotNull);
      expect(migrator, isA<PropertyCountToActivityCountMigrator>());
    });

    test('returns correct migrator for ActivityCount', () {
      final migrator = MigratorRegistry.getMigrator('ActivityCount', 1, 2);
      expect(migrator, isNotNull);
      expect(migrator, isA<PropertyCountToActivityCountMigrator>());
    });

    test('returns correct migrator for Person', () {
      final migrator = MigratorRegistry.getMigrator('Person', 1, 2);
      expect(migrator, isNotNull);
      expect(migrator, isA<PersonMigrator>());
    });

    test('returns correct migrator for SexualActivityType', () {
      final migrator = MigratorRegistry.getMigrator('SexualActivityType', 1, 2);
      expect(migrator, isNotNull);
      expect(
        migrator,
        isA<SexualActivityTypeToSexualActivityCategoryMigrator>(),
      );
    });

    test('returns correct migrator for SexualActivityTypeProperty', () {
      final migrator = MigratorRegistry.getMigrator(
        'SexualActivityTypeProperty',
        1,
        2,
      );
      expect(migrator, isNotNull);
      expect(
        migrator,
        isA<SexualActivityTypePropertyToSexualActivityMigrator>(),
      );
    });

    test('returns correct migrator for SexualEvent', () {
      final migrator = MigratorRegistry.getMigrator('SexualEvent', 1, 2);
      expect(migrator, isNotNull);
      expect(migrator, isA<SexualEventMigrator>());
    });

    test('returns null for unknown resource type', () {
      final migrator = MigratorRegistry.getMigrator('UnknownType', 1, 2);
      expect(migrator, isNull);
    });

    test('returns null for unsupported version jump', () {
      final migrator = MigratorRegistry.getMigrator('Person', 2, 3);
      expect(migrator, isNull);
    });

    test('canMigrate returns true for supported migrations', () {
      expect(MigratorRegistry.canMigrate('Person', 1, 2), true);
      expect(MigratorRegistry.canMigrate('SexualEvent', 1, 2), true);
    });

    test('canMigrate returns false for unsupported migrations', () {
      expect(MigratorRegistry.canMigrate('UnknownType', 1, 2), false);
      expect(MigratorRegistry.canMigrate('Person', 3, 4), false);
    });

    test('getMigratorsForType returns all migrators for a type', () {
      final migrators = MigratorRegistry.getMigratorsForType('Person');
      expect(migrators.length, 1);
      expect(migrators[0], isA<PersonMigrator>());
    });

    test('getMigratorsForType returns empty list for unknown type', () {
      final migrators = MigratorRegistry.getMigratorsForType('UnknownType');
      expect(migrators, isEmpty);
    });
  });
}
