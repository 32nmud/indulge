// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sexual_activity_type_property.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SexualActivityTypeProperty _$SexualActivityTypePropertyFromJson(
  Map<String, dynamic> json,
) => _SexualActivityTypeProperty(
  name: json['name'] as String? ?? "",
  displayCharacter: json['displayCharacter'] as String? ?? "❔",
  canHaveMultipleParticipants:
      json['canHaveMultipleParticipants'] as bool? ?? true,
);

Map<String, dynamic> _$SexualActivityTypePropertyToJson(
  _SexualActivityTypeProperty instance,
) => <String, dynamic>{
  'name': instance.name,
  'displayCharacter': instance.displayCharacter,
  'canHaveMultipleParticipants': instance.canHaveMultipleParticipants,
};
