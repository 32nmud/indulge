// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinical_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClinicalEvent _$ClinicalEventFromJson(Map<String, dynamic> json) =>
    _ClinicalEvent(
      id: json['id'] as String? ?? "",
      date: DateTime.parse(json['date'] as String),
      lastModifiedDate: json['lastModifiedDate'] == null
          ? null
          : DateTime.parse(json['lastModifiedDate'] as String),
      tests: (json['tests'] as List<dynamic>)
          .map((e) => ClinicalTestResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      facility: json['facility'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ClinicalEventToJson(_ClinicalEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'lastModifiedDate': instance.lastModifiedDate?.toIso8601String(),
      'tests': instance.tests,
      'facility': instance.facility,
      'notes': instance.notes,
    };
