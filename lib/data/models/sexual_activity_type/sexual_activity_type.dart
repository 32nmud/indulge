import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import '../reference/reference.dart';

part 'sexual_activity_type.freezed.dart';
part 'sexual_activity_type.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class SexualActivityType with _$SexualActivityType {
  const SexualActivityType._();

  const factory SexualActivityType({
    @Default("") String id,
    DateTime? lastUpdateDate,
    required String name,
    String? displayCharacter,
    @Default(-1) int minParticipants,
    @Default(-1) int maxParticipants,
    @Default([]) List<Reference> properties,
  }) = _SexualActivityType;

  // -----------------------------------------------------------------
  // Custom JSON (de)serialization
  // -----------------------------------------------------------------
  factory SexualActivityType.fromJson(Map<String, dynamic> json) {
    // Remove any incoming `resourceType` – we ignore it completely.
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$SexualActivityTypeFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    // Let the generated helper create the map, then inject the constant.
    final map = _$SexualActivityTypeToJson(this as _SexualActivityType);
    map['resourceType'] = "SexualActivityType"; // guarantee the correct value
    return map;
  }

  // -----------------------------------------------------------------
  // Fixed getters
  // -----------------------------------------------------------------
  @override
  @JsonKey(name: 'resourceType')
  String get resourceType => "SexualActivityType";

  @override
  String get id => (this as _SexualActivityType).id == ""
      ? const Uuid().v4()
      : (this as _SexualActivityType).id;
}
