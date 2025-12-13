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
);

Map<String, dynamic> _$PersonToJson(_Person instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date.toIso8601String(),
  'lastUpdateDate': instance.lastUpdateDate?.toIso8601String(),
  'name': instance.name,
  'location': instance.location,
  'birthday': instance.birthday?.toIso8601String(),
};
