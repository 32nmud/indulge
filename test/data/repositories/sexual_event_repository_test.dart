import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';

void main() {
  group('SexualEventRepository', () {
    // Note: These are integration tests that would require a full database setup.
    // For true unit testing, we would mock the database layer.
    // The repository tests are better suited for integration testing in a real environment.

    group('Model Copy Tests', () {
      test('SexualEvent copyWith creates modified copy', () {
        final original = SexualEvent(
          id: 'original',
          date: DateTime(2024, 1, 15),
          activities: [],
        );

        final newDate = DateTime(2024, 1, 16);
        final copied = original.copyWith(date: newDate);

        expect(copied.id, equals('original'));
        expect(copied.date, equals(newDate));
        expect(original.date, equals(DateTime(2024, 1, 15)));
      });

      test('Person copyWith creates modified copy', () {
        final original = Person(
          id: 'person1',
          name: const Name(given: 'Original'),
          date: DateTime.now(),
          isSelf: false,
        );

        final copied = original.copyWith(
          name: const Name(given: 'Modified'),
          isSelf: true,
        );

        expect(copied.id, equals('person1'));
        expect(copied.name.given, equals('Modified'));
        expect(copied.isSelf, isTrue);
        expect(original.name.given, equals('Original'));
        expect(original.isSelf, isFalse);
      });

      test('Event with activities can be copied with modified activities', () {
        final original = SexualEvent(
          id: 'event1',
          date: DateTime.now(),
          activities: [
            SexualActivity(type: const Reference(reference: 'oral')),
          ],
        );

        final newActivities = [
          SexualActivity(type: const Reference(reference: 'oral')),
          SexualActivity(type: const Reference(reference: 'vaginal')),
        ];

        final copied = original.copyWith(activities: newActivities);

        expect(copied.activities.length, equals(2));
        expect(original.activities.length, equals(1));
      });
    });

    group('Model Structure Tests', () {
      test('SexualEvent can be created with complex activities', () {
        final event = SexualEvent(
          id: 'complex-event',
          date: DateTime(2024, 1, 15),
          activities: [
            SexualActivity(
              type: const Reference(reference: 'oral'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'p1'),
                  propertyCounts: [
                    PropertyCount(
                      propertyReference: Reference(reference: 'condom'),
                      count: 1,
                    ),
                  ],
                ),
              ],
            ),
            SexualActivity(
              type: const Reference(reference: 'vaginal'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'p1'),
                  propertyCounts: [
                    PropertyCount(
                      propertyReference: Reference(reference: 'condom'),
                      count: 2,
                    ),
                  ],
                ),
                const SexualActivityParticipant(
                  participant: Reference(reference: 'p2'),
                  propertyCounts: [],
                ),
              ],
            ),
          ],
        );

        expect(event.id, equals('complex-event'));
        expect(event.activities.length, equals(2));
        expect(
          event.activities[0].participants[0].propertyCounts.length,
          equals(1),
        );
        expect(event.activities[1].participants.length, equals(2));
      });

      test('Person can be created with all fields', () {
        final person = Person(
          id: 'person1',
          name: const Name(given: 'Test', family: 'Person'),
          date: DateTime(2024, 1, 1),
          isSelf: false,
          birthday: DateTime(1990, 5, 15),
        );

        expect(person.id, equals('person1'));
        expect(person.name.given, equals('Test'));
        expect(person.name.family, equals('Person'));
        expect(person.isSelf, isFalse);
        expect(person.birthday, isNotNull);
      });

      test('SexualActivityType can be created', () {
        const activityType = SexualActivityType(
          id: 'oral',
          name: 'Oral',
          displayCharacter: '👄',
          minParticipants: 1,
          maxParticipants: 2,
        );

        expect(activityType.id, equals('oral'));
        expect(activityType.name, equals('Oral'));
        expect(activityType.displayCharacter, equals('👄'));
        expect(activityType.minParticipants, equals(1));
        expect(activityType.maxParticipants, equals(2));
      });

      test('SexualActivityTypeProperty can be created', () {
        const property = SexualActivityTypeProperty(
          id: 'condom',
          name: 'Condom',
          isRisky: false,
          requiresPartner: true,
        );

        expect(property.id, equals('condom'));
        expect(property.name, equals('Condom'));
        expect(property.isRisky, isFalse);
        expect(property.requiresPartner, isTrue);
      });

      test('Reference can be created', () {
        const ref = Reference(reference: 'test-id', resourceType: 'Person');

        expect(ref.reference, equals('test-id'));
        expect(ref.resourceType, equals('Person'));
      });

      test('PropertyCount can be created', () {
        const propCount = PropertyCount(
          propertyReference: Reference(
            reference: 'prop-id',
            resourceType: 'SexualActivityTypeProperty',
          ),
          count: 3,
        );

        expect(propCount.propertyReference.reference, equals('prop-id'));
        expect(propCount.count, equals(3));
      });

      test('Name can be created', () {
        const name = Name(given: 'John', family: 'Doe', nickname: 'Johnny');

        expect(name.given, equals('John'));
        expect(name.family, equals('Doe'));
        expect(name.nickname, equals('Johnny'));
      });
    });

    group('Model Validation Tests', () {
      test('Person resourceType is always "Person"', () {
        final person = Person(
          id: 'test',
          name: const Name(given: 'Test'),
          date: DateTime.now(),
        );

        expect(person.resourceType, equals('Person'));
      });

      test(
        'SexualActivityType resourceType is always "SexualActivityType"',
        () {
          const activityType = SexualActivityType(id: 'test', name: 'Test');

          expect(activityType.resourceType, equals('SexualActivityType'));
        },
      );

      test(
        'SexualActivityTypeProperty resourceType is always "SexualActivityTypeProperty"',
        () {
          const property = SexualActivityTypeProperty(id: 'test', name: 'Test');

          expect(property.resourceType, equals('SexualActivityTypeProperty'));
        },
      );

      test('Event with no activities can be created', () {
        final event = SexualEvent(
          id: 'empty-event',
          date: DateTime(2024, 1, 15),
          activities: [],
        );

        expect(event.id, equals('empty-event'));
        expect(event.activities, isEmpty);
      });

      test('Multiple property counts can be added to participant', () {
        const participant = SexualActivityParticipant(
          participant: Reference(reference: 'p1'),
          propertyCounts: [
            PropertyCount(
              propertyReference: Reference(reference: 'prop1'),
              count: 1,
            ),
            PropertyCount(
              propertyReference: Reference(reference: 'prop2'),
              count: 2,
            ),
            PropertyCount(
              propertyReference: Reference(reference: 'prop3'),
              count: 3,
            ),
          ],
        );

        expect(participant.propertyCounts.length, equals(3));
        expect(participant.propertyCounts[0].count, equals(1));
        expect(participant.propertyCounts[1].count, equals(2));
        expect(participant.propertyCounts[2].count, equals(3));
      });
    });
  });
}
