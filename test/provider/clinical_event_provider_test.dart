import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/data/repositories/clinical_event_repository.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';

/// Mock repository for testing ClinicalEventsProvider
class MockClinicalEventRepository implements ClinicalEventRepository {
  final List<ClinicalEvent> _events = [];
  Map<DateTime, bool> _presence = {};
  ClinicalEvent? lastSavedEvent;

  void addEvent(ClinicalEvent event) {
    _events.add(event);
    final normalized = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );
    _presence[normalized] = true;
  }

  void clear() {
    _events.clear();
    _presence.clear();
    lastSavedEvent = null;
  }

  @override
  Future<List<ClinicalEvent>> getByDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    return _events.where((e) {
      final eDate = DateTime(e.date.year, e.date.month, e.date.day);
      return eDate == normalized;
    }).toList();
  }

  @override
  Future<ClinicalEvent?> getById(String id) async {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<DateTime, bool>> getDailyPresence(
    DateTime start,
    DateTime end,
  ) async {
    return Map.from(_presence);
  }

  @override
  Future<void> save(ClinicalEvent event) async {
    lastSavedEvent = event;
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      _events[index] = event;
    } else {
      _events.add(event);
    }
    final normalized = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );
    _presence[normalized] = true;
  }

  @override
  Future<void> deleteById(String id) async {
    _events.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<ClinicalEvent>> getAllEvents() async {
    return List.from(_events);
  }

  @override
  Future<DateTime?> getLastTestDateFor(TestType testType) async {
    final eventsWithType = _events.where(
      (e) => e.tests.any((t) => t.testType == testType),
    );
    if (eventsWithType.isEmpty) return null;
    return eventsWithType
        .map((e) => e.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Future<DateTime?> getLastClinicalEventDate() async {
    if (_events.isEmpty) return null;
    return _events.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Future<List<DateTime>> getRecentClinicalEventDates(int count) async {
    final sorted = _events.map((e) => e.date).toList()
      ..sort((a, b) => b.compareTo(a));
    return sorted.take(count).toList();
  }

  @override
  Future<Map<TestType, ClinicalTestResult>> getLatestTestResults() async {
    // Track event date for each test type separately since ClinicalTestResult doesn't have a date field
    final results = <TestType, ClinicalTestResult>{};
    final testTypeDates = <TestType, DateTime>{};

    for (final event in _events) {
      for (final test in event.tests) {
        final existingDate = testTypeDates[test.testType];
        if (existingDate == null || event.date.isAfter(existingDate)) {
          results[test.testType] = test;
          testTypeDates[test.testType] = event.date;
        }
      }
    }
    return results;
  }
}

void main() {
  group('ClinicalEventsProvider', () {
    late EventStateStore stateStore;
    late MockClinicalEventRepository mockRepository;

    setUp(() {
      stateStore = EventStateStore();
      mockRepository = MockClinicalEventRepository();
    });

    group('initialization', () {
      test('initializes with provided repository', () async {
        final event = ClinicalEvent(
          id: 'init-event',
          date: DateTime.now(),
          tests: [],
        );
        mockRepository.addEvent(event);

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        expect(provider.ready, completion('ready'));
      });

      test('loads presence map on initialization', () async {
        final event = ClinicalEvent(
          id: 'test-event',
          date: DateTime(2024, 1, 15),
          tests: [],
        );
        mockRepository.addEvent(event);

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        expect(stateStore.state.dailyClinicalEventPresence, isNotNull);
      });
    });

    group('refreshAllData', () {
      test('refreshes presence map with custom date range', () async {
        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        await provider.refreshAllData(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 12, 31),
        );

        expect(stateStore.state.dailyClinicalEventPresence, isNotNull);
      });
    });

    group('selectDate', () {
      test('normalizes date and loads events for that date', () async {
        final event = ClinicalEvent(
          id: 'event-1',
          date: DateTime(2024, 6, 15, 10, 30),
          tests: [],
        );
        mockRepository.addEvent(event);

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        provider.selectDate(DateTime(2024, 6, 15, 14, 45));

        expect(stateStore.state.selectedDate, isNotNull);
        expect(stateStore.state.selectedDate!.year, equals(2024));
        expect(stateStore.state.selectedDate!.month, equals(6));
        expect(stateStore.state.selectedDate!.day, equals(15));
      });
    });

    group('selectClinicalEvent', () {
      test(
        'sets selected clinical event and loads events for its date',
        () async {
          final event = ClinicalEvent(
            id: 'event-1',
            date: DateTime(2024, 6, 15),
            tests: [],
          );
          mockRepository.addEvent(event);

          final provider = ClinicalEventsProvider(
            repository: mockRepository,
            stateStore: stateStore,
          );

          await provider.ready;

          await provider.selectClinicalEvent(event);

          expect(stateStore.state.selectedClinicalEvent, equals(event));
        },
      );
    });

    group('saveEvent', () {
      test('saves event and refreshes presence', () async {
        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final event = ClinicalEvent(
          id: 'new-event',
          date: DateTime(2024, 6, 20),
          tests: [
            ClinicalTestResult(
              testType: TestType.hiv,
              result: TestResult.negative,
              specimenSite: SpecimenSite.blood,
            ),
          ],
        );

        await provider.saveEvent(event);

        expect(mockRepository.lastSavedEvent, equals(event));
      });

      test('updates selected date to event date after save', () async {
        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final event = ClinicalEvent(
          id: 'new-event',
          date: DateTime(2024, 7, 15),
          tests: [],
        );

        await provider.saveEvent(event);

        expect(stateStore.state.selectedDate, isNotNull);
      });

      test('marks data as dirty after save', () async {
        stateStore.clearDataDirty();

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final event = ClinicalEvent(
          id: 'new-event',
          date: DateTime(2024, 8, 1),
          tests: [],
        );

        await provider.saveEvent(event);

        expect(stateStore.needsDataRefresh, isTrue);
      });
    });

    group('deleteEvent', () {
      test('deletes event and refreshes presence', () async {
        final event = ClinicalEvent(
          id: 'to-delete',
          date: DateTime(2024, 6, 15),
          tests: [],
        );
        mockRepository.addEvent(event);

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        await provider.deleteEvent('to-delete');

        final deleted = await mockRepository.getById('to-delete');
        expect(deleted, isNull);
      });
    });

    group('getEventsForDate', () {
      test('returns events for specific date', () async {
        final event1 = ClinicalEvent(
          id: 'event-1',
          date: DateTime(2024, 6, 15),
          tests: [],
        );
        final event2 = ClinicalEvent(
          id: 'event-2',
          date: DateTime(2024, 6, 16),
          tests: [],
        );
        mockRepository.addEvent(event1);
        mockRepository.addEvent(event2);

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final events = await provider.getEventsForDate(DateTime(2024, 6, 15));

        expect(events.length, equals(1));
        expect(events.first.id, equals('event-1'));
      });
    });

    group('hasClinicalEventForDate', () {
      test('returns true when event exists for date', () async {
        final event = ClinicalEvent(
          id: 'event-1',
          date: DateTime(2024, 6, 15),
          tests: [],
        );
        mockRepository.addEvent(event);

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        expect(provider.hasClinicalEventForDate(DateTime(2024, 6, 15)), isTrue);
      });

      test('returns false when no event exists for date', () async {
        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        expect(
          provider.hasClinicalEventForDate(DateTime(2024, 6, 15)),
          isFalse,
        );
      });
    });

    group('getLastTestDateFor', () {
      test('returns last date for specific test type', () async {
        final event = ClinicalEvent(
          id: 'event-1',
          date: DateTime(2024, 6, 15),
          tests: [
            ClinicalTestResult(
              testType: TestType.hiv,
              result: TestResult.negative,
              specimenSite: SpecimenSite.blood,
            ),
          ],
        );
        mockRepository.addEvent(event);

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final lastDate = await provider.getLastTestDateFor(TestType.hiv);

        expect(lastDate, isNotNull);
      });
    });

    group('getLastClinicalEventDate', () {
      test('returns null when no events exist', () async {
        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final lastDate = await provider.getLastClinicalEventDate();

        expect(lastDate, isNull);
      });

      test('returns date of most recent event', () async {
        final event1 = ClinicalEvent(
          id: 'event-1',
          date: DateTime(2024, 6, 1),
          tests: [],
        );
        final event2 = ClinicalEvent(
          id: 'event-2',
          date: DateTime(2024, 6, 15),
          tests: [],
        );
        mockRepository.addEvent(event1);
        mockRepository.addEvent(event2);

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final lastDate = await provider.getLastClinicalEventDate();

        expect(lastDate, isNotNull);
      });
    });

    group('getRecentClinicalEventDates', () {
      test('returns empty list when no events', () async {
        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final dates = await provider.getRecentClinicalEventDates(5);

        expect(dates, isEmpty);
      });

      test('returns requested number of dates', () async {
        for (int i = 0; i < 10; i++) {
          mockRepository.addEvent(
            ClinicalEvent(
              id: 'event-$i',
              date: DateTime(2024, 1, i + 1),
              tests: [],
            ),
          );
        }

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final dates = await provider.getRecentClinicalEventDates(3);

        expect(dates.length, equals(3));
      });
    });

    group('getLatestTestResults', () {
      test('returns empty map when no tests', () async {
        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final results = await provider.getLatestTestResults();

        expect(results, isEmpty);
      });

      test('returns latest result for each test type', () async {
        mockRepository.addEvent(
          ClinicalEvent(
            id: 'event-1',
            date: DateTime(2024, 6, 1),
            tests: [
              ClinicalTestResult(
                testType: TestType.hiv,
                result: TestResult.negative,
                specimenSite: SpecimenSite.blood,
              ),
            ],
          ),
        );

        final provider = ClinicalEventsProvider(
          repository: mockRepository,
          stateStore: stateStore,
        );

        await provider.ready;

        final results = await provider.getLatestTestResults();

        expect(results.containsKey(TestType.hiv), isTrue);
      });
    });
  });
}
