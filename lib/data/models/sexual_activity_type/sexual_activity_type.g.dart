// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sexual_activity_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SexualActivityType _$SexualActivityTypeFromJson(Map<String, dynamic> json) =>
    _SexualActivityType(
      id: json['id'] as String? ?? "",
      lastUpdateDate: json['lastUpdateDate'] == null
          ? null
          : DateTime.parse(json['lastUpdateDate'] as String),
      name: json['name'] as String,
      displayCharacter: json['displayCharacter'] as String?,
      isRisky: json['isRisky'] as bool? ?? false,
      minParticipants: (json['minParticipants'] as num?)?.toInt() ?? -1,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? -1,
      properties:
          (json['properties'] as List<dynamic>?)
              ?.map(
                (e) => SexualActivityTypeProperty.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SexualActivityTypeToJson(_SexualActivityType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lastUpdateDate': instance.lastUpdateDate?.toIso8601String(),
      'name': instance.name,
      'displayCharacter': instance.displayCharacter,
      'isRisky': instance.isRisky,
      'minParticipants': instance.minParticipants,
      'maxParticipants': instance.maxParticipants,
      'properties': instance.properties,
    };
