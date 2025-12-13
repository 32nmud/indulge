import 'package:freezed_annotation/freezed_annotation.dart';
import '../reference/reference.dart';

part 'sexual_activity_participant.freezed.dart';
part 'sexual_activity_participant.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class SexualActivityParticipant with _$SexualActivityParticipant {
  const factory SexualActivityParticipant({
    @Default(Reference()) Reference participant,
    @Default(Reference()) Reference activity,
    @Default(0) int timesParticipated,
    String? subtypeParticipated,
  }) = _SexualActivityParticipant;

  factory SexualActivityParticipant.fromJson(Map<String, dynamic> json) =>
      _$SexualActivityParticipantFromJson(json);
}
