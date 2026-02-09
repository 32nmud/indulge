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
    final types = await _loadSexualActivityTypes();
    final properties = await _loadSexualActivityTypeProperties();
    final myself = await _repository.getMyself();
    _state = _state.copyWith(
      dailyEventCount: counts,
      sexualActivityTypes: types,
      sexualActivityTypeProperties: properties,
      myself: myself,
    );
    return "ready!";
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
      // Key: Activity Type ID
      final activityParticipantsMap = <String, List<Person>>{};
      final personMap = {for (var p in participants) p.id: p};

      for (var activity in event.activities) {
        final typeId = activity.type.reference;
        final currentList = activityParticipantsMap[typeId] ?? [];

        for (var participant in activity.participants) {
          if (participant.participant.resourceType == 'Person' &&
              personMap.containsKey(participant.participant.reference)) {
            final person = personMap[participant.participant.reference]!;
            if (!currentList.any((p) => p.id == person.id)) {
              currentList.add(person);
            }
          }
        }
        activityParticipantsMap[typeId] = currentList;
      }

      // List<SexualActivityParticipant>
      // Aggregate participation counts
      final sapMap = <String, SexualActivityParticipant>{};

      for (var activity in event.activities) {
        final typeId = activity.type.reference;
        for (var participant in activity.participants) {
          if (participant.participant.resourceType != 'Person') continue;

          final key = '${participant.participant.reference}_$typeId';

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

  Future<void> removeActivity(SexualActivity activity) async {
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

    final currentActivities = <SexualActivity>[];

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

  Future<void> removeActivityFromEdit(String activityTypeId) async {
    if (_state.selectedEvent == null) return;

    await _repository.removeActivityByTypeId(
      _state.selectedEvent!.id,
      activityTypeId,
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

  List<SexualActivityTypeProperty>
  getSexualActivityTypePropertiesForPersonAndActivity(
    Person person,
    SexualActivity activity,
  ) {
    List<SexualActivityTypeProperty> properties = [];
    for (SexualActivityParticipant property in activity.participants) {
      for (var propertyCount in property.propertyCounts) {
        if (propertyCount.propertyReference.resourceType ==
                "SexualActivityTypeProperty" &&
            property.participant.resourceType == "Person" &&
            property.participant.reference == person.id &&
            _state.sexualActivityTypeProperties != null &&
            _state.sexualActivityTypeProperties!.containsKey(
              propertyCount.propertyReference.reference,
            )) {
          properties.add(
            _state.sexualActivityTypeProperties![propertyCount
                .propertyReference
                .reference]!,
          );
        }
      }
    }
    return properties;
  }

  Future<List<Person>> getPersonsForEvent(String eventId) async {
    SexualEvent? event = await _repository.getById(eventId);
    if (event == null) {
      return [];
    }

    return await _repository.getPersonsFromActivities(event.activities);
  }

  Future<List<Person>> getPersonsForActivity(SexualActivity activity) async {
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

  Future<void> saveActivityType(SexualActivityType activityType) async {
    await _repository.saveActivityType(activityType);

    // Refresh activity types in state
    final types = await _loadSexualActivityTypes();
    _state = _state.copyWith(sexualActivityTypes: types);

    notifyListeners();
  }

  Future<void> deleteActivityType(String id) async {
    await _repository.deleteActivityType(id);

    // Refresh activity types and daily event counts (events may have changed)
    final types = await _loadSexualActivityTypes();
    final counts = await _repository.getDailyEventCount();
    _state = _state.copyWith(
      sexualActivityTypes: types,
      dailyEventCount: counts,
    );

    // Reload current events to reflect changes
    await _loadEventsForDate(_state.selectedDate);

    notifyListeners();
  }

  Future<bool> isActivityTypeUsed(String activityTypeId) async {
    return await _repository.isActivityTypeUsed(activityTypeId);
  }

  Future<void> saveActivityProperty(SexualActivityTypeProperty property) async {
    await _repository.saveActivityProperty(property);

    // Refresh activity properties in state
    final properties = await _loadSexualActivityTypeProperties();
    _state = _state.copyWith(sexualActivityTypeProperties: properties);

    notifyListeners();
  }

  Future<void> deleteActivityProperty(String id) async {
    await _repository.deleteActivityProperty(id);

    // Refresh both properties and activity types (types may have changed)
    final properties = await _loadSexualActivityTypeProperties();
    final types = await _loadSexualActivityTypes();
    _state = _state.copyWith(
      sexualActivityTypeProperties: properties,
      sexualActivityTypes: types,
    );

    notifyListeners();
  }

  Future<bool> isActivityPropertyUsed(String propertyId) async {
    return await _repository.isActivityPropertyUsed(propertyId);
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

  Future<Map<String, SexualActivityTypeProperty>>
  _loadSexualActivityTypeProperties() async {
    final properties = await _repository.getAllSexualActivityTypeProperties();
    Map<String, SexualActivityTypeProperty> propertyMap = {};
    for (var property in properties) {
      propertyMap[property.id] = property;
    }
    return propertyMap;
  }

  Future<Map<String, SexualActivityType>> _loadSexualActivityTypes() async {
    final properties = await _repository.getAllSexualActivityTypes();
    Map<String, SexualActivityType> typeMap = {};
    for (var type in properties) {
      typeMap[type.id] = type;
    }
    return typeMap;
  }
}
