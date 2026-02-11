import 'package:flutter/cupertino.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/data/repositories/sexual_event_repository.dart';
import 'package:indulge/provider/event_state.dart';

class SexualEventsProvider extends ChangeNotifier {
  EventState _state = EventState();
  late SexualEventRepository _repository;
  late final Future<String> _ready;

  SexualEventsProvider() {
    _ready = _initProvider();
  }

  Future<String> _initProvider() async {
    _repository = await SexualEventRepository.create();
    final counts = await _repository.getDailyEventCount();
    final categories = await _loadSexualActivityCategories();
    final activities = await _loadSexualActivities();
    final myself = await _repository.getMyself();
    _state = _state.copyWith(
      dailyEventCount: counts,
      sexualActivityCategories: categories,
      sexualActivities: activities,
      myself: myself,
    );
    return "ready!";
  }

  /// Reloads all data from the repository and updates the state.
  /// Useful after bulk operations like import.
  Future<void> refreshAllData() async {
    final counts = await _repository.getDailyEventCount();
    final categories = await _loadSexualActivityCategories();
    final activities = await _loadSexualActivities();
    final myself = await _repository.getMyself();

    _state = _state.copyWith(
      dailyEventCount: counts,
      sexualActivityCategories: categories,
      sexualActivities: activities,
      myself: myself,
    );

    // Also reload events for the currently selected date
    await _loadEventsForDate(_state.selectedDate);

    notifyListeners();
  }

  Future<String> get ready => _ready;

  EventState get state => _state;

  void selectDate(DateTime date) {
    _state = _state.copyWith(selectedDate: date);
    _loadEventsForDate(date);
    notifyListeners();
  }

  Future<void> selectEvent(SexualEvent event) async {
    try {
      // 1. Fetch Related Data

      // 1a. Persons (Participants)
      final participants = await _repository.getPersonsFromActivities(
        event.activities,
      );

      // 2. Construct State Fields
      // List<Person> selectedEventParticipants
      final eventParticipants = participants;

      // Map<String, List<Person>> selectedEventActivityParticipants
      // Key: Activity Category ID
      final activityParticipantsMap = <String, List<Person>>{};
      final personMap = {for (var p in participants) p.id: p};

      for (var activity in event.activities) {
        final categoryId = activity.category.reference;
        final currentList = activityParticipantsMap[categoryId] ?? [];

        for (var participant in activity.participants) {
          if (participant.participant.resourceType == 'Person' &&
              personMap.containsKey(participant.participant.reference)) {
            final person = personMap[participant.participant.reference]!;
            if (!currentList.any((p) => p.id == person.id)) {
              currentList.add(person);
            }
          }
        }
        activityParticipantsMap[categoryId] = currentList;
      }

      // List<ActivityParticipant>
      // Aggregate participation counts
      final sapMap = <String, ActivityParticipant>{};

      for (var activity in event.activities) {
        final categoryId = activity.category.reference;
        for (var participant in activity.participants) {
          if (participant.participant.resourceType != 'Person') continue;

          final key = '${participant.participant.reference}_$categoryId';

          if (!sapMap.containsKey(key)) {
            sapMap[key] = participant;
          }
        }
      }
      final sapList = sapMap.values.toList();

      // 3. Update State
      _state = _state.copyWith(
        selectedEvent: event,
        selectedEventSexualActivityParticipants: sapList,
        selectedEventParticipants: eventParticipants,
        selectedEventActivityParticipants: activityParticipantsMap,
      );
    } catch (e) {
      debugPrint("Error loading event details: $e");
    }

    _loadEventsForDate(_state.selectedDate);
    notifyListeners();
  }

  Future<void> removeActivity(EventActivity activity) async {
    if (_state.selectedEvent == null) return;

    final currentActivities = _state.selectedEvent!.activities.toList();
    currentActivities.remove(activity);

    final updatedEvent = _state.selectedEvent!.copyWith(
      activities: currentActivities,
      lastModifiedDate: DateTime.now(),
    );

    await _repository.save(updatedEvent);
    await selectEvent(updatedEvent);
  }

