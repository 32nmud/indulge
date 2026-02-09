// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_count.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PropertyCount _$PropertyCountFromJson(Map<String, dynamic> json) =>
    _PropertyCount(
      propertyReference: json['propertyReference'] == null
          ? const Reference()
          : Reference.fromJson(
              json['propertyReference'] as Map<String, dynamic>,
            ),
      count: (json['count'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$PropertyCountToJson(_PropertyCount instance) =>
    <String, dynamic>{
      'propertyReference': instance.propertyReference,
      'count': instance.count,
    };
