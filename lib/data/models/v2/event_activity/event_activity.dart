import 'package:freezed_annotation/freezed_annotation.dart';
import '../reference/reference.dart';
import '../activity_participant/activity_participant.dart';

part 'event_activity.freezed.dart';
part 'event_activity.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class EventActivity with _$EventActivity {
  const factory EventActivity({
    @Default(Reference()) Reference category,
    @Default([]) List<ActivityParticipant> participants,
  }) = _EventActivity;

  factory EventActivity.fromJson(Map<String, dynamic> json) =>
      _$EventActivityFromJson(json);
}
