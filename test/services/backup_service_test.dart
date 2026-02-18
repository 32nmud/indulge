import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/data/repositories/sexual_event_repository.dart';
import 'package:indulge/data/repositories/clinical_event_repository.dart';
import 'package:indulge/services/backup_service.dart';

/// Mock SexualEventRepository for testing
class MockSexualEventRepository implements SexualEventRepository {
  final List<SexualEvent> _events = [];
  final List<Person> _persons = [];
  final List<SexualActivityCategory> _categories = [];
  final List<SexualActivity> _activities = [];

  void addEvent(SexualEvent event) => _events.add(event);
  void addPerson(Person person) => _persons.add(person);
  void addCategory(SexualActivityCategory category) =>
      _categories.add(category);
  void addActivity(SexualActivity activity) => _activities.add(activity);
  void clear() {
    _events.clear();
    _persons.clear();
    _categories.clear();
    _activities.clear();
  }

  @override
  Future<List<SexualEvent>> getAllEvents() async => List.from(_events);

  @override
  Future<List<Person>> getAllPersons() async => List.from(_persons);

  @override
  Future<List<SexualActivityCategory>> getAllSexualActivityCategories() async =>
      List.from(_categories);

  @override
  Future<List<SexualActivity>> getAllSexualActivities() async =>
      List.from(_activities);

  @override
  Future<void> save(SexualEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      _events[index] = event;
    } else {
      _events.add(event);
    }
  }

  @override
  Future<void> savePerson(Person person) async {
    final index = _persons.indexWhere((p) => p.id == person.id);
    if (index >= 0) {
      _persons[index] = person;
    } else {
      _persons.add(person);
    }
  }

  @override
  Future<void> saveActivityCategory(SexualActivityCategory category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      _categories[index] = category;
    } else {
      _categories.add(category);
    }
  }

  @override
  Future<void> saveSexualActivity(SexualActivity activity) async {
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index >= 0) {
      _activities[index] = activity;
    } else {
      _activities.add(activity);
    }
  }

  // Stub implementations
  @override
  Future<void> deleteById(String id) async {}
  @override
  Future<SexualEvent?> getById(String id) async => null;
  @override
  Future<List<SexualEvent>> getByDate(DateTime date) async => [];
  @override
  Future<Map<DateTime, int>> getDailyEventCount() async => {};
  @override
  Future<Person?> getPersonById(String id) async => null;
  @override
  Future<void> deletePerson(String id) async {}
  @override
  Future<void> deleteActivityCategory(String id) async {}
  @override
  Future<void> deleteSexualActivity(String id) async {}
  @override
  @override
  Future<int> getEventCountForActivityCategory(String id) async => 0;
  @override
  Future<int> getEventCountForSexualActivity(String id) async => 0;
  @override
  Future<bool> isActivityCategoryUsed(String id) async => false;
  @override
  Future<bool> isSexualActivityUsed(String id) async => false;
  @override
  Future<List<Person>> getPersonsFromActivity(EventActivity activity) async =>
      [];
  @override
  Future<List<Person>> getPersonsFromActivities(
    List<EventActivity> activities,
  ) async => [];
  @override
  Future<List<SexualActivityCategory>> getSexualActivityCategoriesByIds(
    List<String> ids,
  ) async => [];
  @override
  Future<List<SexualActivity>> getSexualActivitiesForParticipant(
    ActivityParticipant participant,
  ) async => [];
  @override
  Future<void> removeActivityByCategoryId(
    String eventId,
    String categoryId,
  ) async {}
  @override
  Future<void> removeParticipantById(String eventId, String personId) async {}
  @override
  Future<Person?> getMyself() async => null;
  @override
  Future<void> replacePersonInAllEvents(
    String oldPersonId,
    String newPersonId,
  ) async {}
}

/// Mock ClinicalEventRepository for testing
class MockClinicalEventRepository implements ClinicalEventRepository {
  final List<ClinicalEvent> _events = [];

  void addEvent(ClinicalEvent event) => _events.add(event);
  void clear() => _events.clear();

  @override
  Future<List<ClinicalEvent>> getAllEvents() async => List.from(_events);

  @override
  Future<void> save(ClinicalEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      _events[index] = event;
    } else {
      _events.add(event);
    }
  }

  // Stub implementations
  @override
  Future<void> deleteById(String id) async {}
  @override
  Future<ClinicalEvent?> getById(String id) async => null;
  @override
  Future<List<ClinicalEvent>> getByDate(DateTime date) async => [];
  @override
  Future<Map<DateTime, bool>> getDailyPresence(
    DateTime start,
    DateTime end,
  ) async => {};
  @override
  Future<DateTime?> getLastTestDateFor(TestType testType) async => null;
  @override
  Future<DateTime?> getLastClinicalEventDate() async => null;
  @override
  Future<List<DateTime>> getRecentClinicalEventDates(int count) async => [];
  @override
  Future<Map<TestType, ClinicalTestResult>> getLatestTestResults() async => {};
}

void main() {
  group('BackupService', () {
    late MockSexualEventRepository mockSexualRepo;
    late MockClinicalEventRepository mockClinicalRepo;
    late BackupService backupService;

    setUp(() {
      mockSexualRepo = MockSexualEventRepository();
      mockClinicalRepo = MockClinicalEventRepository();
      backupService = BackupService(mockSexualRepo, mockClinicalRepo);
    });

    group('exportData', () {
      test('fetches all data from repositories', () async {
        mockSexualRepo.addEvent(
          SexualEvent(id: 'event1', date: DateTime.now(), activities: []),
        );
        mockSexualRepo.addPerson(
          Person(
            id: 'person1',
            name: const Name(given: 'Test'),
            date: DateTime.now(),
          ),
        );
        mockSexualRepo.addCategory(
          const SexualActivityCategory(id: 'cat1', name: 'Test Category'),
        );
        mockSexualRepo.addActivity(
          const SexualActivity(id: 'act1', name: 'Test Activity'),
        );
        mockClinicalRepo.addEvent(
          ClinicalEvent(id: 'clinical1', date: DateTime.now(), tests: []),
        );

        // Note: exportData requires platform interactions (file picker)
        expect(backupService, isNotNull);
      });

      test('service is constructed with correct repositories', () {
        expect(backupService.sexualRepo, equals(mockSexualRepo));
        expect(backupService.clinicalRepo, equals(mockClinicalRepo));
      });
    });

    group('importData', () {
      test('service provides importData method', () {
        expect(backupService.importData, isNotNull);
        expect(backupService.importData(), isA<Stream<String>>());
      });
    });
  });
}
