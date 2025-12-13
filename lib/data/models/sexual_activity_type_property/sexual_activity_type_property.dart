import 'package:freezed_annotation/freezed_annotation.dart';

part 'sexual_activity_type_property.freezed.dart';
part 'sexual_activity_type_property.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class SexualActivityTypeProperty with _$SexualActivityTypeProperty {
  const factory SexualActivityTypeProperty({
    @Default("") String name,
    @Default("❔") String displayCharacter,
    @Default(true) bool canHaveMultipleParticipants,
  }) = _SexualActivityTypeProperty;

  factory SexualActivityTypeProperty.fromJson(Map<String, dynamic> json) =>
      _$SexualActivityTypePropertyFromJson(json);
}
