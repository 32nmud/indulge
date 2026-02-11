import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';

void main() {
  group('SexualEventsProvider', () {
    // Note: The SexualEventsProvider creates its own repository internally,
    // making it difficult to unit test without a full database setup.
    // These tests focus on the EventState which the provider manages.
    // For true provider testing, integration tests would be more appropriate.

    group('EventState', () {
      test('creates default state with null values', () {
        final state = EventState();

        expect(state.selectedEvent, isNull);
        expect(state.selectedEventSexualActivityParticipants, isNull);
        expect(state.selectedEventParticipants, isNull);
        expect(state.selectedEventActivityParticipants, isNull);
        expect(state.sexualActivityCategories, isNull);
        expect(state.sexualActivities, isNull);
        expect(state.currentEvents, isNull);
        expect(state.selectedDate, isNull);
        expect(state.dailyEventCount, isNull);
        expect(state.myself, isNull);
      });

      test('copyWith creates new instance with updated values', () {
        final original = EventState();
        final testDate = DateTime(2024, 1, 15);

        final updated = original.copyWith(selectedDate: testDate);

        expect(updated.selectedDate, equals(testDate));
        expect(original.selectedDate, isNull); // Original unchanged
      });

      test('copyWith preserves unmodified values', () {
        final testDate = DateTime(2024, 1, 15);
        final testEvent = SexualEvent(
          id: 'test',
          date: testDate,
          activities: [],
        );

        final original = EventState(
          selectedDate: testDate,
          selectedEvent: testEvent,
        );

        final updated = original.copyWith(dailyEventCount: {testDate: 1});

        expect(updated.selectedDate, equals(testDate));
        expect(updated.selectedEvent, equals(testEvent));
        expect(updated.dailyEventCount![testDate], equals(1));
      });

      test('stores sexual activity types as map', () {
        const category1 = SexualActivityCategory(id: 'oral', name: 'Oral');
        const category2 = SexualActivityCategory(
          id: 'vaginal',
          name: 'Vaginal',
        );

        final state = EventState(
          sexualActivityCategories: {'oral': category1, 'vaginal': category2},
        );

        expect(state.sexualActivityCategories!['oral'], equals(category1));
        expect(state.sexualActivityCategories!['vaginal'], equals(category2));
        expect(state.sexualActivityCategories!.length, equals(2));
      });

      test('stores sexual activity type properties as map', () {
        const activity1 = SexualActivity(
          id: 'giving',
          name: 'Giving',
          isRisky: false,
        );
        const activity2 = SexualActivity(
          id: 'receiving',
          name: 'Receiving',
          isRisky: true,
        );

        final state = EventState(
          sexualActivities: {'giving': activity1, 'receiving': activity2},
        );

        expect(state.sexualActivities!['giving'], equals(activity1));
        expect(state.sexualActivities!['receiving'], equals(activity2));
        expect(state.sexualActivities!.length, equals(2));
      });

      test('stores current events list', () {
        final testDate = DateTime(2024, 1, 15);
        final event1 = SexualEvent(id: 'e1', date: testDate, activities: []);
        final event2 = SexualEvent(id: 'e2', date: testDate, activities: []);

        final state = EventState(currentEvents: [event1, event2]);

        expect(state.currentEvents!.length, equals(2));
        expect(state.currentEvents![0], equals(event1));
        expect(state.currentEvents![1], equals(event2));
      });

      test('stores daily event count map', () {
        final date1 = DateTime(2024, 1, 15);
        final date2 = DateTime(2024, 1, 16);

        final state = EventState(dailyEventCount: {date1: 3, date2: 1});

        expect(state.dailyEventCount![date1], equals(3));
        expect(state.dailyEventCount![date2], equals(1));
      });

      test('stores selected event with participants', () {
        final testDate = DateTime(2024, 1, 15);
        final person1 = Person(
          id: 'p1',
          name: const Name(given: 'Person1'),
          date: DateTime.now(),
        );

        final testEvent = SexualEvent(
          id: 'event1',
          date: testDate,
          activities: [
            const EventActivity(
              category: Reference(reference: 'oral'),
              participants: [
                ActivityParticipant(participant: Reference(reference: 'p1')),
              ],
            ),
          ],
        );

        final state = EventState(
          selectedEvent: testEvent,
          selectedEventParticipants: [person1],
        );

        expect(state.selectedEvent, equals(testEvent));
        expect(state.selectedEventParticipants!.length, equals(1));
        expect(state.selectedEventParticipants![0], equals(person1));
      });

      test('stores activity participants map', () {
        final person1 = Person(
          id: 'p1',
          name: const Name(given: 'Person1'),
          date: DateTime.now(),
        );
        final person2 = Person(
          id: 'p2',
          name: const Name(given: 'Person2'),
          date: DateTime.now(),
        );

        final state = EventState(
          selectedEventActivityParticipants: {
            'oral': [person1],
            'vaginal': [person1, person2],
          },
        );

        expect(
          state.selectedEventActivityParticipants!['oral']!.length,
          equals(1),
        );
        expect(
          state.selectedEventActivityParticipants!['vaginal']!.length,
          equals(2),
        );
      });

      test('stores myself person', () {
        final me = Person(
          id: 'me',
          name: const Name(given: 'Me'),
          date: DateTime.now(),
          isSelf: true,
        );

        final state = EventState(myself: me);

        expect(state.myself, equals(me));
        expect(state.myself!.isSelf, isTrue);
      });

      test('copyWith can update selected event', () {
        final event1 = SexualEvent(
          id: 'event1',
          date: DateTime.now(),
          activities: [],
        );
        final event2 = SexualEvent(
          id: 'event2',
          date: DateTime.now(),
          activities: [],
        );

        final state = EventState(selectedEvent: event1);
        final updated = state.copyWith(selectedEvent: event2);

        expect(state.selectedEvent, equals(event1));
        expect(updated.selectedEvent, equals(event2));
      });

      test('copyWith can update current events list', () {
        final event1 = SexualEvent(
          id: 'event1',
          date: DateTime.now(),
          activities: [],
        );
        final event2 = SexualEvent(
          id: 'event2',
          date: DateTime.now(),
          activities: [],
        );

        final state = EventState(currentEvents: [event1]);
        final updated = state.copyWith(currentEvents: [event1, event2]);

        expect(state.currentEvents!.length, equals(1));
        expect(updated.currentEvents!.length, equals(2));
      });

      test('handles complex state with multiple fields', () {
        final testDate = DateTime(2024, 1, 15);
        final testEvent = SexualEvent(
          id: 'event1',
          date: testDate,
          activities: [],
        );
        final person = Person(
          id: 'p1',
          name: const Name(given: 'Test'),
          date: DateTime.now(),
        );

        final state = EventState(
          selectedDate: testDate,
          selectedEvent: testEvent,
          currentEvents: [testEvent],
          selectedEventParticipants: [person],
          dailyEventCount: {testDate: 1},
          sexualActivityCategories: {
            'oral': const SexualActivityCategory(id: 'oral', name: 'Oral'),
          },
          sexualActivities: {
            'giving': const SexualActivity(id: 'giving', name: 'Giving'),
          },
        );

        expect(state.selectedDate, equals(testDate));
        expect(state.selectedEvent, equals(testEvent));
        expect(state.currentEvents!.length, equals(1));
        expect(state.selectedEventParticipants!.length, equals(1));
        expect(state.dailyEventCount![testDate], equals(1));
        expect(state.sexualActivityCategories!.length, equals(1));
        expect(state.sexualActivities!.length, equals(1));
      });
    });
  });
}
