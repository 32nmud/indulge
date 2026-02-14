// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinical_test_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClinicalTestResult _$ClinicalTestResultFromJson(Map<String, dynamic> json) =>
    _ClinicalTestResult(
      testType: $enumDecode(_$TestTypeEnumMap, json['testType']),
      result: $enumDecode(_$TestResultEnumMap, json['result']),
      specimenSite: $enumDecode(_$SpecimenSiteEnumMap, json['specimenSite']),
    );

Map<String, dynamic> _$ClinicalTestResultToJson(_ClinicalTestResult instance) =>
    <String, dynamic>{
      'testType': _$TestTypeEnumMap[instance.testType]!,
      'result': _$TestResultEnumMap[instance.result]!,
      'specimenSite': _$SpecimenSiteEnumMap[instance.specimenSite]!,
    };

const _$TestTypeEnumMap = {
  TestType.chlamydia: 'chlamydia',
  TestType.gonorrhea: 'gonorrhea',
  TestType.hiv: 'hiv',
  TestType.syphilis: 'syphilis',
  TestType.trichomonas: 'trichomonas',
  TestType.hepatitis: 'hepatitis',
  TestType.other: 'other',
};

const _$TestResultEnumMap = {
  TestResult.negative: 'negative',
  TestResult.positive: 'positive',
  TestResult.indeterminate: 'indeterminate',
  TestResult.pending: 'pending',
};

const _$SpecimenSiteEnumMap = {
  SpecimenSite.throat: 'throat',
  SpecimenSite.urine: 'urine',
  SpecimenSite.rectal: 'rectal',
};
