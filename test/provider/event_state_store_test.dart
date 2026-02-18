import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state_store.dart';

void main() {
  group('EventStateStore', () {
    late EventStateStore store;

    setUp(() {
      store = EventStateStore();
    });

    group('initial state', () {
      test('has empty state with null values', () {
        expect(store.state.selectedEvent, isNull);
        expect(store.state.selectedDate, isNull);
        expect(store.state.currentEvents, isNull);
        expect(store.state.dailyEventCount, isNull);
        expect(store.state.needsDataRefresh, isFalse);
      });

      test('starts with needsDataRefresh as false', () {
        expect(store.needsDataRefresh, isFalse);
      });
    });

    group('markDataDirty and clearDataDirty', () {
      test('markDataDirty sets needsDataRefresh to true', () {
        store.markDataDirty();

        expect(store.needsDataRefresh, isTrue);
        expect(store.state.needsDataRefresh, isTrue);
      });

      test('clearDataDirty sets needsDataRefresh to false', () {
        store.markDataDirty();
        store.clearDataDirty();

        expect(store.needsDataRefresh, isFalse);
        expect(store.state.needsDataRefresh, isFalse);
      });

      test('notifies listeners when marking dirty', () {
        var notified = false;
        store.addListener(() => notified = true);

        store.markDataDirty();

        expect(notified, isTrue);
      });
    });

    group('sexual event setters', () {
      test('setDailyEventCount updates state', () {
        final counts = {DateTime(2024, 1, 15): 3};

        store.setDailyEventCount(counts);

        expect(store.state.dailyEventCount, equals(counts));
      });

      test('setCurrentEvents updates state', () {
        final events = [
          SexualEvent(id: 'e1', date: DateTime.now(), activities: []),
        ];

        store.setCurrentEvents(events);

        expect(store.state.currentEvents, equals(events));
        expect(store.state.currentEvents!.length, equals(1));
      });

      test('setSelectedEvent updates state', () {
        final event = SexualEvent(
          id: 'event1',
          date: DateTime.now(),
          activities: [],
        );

        store.setSelectedEvent(event);

        expect(store.state.selectedEvent, equals(event));
      });

      test('setSelectedDate updates state', () {
        final date = DateTime(2024, 6, 15);

        store.setSelectedDate(date);

        expect(store.state.selectedDate, equals(date));
      });

      test('setSexualActivityCategories updates state', () {
        final categories = {
          'oral': const SexualActivityCategory(id: 'oral', name: 'Oral'),
        };

        store.setSexualActivityCategories(categories);

        expect(store.state.sexualActivityCategories, equals(categories));
      });

      test('setSexualActivities updates state', () {
        final activities = {
          'giving': const SexualActivity(id: 'giving', name: 'Giving'),
        };

        store.setSexualActivities(activities);

        expect(store.state.sexualActivities, equals(activities));
      });

      test('setMyself updates state', () {
        final me = Person(
          id: 'me',
          name: const Name(given: 'Me'),
          date: DateTime.now(),
          isSelf: true,
        );

        store.setMyself(me);

        expect(store.myselfId, equals('me'));
        expect(store.state.myself, equals(me));
      });

      test('setAllPersons updates state', () {
        final persons = [
          Person(
            id: 'p1',
            name: const Name(given: 'Person1'),
            date: DateTime.now(),
          ),
        ];

        store.setAllPersons(persons);

        expect(store.state.allPersons, equals(persons));
        expect(store.allPersonsMap, isNotNull);
        expect(store.allPersonsMap!['p1'], isNotNull);
      });

      test('getPersonById returns person when cached', () {
        final persons = [
          Person(
            id: 'p1',
            name: const Name(given: 'Person1'),
            date: DateTime.now(),
          ),
        ];
        store.setAllPersons(persons);

        final person = store.getPersonById('p1');

        expect(person, isNotNull);
        expect(person!.id, equals('p1'));
      });

      test('getPersonById returns null for unknown id', () {
        store.setAllPersons([]);

        final person = store.getPersonById('unknown');

        expect(person, isNull);
      });

      test('getPersonById returns null when cache is empty', () {
        final person = store.getPersonById('p1');

        expect(person, isNull);
      });

      test('allPersonsOrEmpty returns empty map when cache is null', () {
        final result = store.allPersonsOrEmpty;

        expect(result, isEmpty);
      });

      test('allPersonsOrEmpty returns map when cache exists', () {
        final persons = [
          Person(
            id: 'p1',
            name: const Name(given: 'Person1'),
            date: DateTime.now(),
          ),
        ];
        store.setAllPersons(persons);

        final result = store.allPersonsOrEmpty;

        expect(result, isNotEmpty);
        expect(result['p1'], isNotNull);
      });
    });

    group('sexual activity accessors', () {
      test('getActivityById returns activity when exists', () {
        final activities = {
          'giving': const SexualActivity(id: 'giving', name: 'Giving'),
        };
        store.setSexualActivities(activities);

        final activity = store.getActivityById('giving');

        expect(activity, isNotNull);
        expect(activity!.name, equals('Giving'));
      });

      test('getActivityById returns null for unknown id', () {
        store.setSexualActivities({});

        final activity = store.getActivityById('unknown');

        expect(activity, isNull);
      });

      test('getCategoryById returns category when exists', () {
        final categories = {
          'oral': const SexualActivityCategory(id: 'oral', name: 'Oral'),
        };
        store.setSexualActivityCategories(categories);

        final category = store.getCategoryById('oral');

        expect(category, isNotNull);
        expect(category!.name, equals('Oral'));
      });

      test('getCategoryById returns null for unknown id', () {
        store.setSexualActivityCategories({});

        final category = store.getCategoryById('unknown');

        expect(category, isNull);
      });

      test('sexualActivitiesMap returns null when not set', () {
        expect(store.sexualActivitiesMap, isNull);
      });

      test('sexualActivityCategoriesMap returns null when not set', () {
        expect(store.sexualActivityCategoriesMap, isNull);
      });
    });

    group('location setters', () {
      test('setSelectedEventLocation updates state', () {
        final location = Location(latitude: 0.0, longitude: 0.0);

        store.setSelectedEventLocation(location);

        expect(store.state.selectedEventLocation, equals(location));
      });
    });

    group('participant setters', () {
      test('setSelectedEventParticipants updates state', () {
        final participants = [
          Person(
            id: 'p1',
            name: const Name(given: 'Person1'),
            date: DateTime.now(),
          ),
        ];

        store.setSelectedEventParticipants(participants);

        expect(store.state.selectedEventParticipants, equals(participants));
      });

      test('setSelectedEventSexualActivityParticipants updates state', () {
        final sap = [
          const ActivityParticipant(participant: Reference(reference: 'p1')),
        ];

        store.setSelectedEventSexualActivityParticipants(sap);

        expect(
          store.state.selectedEventSexualActivityParticipants,
          equals(sap),
        );
      });

      test('setSelectedEventActivityParticipants updates state', () {
        final map = {
          'oral': [
            Person(
              id: 'p1',
              name: const Name(given: 'Person1'),
              date: DateTime.now(),
            ),
          ],
        };

        store.setSelectedEventActivityParticipants(map);

        expect(store.state.selectedEventActivityParticipants, equals(map));
      });
    });

    group('clinical event setters', () {
      test('setDailyClinicalEventPresence updates state', () {
        final presence = {DateTime(2024, 1, 15): true};

        store.setDailyClinicalEventPresence(presence);

        expect(store.state.dailyClinicalEventPresence, equals(presence));
      });

      test('setCurrentClinicalEvents updates state', () {
        final events = [
          ClinicalEvent(id: 'ce1', date: DateTime.now(), tests: []),
        ];

        store.setCurrentClinicalEvents(events);

        expect(store.state.currentClinicalEvents, equals(events));
      });

      test('setSelectedClinicalEvent updates state', () {
        final event = ClinicalEvent(id: 'ce1', date: DateTime.now(), tests: []);

        store.setSelectedClinicalEvent(event);

        expect(store.state.selectedClinicalEvent, equals(event));
      });
    });

    group('applyClinicalEventSave', () {
      test('updates multiple fields atomically', () {
        final presence = {DateTime(2024, 1, 15): true};
        final events = [
          ClinicalEvent(id: 'ce1', date: DateTime(2024, 1, 15), tests: []),
        ];
        final selected = ClinicalEvent(
          id: 'ce1',
          date: DateTime(2024, 1, 15),
          tests: [],
        );

        store.applyClinicalEventSave(
          presence: presence,
          eventsForDate: events,
          selected: selected,
        );

        expect(store.state.dailyClinicalEventPresence, equals(presence));
        expect(store.state.currentClinicalEvents, equals(events));
        expect(store.state.selectedClinicalEvent, equals(selected));
        expect(store.state.needsDataRefresh, isTrue);
      });

      test('notifies listeners only once', () {
        var notifyCount = 0;
        store.addListener(() => notifyCount++);

        store.applyClinicalEventSave(
          presence: {},
          eventsForDate: [],
          selected: null,
        );

        expect(notifyCount, equals(1));
      });
    });

    group('applySexualEventSave', () {
      test('updates multiple fields atomically', () {
        final counts = {DateTime(2024, 1, 15): 3};
        final events = [
          SexualEvent(id: 'e1', date: DateTime(2024, 1, 15), activities: []),
        ];
        final selected = SexualEvent(
          id: 'e1',
          date: DateTime(2024, 1, 15),
          activities: [],
        );

        store.applySexualEventSave(
          dailyCounts: counts,
          eventsForDate: events,
          selected: selected,
        );

        expect(store.state.dailyEventCount, equals(counts));
        expect(store.state.currentEvents, equals(events));
        expect(store.state.selectedEvent, equals(selected));
        expect(store.state.needsDataRefresh, isTrue);
      });

      test('notifies listeners only once', () {
        var notifyCount = 0;
        store.addListener(() => notifyCount++);

        store.applySexualEventSave(
          dailyCounts: {},
          eventsForDate: [],
          selected: null,
        );

        expect(notifyCount, equals(1));
      });
    });

    group('notifyListeners', () {
      test('notifies when state is changed via setter', () {
        var notified = false;
        store.addListener(() => notified = true);

        store.setSelectedDate(DateTime.now());

        expect(notified, isTrue);
      });
    });
  });
}
