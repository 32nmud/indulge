import 'package:freezed_annotation/freezed_annotation.dart';
import '../reference/reference.dart';

part 'activity_count.freezed.dart';
part 'activity_count.g.dart';

/// V2: Renamed from PropertyCount to ActivityCount for clarity
/// Represents a count of a specific activity performed by a participant
@Freezed(toJson: true, fromJson: true)
abstract class ActivityCount with _$ActivityCount {
  const ActivityCount._();

  const factory ActivityCount({
    @Default(Reference()) Reference activityReference,
    @Default(1) int count,
  }) = _ActivityCount;

  factory ActivityCount.fromJson(Map<String, dynamic> json) =>
      _$ActivityCountFromJson(json);

  String get resourceType => 'ActivityCount';
}
