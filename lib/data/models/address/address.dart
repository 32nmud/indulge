import 'package:freezed_annotation/freezed_annotation.dart';

part 'address.freezed.dart';
part 'address.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class Address with _$Address {
  const factory Address({
    @Default('') String city,
    @Default('') String state,
    String? line1,
    String? line2,
    int? zipCode,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}
