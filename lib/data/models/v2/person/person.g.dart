// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Person _$PersonFromJson(Map<String, dynamic> json) => _Person(
  id: json['id'] as String? ?? "",
  date: DateTime.parse(json['date'] as String),
  lastUpdateDate: json['lastUpdateDate'] == null
      ? null
      : DateTime.parse(json['lastUpdateDate'] as String),
  name: Name.fromJson(json['name'] as Map<String, dynamic>),
  location: json['location'] == null
      ? null
      : Reference.fromJson(json['location'] as Map<String, dynamic>),
  birthday: json['birthday'] == null
      ? null
      : DateTime.parse(json['birthday'] as String),
  isSelf: json['isSelf'] as bool? ?? false,
  bodyType: json['bodyType'] as String?,
  endowment: json['endowment'] as String?,
  cutStatus: json['cutStatus'] as String?,
  breastSize: json['breastSize'] as String?,
  assignedSexAtBirth: json['assignedSexAtBirth'] as String?,
  height: json['height'] as String?,
  gender: json['gender'] as String?,
  hivStatus: json['hivStatus'] as String?,
  herpesStatus: json['herpesStatus'] as String?,
  pronouns: json['pronouns'] as String?,
  socialLinks:
      (json['socialLinks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  notes: json['notes'] as String?,
  imageBytes: json['imageBytes'] as String?,
);

Map<String, dynamic> _$PersonToJson(_Person instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date.toIso8601String(),
  'lastUpdateDate': instance.lastUpdateDate?.toIso8601String(),
  'name': instance.name,
  'location': instance.location,
  'birthday': instance.birthday?.toIso8601String(),
  'isSelf': instance.isSelf,
  'bodyType': instance.bodyType,
  'endowment': instance.endowment,
  'cutStatus': instance.cutStatus,
  'breastSize': instance.breastSize,
  'assignedSexAtBirth': instance.assignedSexAtBirth,
  'height': instance.height,
  'gender': instance.gender,
  'hivStatus': instance.hivStatus,
  'herpesStatus': instance.herpesStatus,
  'pronouns': instance.pronouns,
  'socialLinks': instance.socialLinks,
  'notes': instance.notes,
  'imageBytes': instance.imageBytes,
};
