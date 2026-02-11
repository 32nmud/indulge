import 'package:freezed_annotation/freezed_annotation.dart';
import '../reference/reference.dart';
import '../../versioned_model.dart';

part 'activity_count.freezed.dart';
part 'activity_count.g.dart';

/// V2: Renamed from PropertyCount to ActivityCount for clarity
/// Represents a count of a specific activity performed by a participant
@Freezed(toJson: true, fromJson: true)
abstract class ActivityCount with _$ActivityCount implements VersionedModel {
  const ActivityCount._();

  const factory ActivityCount({
    @Default(Reference()) Reference activityReference,
    @Default(1) int count,
    @Default(2) int version,
  }) = _ActivityCount;

  factory ActivityCount.fromJson(Map<String, dynamic> json) =>
      _$ActivityCountFromJson(json);

  @override
  String get resourceType => 'ActivityCount';
}
