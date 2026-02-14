// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clinical_test_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClinicalTestResult {

/// Which canonical test was performed.
 TestType get testType;/// The outcome of the test.
 TestResult get result;/// Specimen site.
 SpecimenSite get specimenSite;
/// Create a copy of ClinicalTestResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClinicalTestResultCopyWith<ClinicalTestResult> get copyWith => _$ClinicalTestResultCopyWithImpl<ClinicalTestResult>(this as ClinicalTestResult, _$identity);

  /// Serializes this ClinicalTestResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClinicalTestResult&&(identical(other.testType, testType) || other.testType == testType)&&(identical(other.result, result) || other.result == result)&&(identical(other.specimenSite, specimenSite) || other.specimenSite == specimenSite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,testType,result,specimenSite);

@override
String toString() {
  return 'ClinicalTestResult(testType: $testType, result: $result, specimenSite: $specimenSite)';
}


}

/// @nodoc
abstract mixin class $ClinicalTestResultCopyWith<$Res>  {
  factory $ClinicalTestResultCopyWith(ClinicalTestResult value, $Res Function(ClinicalTestResult) _then) = _$ClinicalTestResultCopyWithImpl;
@useResult
$Res call({
 TestType testType, TestResult result, SpecimenSite specimenSite
});




}
/// @nodoc
class _$ClinicalTestResultCopyWithImpl<$Res>
    implements $ClinicalTestResultCopyWith<$Res> {
  _$ClinicalTestResultCopyWithImpl(this._self, this._then);

  final ClinicalTestResult _self;
  final $Res Function(ClinicalTestResult) _then;

/// Create a copy of ClinicalTestResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? testType = null,Object? result = null,Object? specimenSite = null,}) {
  return _then(_self.copyWith(
testType: null == testType ? _self.testType : testType // ignore: cast_nullable_to_non_nullable
as TestType,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TestResult,specimenSite: null == specimenSite ? _self.specimenSite : specimenSite // ignore: cast_nullable_to_non_nullable
as SpecimenSite,
  ));
}

}


/// Adds pattern-matching-related methods to [ClinicalTestResult].
extension ClinicalTestResultPatterns on ClinicalTestResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClinicalTestResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClinicalTestResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClinicalTestResult value)  $default,){
final _that = this;
switch (_that) {
case _ClinicalTestResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClinicalTestResult value)?  $default,){
final _that = this;
switch (_that) {
case _ClinicalTestResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TestType testType,  TestResult result,  SpecimenSite specimenSite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClinicalTestResult() when $default != null:
return $default(_that.testType,_that.result,_that.specimenSite);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TestType testType,  TestResult result,  SpecimenSite specimenSite)  $default,) {final _that = this;
switch (_that) {
case _ClinicalTestResult():
return $default(_that.testType,_that.result,_that.specimenSite);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TestType testType,  TestResult result,  SpecimenSite specimenSite)?  $default,) {final _that = this;
switch (_that) {
case _ClinicalTestResult() when $default != null:
return $default(_that.testType,_that.result,_that.specimenSite);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClinicalTestResult extends ClinicalTestResult {
  const _ClinicalTestResult({required this.testType, required this.result, required this.specimenSite}): super._();
  factory _ClinicalTestResult.fromJson(Map<String, dynamic> json) => _$ClinicalTestResultFromJson(json);

/// Which canonical test was performed.
@override final  TestType testType;
/// The outcome of the test.
@override final  TestResult result;
/// Specimen site.
@override final  SpecimenSite specimenSite;

/// Create a copy of ClinicalTestResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClinicalTestResultCopyWith<_ClinicalTestResult> get copyWith => __$ClinicalTestResultCopyWithImpl<_ClinicalTestResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClinicalTestResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClinicalTestResult&&(identical(other.testType, testType) || other.testType == testType)&&(identical(other.result, result) || other.result == result)&&(identical(other.specimenSite, specimenSite) || other.specimenSite == specimenSite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,testType,result,specimenSite);

@override
String toString() {
  return 'ClinicalTestResult(testType: $testType, result: $result, specimenSite: $specimenSite)';
}


}

/// @nodoc
abstract mixin class _$ClinicalTestResultCopyWith<$Res> implements $ClinicalTestResultCopyWith<$Res> {
  factory _$ClinicalTestResultCopyWith(_ClinicalTestResult value, $Res Function(_ClinicalTestResult) _then) = __$ClinicalTestResultCopyWithImpl;
@override @useResult
$Res call({
 TestType testType, TestResult result, SpecimenSite specimenSite
});




}
/// @nodoc
class __$ClinicalTestResultCopyWithImpl<$Res>
    implements _$ClinicalTestResultCopyWith<$Res> {
  __$ClinicalTestResultCopyWithImpl(this._self, this._then);

  final _ClinicalTestResult _self;
  final $Res Function(_ClinicalTestResult) _then;

/// Create a copy of ClinicalTestResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? testType = null,Object? result = null,Object? specimenSite = null,}) {
  return _then(_ClinicalTestResult(
testType: null == testType ? _self.testType : testType // ignore: cast_nullable_to_non_nullable
as TestType,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TestResult,specimenSite: null == specimenSite ? _self.specimenSite : specimenSite // ignore: cast_nullable_to_non_nullable
as SpecimenSite,
  ));
}


}

// dart format on
