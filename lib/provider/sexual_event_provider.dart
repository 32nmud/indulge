import 'package:flutter/cupertino.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/data/repositories/sexual_event_repository.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/event_state_store.dart';

class SexualEventsProvider extends ChangeNotifier {
  final EventStateStore _stateStore;

  late SexualEventRepository _repository;
  late final Future<String> _ready;

  SexualEventsProvider({
    required EventStateStore stateStore,
    SexualEventRepository? repository,
  }) : _stateStore = stateStore {
    _ready = _initProvider(repository: repository);
  }

  Future<String> _initProvider({SexualEventRepository? repository}) async {
    // If a repository instance was provided, use it; otherwise create one.
    if (repository == null) {
      _repository = await SexualEventRepository.create();
    } else {
      _repository = repository;
    }

    // Shared initialization logic (single place).
    final counts = await _repository.getDailyEventCount();
    final categories = await _loadSexualActivityCategories();
    final activities = await _loadSexualActivities();
    final myself = await _repository.getMyself();
    final persons = await _repository.getAllPersons();

    _setDailyEventCount(counts);
    _setSexualActivityCategories(categories);
    _setSexualActivities(activities);
    _setMyself(myself);
    _setAllPersons(persons);

    return "ready!";
  }

  /// Initialize provider using an already-constructed repository instance.
  Future<void> refreshAllData() async {
    final counts = await _repository.getDailyEventCount();
    final categories = await _loadSexualActivityCategories();
    final activities = await _loadSexualActivities();
    final myself = await _repository.getMyself();
    final persons = await _repository.getAllPersons();

    _setDailyEventCount(counts);
    _setSexualActivityCategories(categories);
    _setSexualActivities(activities);
    _setMyself(myself);
    _setAllPersons(persons);

    // Also reload events for the currently selected date
    await _loadEventsForDate(_stateStore.state.selectedDate);
  }

  Future<String> get ready => _ready;

  void selectDate(DateTime date) {
    // Update centralized selected date and load events for the day.
    _setSelectedDate(date);
    _loadEventsForDate(date);
  }

  Future<void> selectEvent(SexualEvent event) async {
    try {
      // 1. Fetch Related Data
      final participants = await _repository.getPersonsFromActivities(
        event.activities,
      );

      // 2. Construct State Fields
      final eventParticipants = participants;

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
      Location? resolvedLocation;
      try {
        resolvedLocation = event.location;
      } catch (e) {
        debugPrint("Error reading embedded event location: $e");
      }

      _setSelectedEvent(event);
      _setSelectedEventSexualActivityParticipants(sapList);
      _setSelectedEventParticipants(eventParticipants);
      _setSelectedEventActivityParticipants(activityParticipantsMap);
      _setSelectedEventLocation(resolvedLocation);
    } catch (e) {
      debugPrint("Error loading event details: $e");
    }

    await _loadEventsForDate(_stateStore.state.selectedDate);
  }

  Future<void> removeActivity(EventActivity activity) async {
    final selected = _stateStore.state.selectedEvent;
    if (selected == null) return;

    final currentActivities = selected.activities.toList();
    currentActivities.remove(activity);

    final updatedEvent = selected.copyWith(
      activities: currentActivities,
      lastModifiedDate: DateTime.now(),
    );

    await _repository.save(updatedEvent);
    await selectEvent(updatedEvent);
  }

  Future<void> removeParticipant(Person participant) async {
    final selected = _stateStore.state.selectedEvent;
    if (selected == null) return;

    final currentActivities = <EventActivity>[];

    for (final activity in selected.activities) {
      final updatedParticipants = activity.participants
          .where((ref) => ref.participant.reference != participant.id)
          .toList();

      currentActivities.add(
        activity.copyWith(participants: updatedParticipants),
      );
    }

    final updatedEvent = selected.copyWith(
      activities: currentActivities,
      lastModifiedDate: DateTime.now(),
    );

    await _repository.save(updatedEvent);
    await selectEvent(updatedEvent);
  }

