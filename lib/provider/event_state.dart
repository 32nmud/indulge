import 'package:indulge/data/models.dart';

class EventState {
  final SexualEvent? selectedEvent;
  final List<SexualActivityParticipant>?
  selectedEventSexualActivityParticipants;
  final List<Person>? selectedEventParticipants;
  final Map<String, List<Person>>? selectedEventActivityParticipants;
  final Map<String, SexualActivityType>? sexualActivityTypes;
  final Map<String, SexualActivityTypeProperty>? sexualActivityTypeProperties;
  final List<SexualEvent>? currentEvents;
  final DateTime? selectedDate;
  final Map<DateTime, int>? dailyEventCount;
  final Person? myself;

  EventState({
    this.selectedEvent,
    this.selectedEventSexualActivityParticipants,
    this.selectedEventParticipants,
    this.selectedEventActivityParticipants,
    this.sexualActivityTypes,
    this.sexualActivityTypeProperties,
    this.currentEvents,
    this.selectedDate,
    this.dailyEventCount,
    this.myself,
  });

  EventState copyWith({
    SexualEvent? selectedEvent,
    List<SexualActivityParticipant>? selectedEventSexualActivityParticipants,
    List<Person>? selectedEventParticipants,
    Map<String, List<Person>>? selectedEventActivityParticipants,
    Map<String, SexualActivityType>? sexualActivityTypes,
    Map<String, SexualActivityTypeProperty>? sexualActivityTypeProperties,
    List<SexualEvent>? currentEvents,
    DateTime? selectedDate,
    Map<DateTime, int>? dailyEventCount,
    Person? myself,
  }) {
    return EventState(
      selectedEvent: selectedEvent ?? this.selectedEvent,
      selectedEventSexualActivityParticipants:
          selectedEventSexualActivityParticipants ??
          this.selectedEventSexualActivityParticipants,
      selectedEventParticipants:
          selectedEventParticipants ?? this.selectedEventParticipants,
      selectedEventActivityParticipants:
          selectedEventActivityParticipants ??
          this.selectedEventActivityParticipants,
      sexualActivityTypes: sexualActivityTypes ?? this.sexualActivityTypes,
      sexualActivityTypeProperties:
          sexualActivityTypeProperties ?? this.sexualActivityTypeProperties,
      currentEvents: currentEvents ?? this.currentEvents,
      selectedDate: selectedDate ?? this.selectedDate,
      dailyEventCount: dailyEventCount ?? this.dailyEventCount,
      myself: myself ?? this.myself,
    );
  }
}
