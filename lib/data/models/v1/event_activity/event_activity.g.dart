// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventActivity _$EventActivityFromJson(Map<String, dynamic> json) =>
    _EventActivity(
      category: json['category'] == null
          ? const Reference()
          : Reference.fromJson(json['category'] as Map<String, dynamic>),
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map(
                (e) => ActivityParticipant.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$EventActivityToJson(_EventActivity instance) =>
    <String, dynamic>{
      'category': instance.category,
      'participants': instance.participants,
    };
