// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Address _$AddressFromJson(Map<String, dynamic> json) => _Address(
  city: json['city'] as String? ?? '',
  state: json['state'] as String? ?? '',
  line1: json['line1'] as String?,
  line2: json['line2'] as String?,
  zipCode: json['zipCode'] as String?,
);

Map<String, dynamic> _$AddressToJson(_Address instance) => <String, dynamic>{
  'city': instance.city,
  'state': instance.state,
  'line1': instance.line1,
  'line2': instance.line2,
  'zipCode': instance.zipCode,
};
