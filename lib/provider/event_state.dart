import 'package:indulge/data/models/sexual_event.dart';

class EventState {
  final SexualEvent? selectedEvent;
  final List<SexualEvent>? currentEvents;
  final DateTime? selectedDate;
  final Map<DateTime, int>? dailyEventCount;

  EventState(
      {this.selectedEvent,
      this.currentEvents,
      this.selectedDate,
      this.dailyEventCount});

  EventState copyWith({
    SexualEvent? selectedEvent,
    List<SexualEvent>? currentEvents,
    DateTime? selectedDate,
    Map<DateTime, int>? dailyEventCount,
  }) {
    return EventState(
      selectedEvent: selectedEvent ?? this.selectedEvent,
      currentEvents: currentEvents ?? this.currentEvents,
      selectedDate: selectedDate ?? this.selectedDate,
      dailyEventCount: dailyEventCount ?? this.dailyEventCount,
    );
  }
}
