// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityParticipant _$ActivityParticipantFromJson(Map<String, dynamic> json) =>
    _ActivityParticipant(
      participant: json['participant'] == null
          ? const Reference()
          : Reference.fromJson(json['participant'] as Map<String, dynamic>),
      activityCounts:
          (json['activityCounts'] as List<dynamic>?)
              ?.map((e) => ActivityCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ActivityParticipantToJson(
  _ActivityParticipant instance,
) => <String, dynamic>{
  'participant': instance.participant,
  'activityCounts': instance.activityCounts,
};
