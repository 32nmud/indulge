import 'package:freezed_annotation/freezed_annotation.dart';
import '../reference/reference.dart';

part 'sexual_activity_participant.freezed.dart';
part 'sexual_activity_participant.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class SexualActivityParticipant with _$SexualActivityParticipant {
  const SexualActivityParticipant._();

  const factory SexualActivityParticipant({
    @Default(Reference()) Reference participant,
    @Default([])
    List<Reference>
    propertyReferences, // References to SexualActivityTypeProperty
  }) = _SexualActivityParticipant;

  factory SexualActivityParticipant.fromJson(Map<String, dynamic> json) {
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$SexualActivityParticipantFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    final map = _$SexualActivityParticipantToJson(
      this as _SexualActivityParticipant,
    );
    map['resourceType'] = "SexualActivityParticipant";
    return map;
  }

  // Fixed getters
  @override
  @JsonKey(name: 'resourceType')
  String get resourceType => "SexualActivityParticipant";
}
