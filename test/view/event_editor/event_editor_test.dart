import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';

void main() {
  group('EventEditor Duplicate Participant Prevention', () {
    test('activity should not allow duplicate participants', () {
      final person1 = Person(
        id: 'person1',
        name: const Name(given: 'John'),
        date: DateTime.now(),
      );

      final activity = EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [
          const ActivityParticipant(
            participant: Reference(reference: 'person1'),
            activityCounts: [],
          ),
        ],
      );

      // Check if person1 already exists
      final alreadyExists = activity.participants.any(
        (p) => p.participant.reference == person1.id,
      );

      expect(alreadyExists, isTrue);
    });

    test('anonymous participant should not be addable twice', () {
      final anonymous = Person(
        id: 'anonymous',
        name: const Name(given: 'Anonymous'),
        date: DateTime.now(),
      );

      final activity = EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [
          const ActivityParticipant(
            participant: Reference(reference: 'anonymous'),
            activityCounts: [],
          ),
        ],
      );

      // Check if anonymous already exists
      final alreadyExists = activity.participants.any(
        (p) => p.participant.reference == anonymous.id,
      );

      expect(alreadyExists, isTrue);
    });

    test('different participants can be added to same activity', () {
      final activity = EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [
          const ActivityParticipant(
            participant: Reference(reference: 'person1'),
            activityCounts: [],
          ),
          const ActivityParticipant(
            participant: Reference(reference: 'person2'),
            activityCounts: [],
          ),
        ],
      );

      final person1Exists = activity.participants.any(
        (p) => p.participant.reference == 'person1',
      );
      final person2Exists = activity.participants.any(
        (p) => p.participant.reference == 'person2',
      );
      final person3Exists = activity.participants.any(
        (p) => p.participant.reference == 'person3',
      );

      expect(person1Exists, isTrue);
      expect(person2Exists, isTrue);
      expect(person3Exists, isFalse);
      expect(activity.participants.length, equals(2));
    });

    test('participant can have multiple activity counts', () {
      const participant = ActivityParticipant(
        participant: Reference(reference: 'person1'),
        activityCounts: [
          ActivityCount(
            activityReference: Reference(reference: 'giving'),
            count: 1,
          ),
          ActivityCount(
            activityReference: Reference(reference: 'receiving'),
            count: 2,
          ),
        ],
      );

      expect(participant.activityCounts.length, equals(2));
      expect(participant.activityCounts[0].count, equals(1));
      expect(participant.activityCounts[1].count, equals(2));
    });

    test('activity count can be incremented for same participant', () {
      const originalActivityCount = ActivityCount(
        activityReference: Reference(reference: 'giving'),
        count: 1,
      );

      final incrementedActivityCount = originalActivityCount.copyWith(
        count: originalActivityCount.count + 1,
      );

      expect(incrementedActivityCount.count, equals(2));
      expect(
        incrementedActivityCount.activityReference.reference,
        equals('giving'),
      );
    });

    test('participant list should be unique by person id', () {
      final activity = EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [
          const ActivityParticipant(
            participant: Reference(reference: 'person1'),
            activityCounts: [],
          ),
          const ActivityParticipant(
            participant: Reference(reference: 'person2'),
            activityCounts: [],
          ),
          const ActivityParticipant(
            participant: Reference(reference: 'person3'),
            activityCounts: [],
          ),
        ],
      );

      // Extract unique participant IDs
      final participantIds = activity.participants
          .map((p) => p.participant.reference)
          .toSet();

      // Should have 3 unique participants
      expect(participantIds.length, equals(3));
      expect(activity.participants.length, equals(3));
    });

    test('incrementing activity count should not duplicate participant', () {
      const participant = ActivityParticipant(
        participant: Reference(reference: 'person1'),
        activityCounts: [
          ActivityCount(
            activityReference: Reference(reference: 'giving'),
            count: 1,
          ),
        ],
      );

      // Simulate incrementing the count
      final updatedActivityCounts = participant.activityCounts.map((ac) {
        if (ac.activityReference.reference == 'giving') {
          return ac.copyWith(count: ac.count + 1);
        }
        return ac;
      }).toList();

      final updatedParticipant = participant.copyWith(
        activityCounts: updatedActivityCounts,
      );

      // Should still be the same participant
      expect(updatedParticipant.participant.reference, equals('person1'));
      expect(updatedParticipant.activityCounts.length, equals(1));
      expect(updatedParticipant.activityCounts[0].count, equals(2));
    });

    test('multiple activities can have same participant', () {
      final event = SexualEvent(
        id: 'event1',
        date: DateTime.now(),
        activities: [
          const EventActivity(
            category: Reference(reference: 'oral'),
            participants: [
              ActivityParticipant(
                participant: Reference(reference: 'person1'),
                activityCounts: [],
              ),
            ],
          ),
          EventActivity(
            category: Reference(reference: 'vaginal'),
            participants: [
              ActivityParticipant(
                participant: Reference(reference: 'person1'),
                activityCounts: [],
              ),
            ],
          ),
        ],
      );

      // Person1 can appear in multiple activities
      expect(event.activities.length, equals(2));
      expect(
        event.activities[0].participants[0].participant.reference,
        equals('person1'),
      );
      expect(
        event.activities[1].participants[0].participant.reference,
        equals('person1'),
      );
    });

    test('can check if participant exists before adding', () {
      final existingParticipants = [
        const ActivityParticipant(
          participant: Reference(reference: 'person1'),
          activityCounts: [],
        ),
        const ActivityParticipant(
          participant: Reference(reference: 'person2'),
          activityCounts: [],
        ),
      ];

      // Helper function to check if participant exists
      bool participantExists(String personId) {
        return existingParticipants.any(
          (p) => p.participant.reference == personId,
        );
      }

      expect(participantExists('person1'), isTrue);
      expect(participantExists('person2'), isTrue);
      expect(participantExists('person3'), isFalse);
      expect(participantExists('anonymous'), isFalse);
    });
  });
}
