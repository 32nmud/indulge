import 'package:freezed_annotation/freezed_annotation.dart';
import '../reference/reference.dart';
import '../sexual_activity_participant/sexual_activity_participant.dart';

part 'sexual_activity.freezed.dart';
part 'sexual_activity.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class SexualActivity with _$SexualActivity {
  const factory SexualActivity({
    @Default(Reference()) Reference type,
    @Default([]) List<SexualActivityParticipant> participants,
  }) = _SexualActivity;

  factory SexualActivity.fromJson(Map<String, dynamic> json) =>
      _$SexualActivityFromJson(json);
}
