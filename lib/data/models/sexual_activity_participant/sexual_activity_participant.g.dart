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
  activity: json['activity'] == null
      ? const Reference()
      : Reference.fromJson(json['activity'] as Map<String, dynamic>),
  timesParticipated: (json['timesParticipated'] as num?)?.toInt() ?? 0,
  subtypeParticipated: json['subtypeParticipated'] as String?,
);

Map<String, dynamic> _$SexualActivityParticipantToJson(
  _SexualActivityParticipant instance,
) => <String, dynamic>{
  'participant': instance.participant,
  'activity': instance.activity,
  'timesParticipated': instance.timesParticipated,
  'subtypeParticipated': instance.subtypeParticipated,
};
