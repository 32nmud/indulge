import 'package:indulge/data/models.dart';

class EventState {
  final SexualEvent? selectedEvent;
  final List<ActivityParticipant>? selectedEventSexualActivityParticipants;
  final List<Person>? selectedEventParticipants;
  final Map<String, List<Person>>? selectedEventActivityParticipants;
  final Map<String, SexualActivityCategory>? sexualActivityCategories;
  final Map<String, SexualActivity>? sexualActivities;
  final Location? selectedEventLocation;
  final List<SexualEvent>? currentEvents;
  final DateTime? selectedDate;
  final Map<DateTime, int>? dailyEventCount;
  final Person? myself;

  EventState({
    this.selectedEvent,
    this.selectedEventSexualActivityParticipants,
    this.selectedEventParticipants,
    this.selectedEventActivityParticipants,
    this.sexualActivityCategories,
    this.sexualActivities,
    this.selectedEventLocation,
    this.currentEvents,
    this.selectedDate,
    this.dailyEventCount,
    this.myself,
  });

  EventState copyWith({
    SexualEvent? selectedEvent,
    List<ActivityParticipant>? selectedEventSexualActivityParticipants,
    List<Person>? selectedEventParticipants,
    Map<String, List<Person>>? selectedEventActivityParticipants,
    Map<String, SexualActivityCategory>? sexualActivityCategories,
    Map<String, SexualActivity>? sexualActivities,
    Location? selectedEventLocation,
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
      sexualActivityCategories:
          sexualActivityCategories ?? this.sexualActivityCategories,
      sexualActivities: sexualActivities ?? this.sexualActivities,
      selectedEventLocation:
          selectedEventLocation ?? this.selectedEventLocation,
      currentEvents: currentEvents ?? this.currentEvents,
      selectedDate: selectedDate ?? this.selectedDate,
      dailyEventCount: dailyEventCount ?? this.dailyEventCount,
      myself: myself ?? this.myself,
    );
  }
}
