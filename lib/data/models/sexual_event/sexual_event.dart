import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import '../sexual_activity/sexual_activity.dart';

part 'sexual_event.freezed.dart';
part 'sexual_event.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class SexualEvent with _$SexualEvent {
  const SexualEvent._();

  const factory SexualEvent({
    @Default("") String id,
    required DateTime date,
    DateTime? lastModifiedDate,
    required List<SexualActivity> activities,
  }) = _SexualEvent;

  // -----------------------------------------------------------------
  // Custom JSON (de)serialization
  // -----------------------------------------------------------------
  factory SexualEvent.fromJson(Map<String, dynamic> json) {
    // Remove any incoming `resourceType` – we ignore it completely.
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$SexualEventFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    // Let the generated helper create the map, then inject the constant.
    final map = _$SexualEventToJson(this as _SexualEvent);
    map['resourceType'] = "SexualEvent"; // guarantee the correct value
    return map;
  }

  // -----------------------------------------------------------------
  // Fixed getters
  // -----------------------------------------------------------------
  @override
  @JsonKey(name: 'resourceType')
  String get resourceType => "SexualEvent";

  @override
  String get id => (this as _SexualEvent).id == ""
      ? const Uuid().v4()
      : (this as _SexualEvent).id;
}
