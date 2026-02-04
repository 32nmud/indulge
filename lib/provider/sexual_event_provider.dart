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
    _state = _state.copyWith(
      dailyEventCount: counts,
      sexualActivityTypes: types,
      sexualActivityTypeProperties: properties,
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

  void removeActivityFromEdit(int id) {
    // TODO: Update logic for new SexualEvent model which relies on ID string, not int or baseEventId
    // _removeActivityFromEdit(id);
    _loadEventsForDate(_state.selectedDate);
    notifyListeners();
  }

  void removeParticipantFromEdit(int id) {
    // TODO: Update logic for new SexualEvent model which relies on ID string, not int or baseEventId
    // _removeParticipantFromEdit(id);
    _loadEventsForDate(_state.selectedDate);
    notifyListeners();
  }

  List<SexualActivityTypeProperty>
  getSexualActivityTypePropertiesForPersonAndActivity(
    Person person,
    SexualActivity activity,
  ) {
    List<SexualActivityTypeProperty> properties = [];
    for (SexualActivityParticipant property in activity.participants) {
      for (Reference reference in property.propertyReferences) {
        if (reference.resourceType == "SexualActivityTypeProperty" &&
            property.participant.resourceType == "Person" &&
            property.participant.reference == person.id &&
            _state.sexualActivityTypeProperties != null &&
            _state.sexualActivityTypeProperties!.containsKey(
              reference.reference,
            )) {
          properties.add(
            _state.sexualActivityTypeProperties![reference.reference]!,
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

  /*
  // TODO: Commented out until repository supports removal and model issues are resolved
  Future<void> _removeActivityFromEdit(int id) async {
    if (_state.selectedEvent == null) return;

    _repository.removeActivity(id);
    _state = _state.copyWith(
      selectedEvent: await _repository.getById(
        _state.selectedEvent!.baseEventId,
      ),
    );
    notifyListeners();
  }

  Future<void> _removeParticipantFromEdit(int id) async {
    if (_state.selectedEvent == null) return;

    _repository.removeParticipant(_state.selectedEvent!.baseEventId, id);
    _state = _state.copyWith(
      selectedEvent: await _repository.getById(
        _state.selectedEvent!.baseEventId,
      ),
    );
    notifyListeners();
  }
  */

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
