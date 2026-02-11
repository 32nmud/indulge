// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sexual_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SexualActivity _$SexualActivityFromJson(Map<String, dynamic> json) =>
    _SexualActivity(
      type: json['type'] == null
          ? const Reference()
          : Reference.fromJson(json['type'] as Map<String, dynamic>),
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map(
                (e) => SexualActivityParticipant.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SexualActivityToJson(_SexualActivity instance) =>
    <String, dynamic>{
      'type': instance.type,
      'participants': instance.participants,
    };
