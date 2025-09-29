import 'package:meta/meta.dart';
import 'location.dart';
import 'person.dart';
import 'sexual_activity.dart';

@immutable
class SexualEvent {
  final int? baseEventId; // Database ID (null if new)
  final DateTime date; // Date of the event
  final Location? location; // Where the event happened
  final List<Person> participants; // People involved
  final List<SexualActivity> activities; // Activities that took place

  const SexualEvent({
    this.baseEventId,
    required this.date,
    this.location,
    required this.participants,
    required this.activities,
  });

  SexualEvent copyWith({
    int? baseEventId,
    DateTime? date,
    Location? location,
    List<Person>? participants,
    List<SexualActivity>? activities,
  }) =>
      SexualEvent(
        baseEventId: baseEventId ?? this.baseEventId,
        date: date ?? this.date,
        location: location ?? this.location,
        participants: participants ?? this.participants,
        activities: activities ?? this.activities,
      );

  @override
  String toString() =>
      'SexualEvent(id: $baseEventId, date: $date, location: $location, participants: $participants, activities: $activities)';
}
