// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sexual_activity_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SexualActivityCategory _$SexualActivityCategoryFromJson(
  Map<String, dynamic> json,
) => _SexualActivityCategory(
  id: json['id'] as String? ?? "",
  lastUpdateDate: json['lastUpdateDate'] == null
      ? null
      : DateTime.parse(json['lastUpdateDate'] as String),
  name: json['name'] as String,
  displayCharacter: json['displayCharacter'] as String?,
  minParticipants: (json['minParticipants'] as num?)?.toInt() ?? -1,
  maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? -1,
  activities:
      (json['activities'] as List<dynamic>?)
          ?.map((e) => SexualActivity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  requiresPartner: json['requiresPartner'] as bool? ?? false,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  subCategories:
      (json['subCategories'] as List<dynamic>?)
          ?.map((e) => Reference.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SexualActivityCategoryToJson(
  _SexualActivityCategory instance,
) => <String, dynamic>{
  'id': instance.id,
  'lastUpdateDate': instance.lastUpdateDate?.toIso8601String(),
  'name': instance.name,
  'displayCharacter': instance.displayCharacter,
  'minParticipants': instance.minParticipants,
  'maxParticipants': instance.maxParticipants,
  'activities': instance.activities,
  'requiresPartner': instance.requiresPartner,
  'sortOrder': instance.sortOrder,
  'subCategories': instance.subCategories,
};