  Future<void> removeActivityFromEdit(String activityCategoryId) async {
    final selected = _stateStore.state.selectedEvent;
    if (selected == null) return;

    await _repository.removeActivityByCategoryId(
      selected.id,
      activityCategoryId,
    );

    final updatedEvent = await _repository.getById(selected.id);
    if (updatedEvent != null) {
      await selectEvent(updatedEvent);
    } else {
      await _loadEventsForDate(_stateStore.state.selectedDate);
    }
  }

  Future<void> removeParticipantFromEdit(String personId) async {
    final selected = _stateStore.state.selectedEvent;
    if (selected == null) return;

    await _repository.removeParticipantById(selected.id, personId);

    final updatedEvent = await _repository.getById(selected.id);
    if (updatedEvent != null) {
      await selectEvent(updatedEvent);
    } else {
      await _loadEventsForDate(_stateStore.state.selectedDate);
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
            _stateStore.state.sexualActivities != null &&
            _stateStore.state.sexualActivities!.containsKey(
              activityCount.activityReference.reference,
            )) {
          activities.add(
            _stateStore.state.sexualActivities![activityCount
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

    // Refresh cached person list in store/local state so UI can react immediately.
    final persons = await _repository.getAllPersons();
    _setAllPersons(persons);
  }

  Future<void> deletePerson(String id) async {
    await _repository.deletePerson(id);

    // Refresh daily event count (events may have been modified)
    final counts = await _repository.getDailyEventCount();
    _setDailyEventCount(counts);

    // Reload current events to show updated participants
    await _loadEventsForDate(_stateStore.state.selectedDate);

    // Clear selected event if it had this person
    if (_stateStore.state.selectedEvent != null) {
      final updatedEvent = await _repository.getById(
        _stateStore.state.selectedEvent!.id,
      );
      if (updatedEvent != null) {
        await selectEvent(updatedEvent);
      } else {
        _setSelectedEvent(null);
        _setSelectedEventSexualActivityParticipants(null);
        _setSelectedEventParticipants(null);
        _setSelectedEventActivityParticipants(null);
      }
    }

    // Refresh cached person list in store/local state so UI can react immediately.
    final persons = await _repository.getAllPersons();
    _setAllPersons(persons);
  }

  Future<void> saveEvent(SexualEvent event) async {
    await _repository.save(event);

    // Refresh daily event count
    final counts = await _repository.getDailyEventCount();
    _setDailyEventCount(counts);

    // Reload events for the event's date
    await _loadEventsForDate(event.date);

    // Select the saved event
    _setSelectedEvent(event);
  }

  Future<void> deleteEvent(String eventId) async {
    await _repository.deleteById(eventId);

    // Clear selected event and all related state if it was the one deleted
    if (_stateStore.state.selectedEvent?.id == eventId) {
      _setSelectedEvent(null);
      _setSelectedEventSexualActivityParticipants(null);
      _setSelectedEventParticipants(null);
      _setSelectedEventActivityParticipants(null);
    }

    // Refresh daily event count
    final counts = await _repository.getDailyEventCount();
    _setDailyEventCount(counts);

    // Reload events for current date
    await _loadEventsForDate(_stateStore.state.selectedDate);
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
    _setSexualActivityCategories(categories);
  }

  Future<void> deleteActivityCategory(String id) async {
    await _repository.deleteActivityCategory(id);

    // Refresh activity categories and daily event counts (events may have changed)
    final categories = await _loadSexualActivityCategories();
    final counts = await _repository.getDailyEventCount();
    _setSexualActivityCategories(categories);
    _setDailyEventCount(counts);

    // Reload current events to reflect changes
    await _loadEventsForDate(_stateStore.state.selectedDate);
  }

  Future<bool> isActivityCategoryUsed(String activityCategoryId) async {
    return await _repository.isActivityCategoryUsed(activityCategoryId);
  }

  Future<int> getUsageCountForCategory(String id) async {
    return await _repository.getEventCountForActivityCategory(id);
  }

  Future<void> saveSexualActivity(SexualActivity activity) async {
    await _repository.saveSexualActivity(activity);

    // Refresh sexual activities in state
    final activities = await _loadSexualActivities();
    _setSexualActivities(activities);
  }

  Future<void> deleteSexualActivity(String id) async {
    await _repository.deleteSexualActivity(id);

    // Refresh both sexual activities and activity categories (categories may have changed)
    final activities = await _loadSexualActivities();
    final categories = await _loadSexualActivityCategories();
    _setSexualActivities(activities);
    _setSexualActivityCategories(categories);
  }

  Future<bool> isSexualActivityUsed(String activityId) async {
    return await _repository.isSexualActivityUsed(activityId);
  }

  Future<int> getUsageCountForActivity(String id) async {
    return await _repository.getEventCountForSexualActivity(id);
  }

  /* ########################
         Private Methods
     ####################### */

  Future<void> _loadEventsForDate(DateTime? date) async {
    if (date == null) {
      return;
    }

    final events = await _repository.getByDate(date);
    // Write day events directly into the store/local state.
    _setCurrentEvents(events);
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

  /// Create a Location object from coordinates.
  /// Note: Locations are embedded in events; this does NOT persist anything
  /// on its own. To persist, attach the Location to an event and save the event.
  Future<Location> createLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    // Construct a Location with the required latitude/longitude.
    // `address` is optional on Location now, so we omit it when not needed.
    final loc = Location(latitude: latitude, longitude: longitude);
    return loc;
  }

  /// Attach an embedded Location to the currently selected event and save.
  Future<void> attachLocationToSelectedEvent(Location location) async {
    final selected = _stateStore.state.selectedEvent;
    if (selected == null) return;

    // Embed the Location object directly on the event (no reference).
    final updatedEvent = selected.copyWith(
      location: location,
      lastModifiedDate: DateTime.now(),
    );

    await _repository.save(updatedEvent);
    await selectEvent(updatedEvent);
  }

  /// Remove any attached Location reference from the currently selected event.
  Future<void> removeLocationFromSelectedEvent() async {
    final selected = _stateStore.state.selectedEvent;
    if (selected == null) return;

    final updatedEvent = selected.copyWith(
      location: null,
      lastModifiedDate: DateTime.now(),
    );

    // Clear any resolved location before we re-select the event to avoid a
    // transient state where UI may still show the old location.
    _setSelectedEventLocation(null);

    await _repository.save(updatedEvent);

    // Re-select the updated event so UI gets the latest event (which has no location).
    await selectEvent(updatedEvent);

    // Defensively clear the resolved location again after re-selection so that
    // any async resolution path cannot re-populate it unexpectedly.
    _setSelectedEventLocation(null);
  }

  /* -------------------------
     Store write helpers (store required)
  ------------------------- */

  void _setDailyEventCount(Map<DateTime, int>? counts) {
    _stateStore.setDailyEventCount(counts);
  }

  void _setSexualActivityCategories(
    Map<String, SexualActivityCategory>? categories,
  ) {
    _stateStore.setSexualActivityCategories(categories);
  }

  void _setSexualActivities(Map<String, SexualActivity>? activities) {
    _stateStore.setSexualActivities(activities);
  }

  void _setMyself(Person? me) {
    _stateStore.setMyself(me);
  }

  void _setCurrentEvents(List<SexualEvent>? events) {
    _stateStore.setCurrentEvents(events);
  }

  void _setSelectedDate(DateTime? date) {
    _stateStore.setSelectedDate(date);
  }

  void _setSelectedEvent(SexualEvent? event) {
    _stateStore.setSelectedEvent(event);
  }

  void _setSelectedEventLocation(Location? loc) {
    _stateStore.setSelectedEventLocation(loc);
  }

  void _setSelectedEventSexualActivityParticipants(
    List<ActivityParticipant>? sap,
  ) {
    _stateStore.setSelectedEventSexualActivityParticipants(sap);
  }

  void _setSelectedEventActivityParticipants(Map<String, List<Person>>? map) {
    _stateStore.setSelectedEventActivityParticipants(map);
  }

  void _setSelectedEventParticipants(List<Person>? participants) {
    _stateStore.setSelectedEventParticipants(participants);
  }

  void _setAllPersons(List<Person>? persons) {
    _stateStore.setAllPersons(persons);
  }
}
