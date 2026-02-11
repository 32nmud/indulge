// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sexual_activity_type_property.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SexualActivityTypeProperty _$SexualActivityTypePropertyFromJson(
  Map<String, dynamic> json,
) => _SexualActivityTypeProperty(
  id: json['id'] as String? ?? "",
  name: json['name'] as String? ?? "unknown",
  displayCharacter: json['displayCharacter'] as String? ?? "❔",
  canHaveMultipleParticipants:
      json['canHaveMultipleParticipants'] as bool? ?? true,
  isRisky: json['isRisky'] as bool? ?? false,
  requiresPartner: json['requiresPartner'] as bool? ?? false,
);

Map<String, dynamic> _$SexualActivityTypePropertyToJson(
  _SexualActivityTypeProperty instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'displayCharacter': instance.displayCharacter,
  'canHaveMultipleParticipants': instance.canHaveMultipleParticipants,
  'isRisky': instance.isRisky,
  'requiresPartner': instance.requiresPartner,
};
