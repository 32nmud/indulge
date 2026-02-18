import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import '../clinical_test_result/clinical_test_result.dart';

part 'clinical_event.freezed.dart';
part 'clinical_event.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class ClinicalEvent with _$ClinicalEvent {
  const ClinicalEvent._();

  /// ClinicalEvent represents one encounter where one or more STI/STD tests
  /// were performed for the current user.
  ///
  /// - `tests` is a list of `ClinicalTestResult` entries (each entry pairs a
  ///   canonical `TestType` with a `TestResult`).
  /// - `facility` is an optional free-form string containing the testing
  ///   facility name.
  /// - `notes` is a general text field for the event; per-test notes are not
  ///   modeled here (kept out to match the requested simplification).
  const factory ClinicalEvent({
    @Default("") String id,
    required DateTime date,
    DateTime? lastModifiedDate,
    required List<ClinicalTestResult> tests,
    String? facility,
    String? notes,
  }) = _ClinicalEvent;

  // -----------------------------------------------------------------
  // Custom JSON (de)serialization
  // -----------------------------------------------------------------
  factory ClinicalEvent.fromJson(Map<String, dynamic> json) {
    // Remove any incoming `resourceType` – we ignore it completely.
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$ClinicalEventFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    final map = _$ClinicalEventToJson(this as _ClinicalEvent);
    map['resourceType'] = 'ClinicalEvent';
    return map;
  }

  // -----------------------------------------------------------------
  // Fixed getters
  // -----------------------------------------------------------------
  @JsonKey(name: 'resourceType')
  String get resourceType => 'ClinicalEvent';

  @override
  String get id => (this as _ClinicalEvent).id == ""
      ? const Uuid().v4()
      : (this as _ClinicalEvent).id;
}
