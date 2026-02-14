import 'package:freezed_annotation/freezed_annotation.dart';

part 'clinical_test_result.freezed.dart';
part 'clinical_test_result.g.dart';

/// Canonical list of tests we track. Kept as an enum to make UI lists and
/// analytics simpler and to avoid free-form string mismatches.
@JsonEnum(alwaysCreate: true)
enum TestType {
  @JsonValue('chlamydia')
  chlamydia,

  @JsonValue('gonorrhea')
  gonorrhea,

  @JsonValue('hiv')
  hiv,

  @JsonValue('syphilis')
  syphilis,

  @JsonValue('trichomonas')
  trichomonas,

  @JsonValue('hepatitis')
  hepatitis,

  /// Fallback for tests not covered by the canonical list. UI should still
  /// allow typing a custom display name when `other` is selected.
  @JsonValue('other')
  other,
}

/// Standardized result values for a given test.
@JsonEnum(alwaysCreate: true)
enum TestResult {
  @JsonValue('negative')
  negative,

  @JsonValue('positive')
  positive,

  @JsonValue('indeterminate')
  indeterminate,

  @JsonValue('pending')
  pending,
}

@JsonEnum(alwaysCreate: true)
enum SpecimenSite {
  @JsonValue('throat')
  throat,

  @JsonValue('urine')
  urine,

  @JsonValue('rectal')
  rectal,
}

@Freezed(toJson: true, fromJson: true)
abstract class ClinicalTestResult with _$ClinicalTestResult {
  const ClinicalTestResult._();

  const factory ClinicalTestResult({
    /// Which canonical test was performed.
    required TestType testType,

    /// The outcome of the test.
    required TestResult result,

    /// Specimen site.
    required SpecimenSite specimenSite,
  }) = _ClinicalTestResult;

  // -----------------------------------------------------------------
  // Custom JSON (de)serialization
  // -----------------------------------------------------------------
  factory ClinicalTestResult.fromJson(Map<String, dynamic> json) {
    // Remove any incoming `resourceType` – we ignore it completely.
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$ClinicalTestResultFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    final map = _$ClinicalTestResultToJson(this as _ClinicalTestResult);
    map['resourceType'] = 'ClinicalTestResult';
    return map;
  }

  // Fixed resourceType getter for strong typing in persisted JSON documents.
  @override
  @JsonKey(name: 'resourceType')
  String get resourceType => 'ClinicalTestResult';
}
