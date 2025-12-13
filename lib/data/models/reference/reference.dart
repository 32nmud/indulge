import 'package:freezed_annotation/freezed_annotation.dart';

part 'reference.freezed.dart';
part 'reference.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class Reference with _$Reference {
  const factory Reference({
    @Default('') String reference,
    @Default('') String resourceType,
  }) = _Reference;

  factory Reference.fromJson(Map<String, dynamic> json) =>
      _$ReferenceFromJson(json);
}