  Future<void> removeParticipant(Person participant) async {
    if (_state.selectedEvent == null) return;

    final currentActivities = <EventActivity>[];

    for (final activity in _state.selectedEvent!.activities) {
      final updatedParticipants = activity.participants
          .where((ref) => ref.participant.reference != participant.id)
          .toList();

      currentActivities.add(
        activity.copyWith(participants: updatedParticipants),
      );
    }

    final updatedEvent = _state.selectedEvent!.copyWith(
      activities: currentActivities,
      lastModifiedDate: DateTime.now(),
    );

    await _repository.save(updatedEvent);
    await selectEvent(updatedEvent);
  }

  Future<void> removeActivityFromEdit(String activityCategoryId) async {
    if (_state.selectedEvent == null) return;

    await _repository.removeActivityByCategoryId(
      _state.selectedEvent!.id,
      activityCategoryId,
    );

    final updatedEvent = await _repository.getById(_state.selectedEvent!.id);
    if (updatedEvent != null) {
      await selectEvent(updatedEvent);
    } else {
      _loadEventsForDate(_state.selectedDate);
      notifyListeners();
    }
  }

  Future<void> removeParticipantFromEdit(String personId) async {
    if (_state.selectedEvent == null) return;

    await _repository.removeParticipantById(_state.selectedEvent!.id, personId);

    final updatedEvent = await _repository.getById(_state.selectedEvent!.id);
    if (updatedEvent != null) {
      await selectEvent(updatedEvent);
    } else {
      _loadEventsForDate(_state.selectedDate);
      notifyListeners();
    }
  }

  List<SexualActivity> getSexualActivitiesForPersonAndActivity(
    Person person,
    EventActivity activity,
  ) {
    List<SexualActivity> activities = [];
    for (ActivityParticipant activityParticipant in activity.participants) {
      for (var activityCount in activityParticipant.activityCounts) {
        if (activityCount.activityReference.resourceType == "SexualActivity" &&
            activityParticipant.participant.resourceType == "Person" &&
            activityParticipant.participant.reference == person.id &&
            _state.sexualActivities != null &&
            _state.sexualActivities!.containsKey(
              activityCount.activityReference.reference,
            )) {
          activities.add(
            _state.sexualActivities![activityCount
                .activityReference
                .reference]!,
          );
        }
      }
    }
    return activities;
  }

  Future<List<Person>> getPersonsForEvent(String eventId) async {
    SexualEvent? event = await _repository.getById(eventId);
    if (event == null) {
      return [];
    }

    return await _repository.getPersonsFromActivities(event.activities);
  }

  Future<List<Person>> getPersonsForActivity(EventActivity activity) async {
    return await _repository.getPersonsFromActivity(activity);
  }

  Future<List<Person>> getAllPersons() async {
    return await _repository.getAllPersons();
  }

  Future<Person?> getPersonById(String id) async {
    return await _repository.getPersonById(id);
  }

  Future<void> savePerson(Person person) async {
    await _repository.savePerson(person);
    notifyListeners();
  }

  Future<void> deletePerson(String id) async {
    await _repository.deletePerson(id);

    // Refresh daily event count (events may have been modified)
    final counts = await _repository.getDailyEventCount();
    _state = _state.copyWith(dailyEventCount: counts);

    // Reload current events to show updated participants
    await _loadEventsForDate(_state.selectedDate);

    // Clear selected event if it had this person
    if (_state.selectedEvent != null) {
      final updatedEvent = await _repository.getById(_state.selectedEvent!.id);
      if (updatedEvent != null) {
        await selectEvent(updatedEvent);
      } else {
        _state = _state.copyWith(
          selectedEvent: null,
          selectedEventSexualActivityParticipants: null,
          selectedEventParticipants: null,
          selectedEventActivityParticipants: null,
        );
      }
    }

    notifyListeners();
  }

