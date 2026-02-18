import 'package:freezed_annotation/freezed_annotation.dart';
import '../reference/reference.dart';
import '../activity_count/activity_count.dart';

part 'activity_participant.freezed.dart';
part 'activity_participant.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class ActivityParticipant with _$ActivityParticipant {
  const ActivityParticipant._();

  const factory ActivityParticipant({
    @Default(Reference()) Reference participant,
    @Default([])
    List<ActivityCount> activityCounts, // Activity references with counts
  }) = _ActivityParticipant;

  factory ActivityParticipant.fromJson(Map<String, dynamic> json) {
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$ActivityParticipantFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    final map = _$ActivityParticipantToJson(this as _ActivityParticipant);
    map['resourceType'] = "SexualActivityParticipant";
    return map;
  }

  // Fixed getters
  @JsonKey(name: 'resourceType')
  String get resourceType => "SexualActivityParticipant";
}
