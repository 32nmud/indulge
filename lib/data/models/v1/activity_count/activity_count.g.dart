// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_count.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityCount _$ActivityCountFromJson(Map<String, dynamic> json) =>
    _ActivityCount(
      activityReference: json['activityReference'] == null
          ? const Reference()
          : Reference.fromJson(
              json['activityReference'] as Map<String, dynamic>,
            ),
      count: (json['count'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$ActivityCountToJson(_ActivityCount instance) =>
    <String, dynamic>{
      'activityReference': instance.activityReference,
      'count': instance.count,
    };
