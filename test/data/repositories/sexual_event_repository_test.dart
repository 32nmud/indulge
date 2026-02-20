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
            const EventActivity(category: Reference(reference: 'oral')),
          ],
        );

        final newActivities = [
          const EventActivity(category: Reference(reference: 'oral')),
          const EventActivity(category: Reference(reference: 'vaginal')),
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
            const EventActivity(
              category: Reference(reference: 'oral'),
              participants: [
                ActivityParticipant(
                  participant: Reference(reference: 'p1'),
                  activityCounts: [
                    ActivityCount(
                      activityReference: Reference(reference: 'giving'),
                      count: 1,
                    ),
                  ],
                ),
              ],
            ),
            EventActivity(
              category: Reference(reference: 'vaginal'),
              participants: [
                ActivityParticipant(
                  participant: Reference(reference: 'p1'),
                  activityCounts: [
                    ActivityCount(
                      activityReference: Reference(reference: 'receiving'),
                      count: 2,
                    ),
                  ],
                ),
                ActivityParticipant(
                  participant: Reference(reference: 'p2'),
                  activityCounts: [],
                ),
              ],
            ),
          ],
        );

        expect(event.id, equals('complex-event'));
        expect(event.activities.length, equals(2));
        expect(
          event.activities[0].participants[0].activityCounts.length,
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

      test('SexualActivityCategory can be created', () {
        const activityCategory = SexualActivityCategory(
          id: 'oral',
          name: 'Oral',
          displayCharacter: '👄',
          requiresPartner: true,
        );

        expect(activityCategory.id, equals('oral'));
        expect(activityCategory.name, equals('Oral'));
        expect(activityCategory.displayCharacter, equals('👄'));
        expect(activityCategory.requiresPartner, isTrue);
      });

      test('SexualActivity can be created', () {
        const activity = SexualActivity(
          id: 'giving',
          name: 'Giving',
          displayCharacter: '👅',
          stiRisk: false,
          healthRisk: false,
          requiresPartner: true,
        );

        expect(activity.id, equals('giving'));
        expect(activity.name, equals('Giving'));
        expect(activity.displayCharacter, equals('👅'));
        expect(activity.stiRisk, isFalse);
        expect(activity.healthRisk, isFalse);
        expect(activity.requiresPartner, isTrue);
      });

      test('Reference can be created', () {
        const ref = Reference(reference: 'test-id', resourceType: 'Person');

        expect(ref.reference, equals('test-id'));
        expect(ref.resourceType, equals('Person'));
      });

      test('ActivityCount can be created', () {
        const activityCount = ActivityCount(
          activityReference: Reference(
            reference: 'activity-id',
            resourceType: 'SexualActivity',
          ),
          count: 3,
        );

        expect(
          activityCount.activityReference.reference,
          equals('activity-id'),
        );
        expect(activityCount.count, equals(3));
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
        'SexualActivityCategory resourceType is always "SexualActivityCategory"',
        () {
          const activityCategory = SexualActivityCategory(
            id: 'test',
            name: 'Test',
          );

          expect(
            activityCategory.resourceType,
            equals('SexualActivityCategory'),
          );
        },
      );

      test('SexualActivity resourceType is always "SexualActivity"', () {
        const activity = SexualActivity(id: 'test', name: 'Test');

        expect(activity.resourceType, equals('SexualActivity'));
      });

      test('Event with no activities can be created', () {
        final event = SexualEvent(
          id: 'empty-event',
          date: DateTime(2024, 1, 15),
          activities: [],
        );

        expect(event.id, equals('empty-event'));
        expect(event.activities, isEmpty);
      });

      test('Multiple activity counts can be added to participant', () {
        const participant = ActivityParticipant(
          participant: Reference(reference: 'p1'),
          activityCounts: [
            ActivityCount(
              activityReference: Reference(reference: 'activity1'),
              count: 1,
            ),
            ActivityCount(
              activityReference: Reference(reference: 'activity2'),
              count: 2,
            ),
            ActivityCount(
              activityReference: Reference(reference: 'activity3'),
              count: 3,
            ),
          ],
        );

        expect(participant.activityCounts.length, equals(3));
        expect(participant.activityCounts[0].count, equals(1));
        expect(participant.activityCounts[1].count, equals(2));
        expect(participant.activityCounts[2].count, equals(3));
      });
    });
  });
}
