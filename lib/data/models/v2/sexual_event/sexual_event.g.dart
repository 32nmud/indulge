// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sexual_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SexualEvent _$SexualEventFromJson(Map<String, dynamic> json) => _SexualEvent(
  id: json['id'] as String? ?? "",
  date: DateTime.parse(json['date'] as String),
  lastModifiedDate: json['lastModifiedDate'] == null
      ? null
      : DateTime.parse(json['lastModifiedDate'] as String),
  activities: (json['activities'] as List<dynamic>)
      .map((e) => EventActivity.fromJson(e as Map<String, dynamic>))
      .toList(),
  location: json['location'] == null
      ? null
      : Reference.fromJson(json['location'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$SexualEventToJson(_SexualEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'lastModifiedDate': instance.lastModifiedDate?.toIso8601String(),
      'activities': instance.activities,
      'location': instance.location,
      'notes': instance.notes,
    };
