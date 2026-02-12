import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/event_editor/utils/event_mutations.dart';

void main() {
  group('Event mutations', () {
    final now = DateTime.now();

    test('addActivity adds a new activity to an event', () {
      final event = SexualEvent(id: 'e1', date: now, activities: []);
      final category = SexualActivityCategory(
        id: 'oral',
        name: 'Oral',
        displayCharacter: '👄',
        requiresPartner: true,
      );

      final updated = addActivity(event, category);

      expect(updated.activities.length, equals(1));
      expect(updated.activities[0].category.reference, equals('oral'));
    });

    test('removeActivity removes an activity by index', () {
      final activity = EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [],
      );
      final event = SexualEvent(id: 'e2', date: now, activities: [activity]);

      final updated = removeActivity(event, 0);

      expect(updated.activities.length, equals(0));
    });

    test('removeActivity with invalid index leaves event unchanged', () {
      final event = SexualEvent(id: 'e3', date: now, activities: []);
      final updated = removeActivity(event, 5);
      expect(updated.activities, equals(event.activities));
    });

    test('addParticipant adds a participant to an activity', () {
      final activity = EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [],
      );
      final event = SexualEvent(id: 'e4', date: now, activities: [activity]);

      final person = Person(
        id: 'p1',
        name: const Name(given: 'Alice'),
        date: now,
      );

      final updated = addParticipant(event, 0, person);

      expect(updated.activities[0].participants.length, equals(1));
      expect(
        updated.activities[0].participants[0].participant.reference,
        equals('p1'),
      );
    });

    test('addParticipant does not add duplicate participant', () {
      final participant = ActivityParticipant(
        participant: Reference(reference: 'p1'),
        activityCounts: [],
      );
      final activity = EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [participant],
      );
      final event = SexualEvent(id: 'e5', date: now, activities: [activity]);

      final person = Person(
        id: 'p1',
        name: const Name(given: 'Alice'),
        date: now,
      );

      final updated = addParticipant(event, 0, person);

      // Should be unchanged (no duplicate)
      expect(updated.activities[0].participants.length, equals(1));
    });

    test('removeParticipant removes a participant by index', () {
      final participant = ActivityParticipant(
        participant: Reference(reference: 'p2'),
        activityCounts: [],
      );
      final activity = EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [participant],
      );
      final event = SexualEvent(id: 'e6', date: now, activities: [activity]);

      final updated = removeParticipant(event, 0, 0);

      expect(updated.activities[0].participants.length, equals(0));
    });

    test(
      'toggleMyselfForProperty creates and removes the "me" participant',
      () {
        final activity = EventActivity(
          category: const Reference(reference: 'kink'),
          participants: [],
        );
        final event = SexualEvent(id: 'e7', date: now, activities: [activity]);

        // Add property for myself
        final added = toggleMyselfForProperty(event, 0, 'me', 'a1');
        expect(added.activities[0].participants.length, equals(1));

        final meParticipant = added.activities[0].participants.firstWhere(
          (p) => p.participant.reference == 'me',
          orElse: () => throw StateError('me participant missing'),
        );
        expect(meParticipant.activityCounts.length, equals(1));
        expect(
          meParticipant.activityCounts.first.activityReference.reference,
          equals('a1'),
        );
        expect(meParticipant.activityCounts.first.count, equals(1));

        // Toggle again to remove
        final removed = toggleMyselfForProperty(added, 0, 'me', 'a1');
        final remaining = removed.activities[0].participants.where(
          (p) => p.participant.reference == 'me',
        );
        expect(remaining.isEmpty, isTrue);
      },
    );

    test(
      'toggleParticipantForProperty toggles a property for an existing participant',
      () {
        final participant = ActivityParticipant(
          participant: Reference(reference: 'p3'),
          activityCounts: [],
        );
        final activity = EventActivity(
          category: const Reference(reference: 'oral'),
          participants: [participant],
        );
        final event = SexualEvent(id: 'e8', date: now, activities: [activity]);

        // Add property
        final added = toggleParticipantForProperty(event, 0, 'actX', 'p3');
        final pAfterAdd = added.activities[0].participants.firstWhere(
          (p) => p.participant.reference == 'p3',
        );
        expect(
          pAfterAdd.activityCounts.any(
            (ac) => ac.activityReference.reference == 'actX',
          ),
          isTrue,
        );

        // Remove property
        final removed = toggleParticipantForProperty(added, 0, 'actX', 'p3');
        final pAfterRemove = removed.activities[0].participants.firstWhere(
          (p) => p.participant.reference == 'p3',
        );
        expect(
          pAfterRemove.activityCounts.any(
            (ac) => ac.activityReference.reference == 'actX',
          ),
          isFalse,
        );
      },
    );

    test(
      'incrementPropertyCount increases the count for a participant activity',
      () {
        final participant = ActivityParticipant(
          participant: Reference(reference: 'p4'),
          activityCounts: [
            ActivityCount(
              activityReference: Reference(reference: 'actA'),
              count: 1,
            ),
          ],
        );
        final activity = EventActivity(
          category: const Reference(reference: 'oral'),
          participants: [participant],
        );
        final event = SexualEvent(id: 'e9', date: now, activities: [activity]);

        final incremented = incrementPropertyCount(event, 0, 'actA', 'p4');
        final p = incremented.activities[0].participants.firstWhere(
          (p) => p.participant.reference == 'p4',
        );
        final ac = p.activityCounts.firstWhere(
          (ac) => ac.activityReference.reference == 'actA',
        );
        expect(ac.count, equals(2));
      },
    );

    test(
      'decrementPropertyCount decreases the count and removes activity count when it reaches zero',
      () {
        final participant = ActivityParticipant(
          participant: Reference(reference: 'p5'),
          activityCounts: [
            ActivityCount(
              activityReference: Reference(reference: 'actB'),
              count: 2,
            ),
          ],
        );
        final activity = EventActivity(
          category: const Reference(reference: 'oral'),
          participants: [participant],
        );
        final event = SexualEvent(id: 'e10', date: now, activities: [activity]);

        // Decrement from 2 to 1
        final decOnce = decrementPropertyCount(event, 0, 'actB', 'p5');
        final p1 = decOnce.activities[0].participants.firstWhere(
          (p) => p.participant.reference == 'p5',
        );
        final ac1 = p1.activityCounts.firstWhere(
          (ac) => ac.activityReference.reference == 'actB',
        );
        expect(ac1.count, equals(1));

        // Decrement from 1 to removal of that activityCount entry
        final decTwice = decrementPropertyCount(decOnce, 0, 'actB', 'p5');
        final p2 = decTwice.activities[0].participants.firstWhere(
          (p) => p.participant.reference == 'p5',
        );
        final remainingCounts = p2.activityCounts.where(
          (ac) => ac.activityReference.reference == 'actB',
        );
        expect(remainingCounts.isEmpty, isTrue);
      },
    );

    test('mutations with invalid indices return original event', () {
      final event = SexualEvent(id: 'e11', date: now, activities: []);
      final person = Person(
        id: 'pX',
        name: const Name(given: 'X'),
        date: now,
      );
      final addedParticipant = addParticipant(event, 5, person);
      expect(addedParticipant.activities, equals(event.activities));

      final removedParticipant = removeParticipant(event, 5, 0);
      expect(removedParticipant.activities, equals(event.activities));

      final inc = incrementPropertyCount(event, 5, 'a', 'pX');
      expect(inc.activities, equals(event.activities));

      final dec = decrementPropertyCount(event, 5, 'a', 'pX');
      expect(dec.activities, equals(event.activities));
    });
  });
}
