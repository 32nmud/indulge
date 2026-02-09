import 'package:freezed_annotation/freezed_annotation.dart';
import '../reference/reference.dart';

part 'property_count.freezed.dart';
part 'property_count.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class PropertyCount with _$PropertyCount {
  const factory PropertyCount({
    @Default(Reference()) Reference propertyReference,
    @Default(1) int count,
  }) = _PropertyCount;

  factory PropertyCount.fromJson(Map<String, dynamic> json) =>
      _$PropertyCountFromJson(json);
}
