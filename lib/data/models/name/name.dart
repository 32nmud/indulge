import 'package:freezed_annotation/freezed_annotation.dart';

part 'name.freezed.dart';
part 'name.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class Name with _$Name {
  const factory Name({String? given, String? family, String? nickname}) = _Name;

  factory Name.fromJson(Map<String, dynamic> json) => _$NameFromJson(json);
}
