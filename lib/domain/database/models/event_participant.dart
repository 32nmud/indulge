import 'package:meta/meta.dart';

@immutable
class EventParticipant {
  final int? id;
  final int eventId;
  final int personId;

  const EventParticipant({
    this.id,
    required this.eventId,
    required this.personId,
  });

  factory EventParticipant.fromMap(Map<String, dynamic> map) {
    return EventParticipant(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      personId: map['person_id'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'person_id': personId,
    };
  }

  EventParticipant copyWith({
    int? id,
    int? eventId,
    int? personId,
  }) {
    return EventParticipant(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      personId: personId ?? this.personId,
    );
  }

  @override
  String toString() =>
      'EventParticipant(id: $id, eventId: $eventId, personId: $personId)';
}
