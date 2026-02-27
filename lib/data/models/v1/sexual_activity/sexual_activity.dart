import 'package:freezed_annotation/freezed_annotation.dart';

part 'sexual_activity.freezed.dart';
part 'sexual_activity.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class SexualActivity with _$SexualActivity {
  const SexualActivity._();

  const factory SexualActivity({
    @Default("") String id,
    @Default("unknown") String name,
    @Default("❔") String displayCharacter,
    @Default(true) bool canHaveMultipleParticipants,
    @Default(false) bool stiRisk,
    @Default(false) bool healthRisk,
    @Default(false) bool requiresPartner,
    @Default(true) bool isActionable,
    @Default(0) int sortOrder,
  }) = _SexualActivity;

  factory SexualActivity.fromJson(Map<String, dynamic> json) {
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$SexualActivityFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    final map = _$SexualActivityToJson(this as _SexualActivity);
    map['resourceType'] = "SexualActivity";
    return map;
  }

  // Fixed getters
  @JsonKey(name: 'resourceType')
  String get resourceType => "SexualActivity";
}
