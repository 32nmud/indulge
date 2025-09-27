import 'package:meta/meta.dart';

@immutable
class EventLocation {
  final int? id;
  final int eventId;
  final int locationId;

  const EventLocation({
    this.id,
    required this.eventId,
    required this.locationId,
  });

  factory EventLocation.fromMap(Map<String, dynamic> map) {
    return EventLocation(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      locationId: map['location_id'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'location_id': locationId,
    };
  }

  EventLocation copyWith({
    int? id,
    int? eventId,
    int? locationId,
  }) {
    return EventLocation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      locationId: locationId ?? this.locationId,
    );
  }

  @override
  String toString() =>
      'EventLocation(id: $id, eventId: $eventId, locationId: $locationId)';
}
