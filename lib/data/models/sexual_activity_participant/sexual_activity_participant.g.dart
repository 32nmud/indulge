// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sexual_activity_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SexualActivityParticipant _$SexualActivityParticipantFromJson(
  Map<String, dynamic> json,
) => _SexualActivityParticipant(
  participant: json['participant'] == null
      ? const Reference()
      : Reference.fromJson(json['participant'] as Map<String, dynamic>),
  propertyReferences:
      (json['propertyReferences'] as List<dynamic>?)
          ?.map((e) => Reference.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SexualActivityParticipantToJson(
  _SexualActivityParticipant instance,
) => <String, dynamic>{
  'participant': instance.participant,
  'propertyReferences': instance.propertyReferences,
};
