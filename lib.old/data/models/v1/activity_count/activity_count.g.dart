// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_count.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityCount _$ActivityCountFromJson(Map<String, dynamic> json) =>
    _ActivityCount(
      categoryReference: json['categoryReference'] == null
          ? const Reference()
          : Reference.fromJson(
              json['categoryReference'] as Map<String, dynamic>,
            ),
      activityName: json['activityName'] as String? ?? "",
      count: (json['count'] as num?)?.toInt() ?? 1,
      role:
          $enumDecodeNullable(_$ActivityRoleEnumMap, json['role']) ??
          ActivityRole.participated,
      solo: json['solo'] as bool? ?? false,
    );

Map<String, dynamic> _$ActivityCountToJson(_ActivityCount instance) =>
    <String, dynamic>{
      'categoryReference': instance.categoryReference,
      'activityName': instance.activityName,
      'count': instance.count,
      'role': _$ActivityRoleEnumMap[instance.role]!,
      'solo': instance.solo,
    };

const _$ActivityRoleEnumMap = {
  ActivityRole.give: 'give',
  ActivityRole.receive: 'receive',
  ActivityRole.both: 'both',
  ActivityRole.participated: 'participated',
};
