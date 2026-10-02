// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sexual_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SexualActivity _$SexualActivityFromJson(Map<String, dynamic> json) =>
    _SexualActivity(
      name: json['name'] as String? ?? "unknown",
      displayCharacter: json['displayCharacter'] as String? ?? "❔",
      canHaveMultipleParticipants:
          json['canHaveMultipleParticipants'] as bool? ?? true,
      stiRisk: json['stiRisk'] as bool? ?? false,
      healthRisk: json['healthRisk'] as bool? ?? false,
      requiresPartner: json['requiresPartner'] as bool? ?? false,
      isActionable: json['isActionable'] as bool? ?? true,
      hasRoles: json['hasRoles'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SexualActivityToJson(_SexualActivity instance) =>
    <String, dynamic>{
      'name': instance.name,
      'displayCharacter': instance.displayCharacter,
      'canHaveMultipleParticipants': instance.canHaveMultipleParticipants,
      'stiRisk': instance.stiRisk,
      'healthRisk': instance.healthRisk,
      'requiresPartner': instance.requiresPartner,
      'isActionable': instance.isActionable,
      'hasRoles': instance.hasRoles,
      'sortOrder': instance.sortOrder,
    };
