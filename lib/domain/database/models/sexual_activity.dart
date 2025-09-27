import 'package:meta/meta.dart';

@immutable
class SexualActivity {
  final int? id;
  final int eventId;
  final int activityId;

  const SexualActivity({
    this.id,
    required this.eventId,
    required this.activityId,
  });

  factory SexualActivity.fromMap(Map<String, dynamic> map) {
    return SexualActivity(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      activityId: map['activity_id'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'activity_id': activityId,
    };
  }

  SexualActivity copyWith({
    int? id,
    int? eventId,
    int? activityId,
  }) {
    return SexualActivity(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      activityId: activityId ?? this.activityId,
    );
  }

  @override
  String toString() {
    return 'SexualActivity(id: $id, eventId: $eventId, activityId: $activityId)';
  }
}
