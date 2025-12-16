import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'sexual_activity_type_property.freezed.dart';
part 'sexual_activity_type_property.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class SexualActivityTypeProperty with _$SexualActivityTypeProperty {
  const SexualActivityTypeProperty._();

  const factory SexualActivityTypeProperty({
    @Default("") String id,
    @Default("unknown") String name,
    @Default("❔") String displayCharacter,
    @Default(true) bool canHaveMultipleParticipants,
    @Default(false) bool isRisky,
  }) = _SexualActivityTypeProperty;

  factory SexualActivityTypeProperty.fromJson(Map<String, dynamic> json) {
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$SexualActivityTypePropertyFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    final map = _$SexualActivityTypePropertyToJson(
      this as _SexualActivityTypeProperty,
    );
    map['resourceType'] = "SexualActivityTypeProperty";
    return map;
  }

  // Fixed getters
  @override
  @JsonKey(name: 'resourceType')
  String get resourceType => "SexualActivityTypeProperty";

  @override
  String get id => (this as _SexualActivityTypeProperty).id == ""
      ? const Uuid().v4()
      : (this as _SexualActivityTypeProperty).id;
}
