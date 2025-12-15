import 'package:indulge/data/models.dart';

class EventState {
  final SexualEvent? selectedEvent;
  final List<SexualActivityParticipant>?
  selectedEventSexualActivityParticipants;
  final List<Person>? selectedEventParticipants;
  final Map<String, List<Person>>? selectedEventActivityParticipants;
  final Map<String, SexualActivityType>? selectedEventActivityTypes;
  final List<SexualActivityTypeProperty>?
  selectedEventSexualActivityTypeProperties;

  final List<SexualEvent>? currentEvents;
  final DateTime? selectedDate;
  final Map<DateTime, int>? dailyEventCount;

  EventState({
    this.selectedEvent,
    this.selectedEventSexualActivityParticipants,
    this.selectedEventParticipants,
    this.selectedEventActivityParticipants,
    this.selectedEventActivityTypes,
    this.selectedEventSexualActivityTypeProperties,
    this.currentEvents,
    this.selectedDate,
    this.dailyEventCount,
  });

  EventState copyWith({
    SexualEvent? selectedEvent,
    List<SexualActivityParticipant>? selectedEventSexualActivityParticipants,
    List<Person>? selectedEventParticipants,
    Map<String, List<Person>>? selectedEventActivityParticipants,
    Map<String, SexualActivityType>? selectedEventActivityTypes,
    List<SexualActivityTypeProperty>? selectedEventSexualActivityTypeProperties,
    List<SexualEvent>? currentEvents,
    DateTime? selectedDate,
    Map<DateTime, int>? dailyEventCount,
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
      selectedEventActivityTypes:
          selectedEventActivityTypes ?? this.selectedEventActivityTypes,
      selectedEventSexualActivityTypeProperties:
          selectedEventSexualActivityTypeProperties ??
          this.selectedEventSexualActivityTypeProperties,
      currentEvents: currentEvents ?? this.currentEvents,
      selectedDate: selectedDate ?? this.selectedDate,
      dailyEventCount: dailyEventCount ?? this.dailyEventCount,
    );
  }
}
