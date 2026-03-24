import 'package:freezed_annotation/freezed_annotation.dart';
import '../reference/reference.dart';

part 'activity_count.freezed.dart';
part 'activity_count.g.dart';

/// Represents the role a participant played in an activity
@JsonEnum(alwaysCreate: true)
enum ActivityRole {
  /// User gave the activity to their partner(s)
  @JsonValue('give')
  give,

  /// User received the activity from their partner(s)
  @JsonValue('receive')
  receive,

  /// User both gave and received the activity
  @JsonValue('both')
  both,

  /// User participated but role is not specified
  @JsonValue('participated')
  participated,
}

/// V2: Renamed from PropertyCount to ActivityCount for clarity
/// Represents a count of a specific activity performed by a participant
@Freezed(toJson: true, fromJson: true)
abstract class ActivityCount with _$ActivityCount {
  const ActivityCount._();

  const factory ActivityCount({
    @Default(Reference()) Reference categoryReference,
    @Default("") String activityName,
    @Default(1) int count,
    @Default(ActivityRole.participated) ActivityRole role,
    @Default(false) bool solo,
  }) = _ActivityCount;

  factory ActivityCount.fromJson(Map<String, dynamic> json) =>
      _$ActivityCountFromJson(json);

  String get resourceType => 'ActivityCount';
}