  Future<void> saveEvent(SexualEvent event) async {
    await _repository.save(event);

    // Refresh daily event count
    final counts = await _repository.getDailyEventCount();
    _state = _state.copyWith(dailyEventCount: counts);

    // Reload events for the event's date
    await _loadEventsForDate(event.date);

    // Select the saved event
    await selectEvent(event);
  }

  Future<void> deleteEvent(String eventId) async {
    await _repository.deleteById(eventId);

    // Clear selected event and all related state if it was the one deleted
    if (_state.selectedEvent?.id == eventId) {
      _state = _state.copyWith(
        selectedEvent: null,
        selectedEventSexualActivityParticipants: null,
        selectedEventParticipants: null,
        selectedEventActivityParticipants: null,
      );
    }

    // Refresh daily event count
    final counts = await _repository.getDailyEventCount();
    _state = _state.copyWith(dailyEventCount: counts);

    // Reload events for current date
    await _loadEventsForDate(_state.selectedDate);
    notifyListeners();
  }

  Future<List<SexualEvent>> getAllEvents() async {
    return await _repository.getAllEvents();
  }

  Future<void> saveActivityCategory(
    SexualActivityCategory activityCategory,
  ) async {
    await _repository.saveActivityCategory(activityCategory);

    // Refresh activity categories in state
    final categories = await _loadSexualActivityCategories();
    _state = _state.copyWith(sexualActivityCategories: categories);

    notifyListeners();
  }

  Future<void> deleteActivityCategory(String id) async {
    await _repository.deleteActivityCategory(id);

    // Refresh activity categories and daily event counts (events may have changed)
    final categories = await _loadSexualActivityCategories();
    final counts = await _repository.getDailyEventCount();
    _state = _state.copyWith(
      sexualActivityCategories: categories,
      dailyEventCount: counts,
    );

    // Reload current events to reflect changes
    await _loadEventsForDate(_state.selectedDate);

    notifyListeners();
  }

  Future<bool> isActivityCategoryUsed(String activityCategoryId) async {
    return await _repository.isActivityCategoryUsed(activityCategoryId);
  }

  Future<void> saveSexualActivity(SexualActivity activity) async {
    await _repository.saveSexualActivity(activity);

    // Refresh sexual activities in state
    final activities = await _loadSexualActivities();
    _state = _state.copyWith(sexualActivities: activities);

    notifyListeners();
  }

  Future<void> deleteSexualActivity(String id) async {
    await _repository.deleteSexualActivity(id);

    // Refresh both sexual activities and activity categories (categories may have changed)
    final activities = await _loadSexualActivities();
    final categories = await _loadSexualActivityCategories();
    _state = _state.copyWith(
      sexualActivities: activities,
      sexualActivityCategories: categories,
    );

    notifyListeners();
  }

  Future<bool> isSexualActivityUsed(String activityId) async {
    return await _repository.isSexualActivityUsed(activityId);
  }

  /* ########################
         Private Methods
    ####################### */

  Future<void> _loadEventsForDate(DateTime? date) async {
    if (date == null) {
      return;
    }

    _state = _state.copyWith(currentEvents: await _repository.getByDate(date));
    notifyListeners();
  }

  Future<Map<String, SexualActivity>> _loadSexualActivities() async {
    final activities = await _repository.getAllSexualActivities();
    Map<String, SexualActivity> activityMap = {};
    for (var activity in activities) {
      activityMap[activity.id] = activity;
    }
    return activityMap;
  }

  Future<Map<String, SexualActivityCategory>>
  _loadSexualActivityCategories() async {
    final categories = await _repository.getAllSexualActivityCategories();
    Map<String, SexualActivityCategory> categoryMap = {};
    for (var category in categories) {
      categoryMap[category.id] = category;
    }
    return categoryMap;
  }
}
