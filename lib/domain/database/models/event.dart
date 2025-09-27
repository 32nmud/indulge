import 'package:meta/meta.dart';
import 'enums.dart';

@immutable
class Event {
  final int? id;
  final DateTime date;
  final DateTime createdAt;
  final DateTime lastModified;
  final EventType eventType;
  final int? locationId;
  final String? notes;

  const Event({
    this.id,
    required this.date,
    required this.createdAt,
    required this.lastModified,
    required this.eventType,
    this.locationId,
    this.notes,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      lastModified: DateTime.parse(map['last_modified'] as String),
      eventType: EventType.values.firstWhere(
        (e) => e.name == map['event_type'] as String,
      ),
      locationId: map['location_id'] as int?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'event_type': eventType.name,
      'location_id': locationId,
      'notes': notes,
    };
  }

  Event copyWith({
    int? id,
    DateTime? date,
    DateTime? createdAt,
    DateTime? lastModified,
    EventType? eventType,
    int? locationId,
    String? notes,
  }) {
    return Event(
      id: id ?? this.id,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      eventType: eventType ?? this.eventType,
      locationId: locationId ?? this.locationId,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, date: $date, createdAt: $createdAt, lastModified: $lastModified, eventType: $eventType, locationId: $locationId, notes: $notes)';
  }
}
