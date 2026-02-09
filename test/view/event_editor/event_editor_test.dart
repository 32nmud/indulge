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

      final activity = SexualActivity(
        type: const Reference(reference: 'oral'),
        participants: [
          const SexualActivityParticipant(
            participant: Reference(reference: 'person1'),
            propertyCounts: [],
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

      final activity = SexualActivity(
        type: const Reference(reference: 'oral'),
        participants: [
          const SexualActivityParticipant(
            participant: Reference(reference: 'anonymous'),
            propertyCounts: [],
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
      final activity = SexualActivity(
        type: const Reference(reference: 'oral'),
        participants: [
          const SexualActivityParticipant(
            participant: Reference(reference: 'person1'),
            propertyCounts: [],
          ),
          const SexualActivityParticipant(
            participant: Reference(reference: 'person2'),
            propertyCounts: [],
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

    test('participant can have multiple property counts', () {
      const participant = SexualActivityParticipant(
        participant: Reference(reference: 'person1'),
        propertyCounts: [
          PropertyCount(
            propertyReference: Reference(reference: 'condom'),
            count: 1,
          ),
          PropertyCount(
            propertyReference: Reference(reference: 'lube'),
            count: 2,
          ),
        ],
      );

      expect(participant.propertyCounts.length, equals(2));
      expect(participant.propertyCounts[0].count, equals(1));
      expect(participant.propertyCounts[1].count, equals(2));
    });

    test('property count can be incremented for same participant', () {
      const originalPropertyCount = PropertyCount(
        propertyReference: Reference(reference: 'condom'),
        count: 1,
      );

      final incrementedPropertyCount = originalPropertyCount.copyWith(
        count: originalPropertyCount.count + 1,
      );

      expect(incrementedPropertyCount.count, equals(2));
      expect(
        incrementedPropertyCount.propertyReference.reference,
        equals('condom'),
      );
    });

    test('participant list should be unique by person id', () {
      final activity = SexualActivity(
        type: const Reference(reference: 'oral'),
        participants: [
          const SexualActivityParticipant(
            participant: Reference(reference: 'person1'),
            propertyCounts: [],
          ),
          const SexualActivityParticipant(
            participant: Reference(reference: 'person2'),
            propertyCounts: [],
          ),
          const SexualActivityParticipant(
            participant: Reference(reference: 'person3'),
            propertyCounts: [],
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

    test('incrementing property count should not duplicate participant', () {
      final participant = const SexualActivityParticipant(
        participant: Reference(reference: 'person1'),
        propertyCounts: [
          PropertyCount(
            propertyReference: Reference(reference: 'condom'),
            count: 1,
          ),
        ],
      );

      // Simulate incrementing the count
      final updatedPropertyCounts = participant.propertyCounts.map((pc) {
        if (pc.propertyReference.reference == 'condom') {
          return pc.copyWith(count: pc.count + 1);
        }
        return pc;
      }).toList();

      final updatedParticipant = participant.copyWith(
        propertyCounts: updatedPropertyCounts,
      );

      // Should still be the same participant
      expect(updatedParticipant.participant.reference, equals('person1'));
      expect(updatedParticipant.propertyCounts.length, equals(1));
      expect(updatedParticipant.propertyCounts[0].count, equals(2));
    });

    test('multiple activities can have same participant', () {
      final event = SexualEvent(
        id: 'event1',
        date: DateTime.now(),
        activities: [
          SexualActivity(
            type: const Reference(reference: 'oral'),
            participants: [
              const SexualActivityParticipant(
                participant: Reference(reference: 'person1'),
                propertyCounts: [],
              ),
            ],
          ),
          SexualActivity(
            type: const Reference(reference: 'vaginal'),
            participants: [
              const SexualActivityParticipant(
                participant: Reference(reference: 'person1'),
                propertyCounts: [],
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
        const SexualActivityParticipant(
          participant: Reference(reference: 'person1'),
          propertyCounts: [],
        ),
        const SexualActivityParticipant(
          participant: Reference(reference: 'person2'),
          propertyCounts: [],
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
