// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clinical_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClinicalEvent {

 String get id; DateTime get date; DateTime? get lastModifiedDate; List<ClinicalTestResult> get tests; String? get facility; String? get notes;
/// Create a copy of ClinicalEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClinicalEventCopyWith<ClinicalEvent> get copyWith => _$ClinicalEventCopyWithImpl<ClinicalEvent>(this as ClinicalEvent, _$identity);

  /// Serializes this ClinicalEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClinicalEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.lastModifiedDate, lastModifiedDate) || other.lastModifiedDate == lastModifiedDate)&&const DeepCollectionEquality().equals(other.tests, tests)&&(identical(other.facility, facility) || other.facility == facility)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,lastModifiedDate,const DeepCollectionEquality().hash(tests),facility,notes);

@override
String toString() {
  return 'ClinicalEvent(id: $id, date: $date, lastModifiedDate: $lastModifiedDate, tests: $tests, facility: $facility, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ClinicalEventCopyWith<$Res>  {
  factory $ClinicalEventCopyWith(ClinicalEvent value, $Res Function(ClinicalEvent) _then) = _$ClinicalEventCopyWithImpl;
@useResult
$Res call({
 String id, DateTime date, DateTime? lastModifiedDate, List<ClinicalTestResult> tests, String? facility, String? notes
});




}
/// @nodoc
class _$ClinicalEventCopyWithImpl<$Res>
    implements $ClinicalEventCopyWith<$Res> {
  _$ClinicalEventCopyWithImpl(this._self, this._then);

  final ClinicalEvent _self;
  final $Res Function(ClinicalEvent) _then;

/// Create a copy of ClinicalEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? lastModifiedDate = freezed,Object? tests = null,Object? facility = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,lastModifiedDate: freezed == lastModifiedDate ? _self.lastModifiedDate : lastModifiedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,tests: null == tests ? _self.tests : tests // ignore: cast_nullable_to_non_nullable
as List<ClinicalTestResult>,facility: freezed == facility ? _self.facility : facility // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ClinicalEvent].
extension ClinicalEventPatterns on ClinicalEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClinicalEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClinicalEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClinicalEvent value)  $default,){
final _that = this;
switch (_that) {
case _ClinicalEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClinicalEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ClinicalEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime date,  DateTime? lastModifiedDate,  List<ClinicalTestResult> tests,  String? facility,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClinicalEvent() when $default != null:
return $default(_that.id,_that.date,_that.lastModifiedDate,_that.tests,_that.facility,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime date,  DateTime? lastModifiedDate,  List<ClinicalTestResult> tests,  String? facility,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _ClinicalEvent():
return $default(_that.id,_that.date,_that.lastModifiedDate,_that.tests,_that.facility,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime date,  DateTime? lastModifiedDate,  List<ClinicalTestResult> tests,  String? facility,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _ClinicalEvent() when $default != null:
return $default(_that.id,_that.date,_that.lastModifiedDate,_that.tests,_that.facility,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClinicalEvent extends ClinicalEvent {
  const _ClinicalEvent({this.id = "", required this.date, this.lastModifiedDate, required final  List<ClinicalTestResult> tests, this.facility, this.notes}): _tests = tests,super._();
  factory _ClinicalEvent.fromJson(Map<String, dynamic> json) => _$ClinicalEventFromJson(json);

@override@JsonKey() final  String id;
@override final  DateTime date;
@override final  DateTime? lastModifiedDate;
 final  List<ClinicalTestResult> _tests;
@override List<ClinicalTestResult> get tests {
  if (_tests is EqualUnmodifiableListView) return _tests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tests);
}

@override final  String? facility;
@override final  String? notes;

/// Create a copy of ClinicalEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClinicalEventCopyWith<_ClinicalEvent> get copyWith => __$ClinicalEventCopyWithImpl<_ClinicalEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClinicalEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClinicalEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.lastModifiedDate, lastModifiedDate) || other.lastModifiedDate == lastModifiedDate)&&const DeepCollectionEquality().equals(other._tests, _tests)&&(identical(other.facility, facility) || other.facility == facility)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,lastModifiedDate,const DeepCollectionEquality().hash(_tests),facility,notes);

@override
String toString() {
  return 'ClinicalEvent(id: $id, date: $date, lastModifiedDate: $lastModifiedDate, tests: $tests, facility: $facility, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ClinicalEventCopyWith<$Res> implements $ClinicalEventCopyWith<$Res> {
  factory _$ClinicalEventCopyWith(_ClinicalEvent value, $Res Function(_ClinicalEvent) _then) = __$ClinicalEventCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime date, DateTime? lastModifiedDate, List<ClinicalTestResult> tests, String? facility, String? notes
});




}
/// @nodoc
class __$ClinicalEventCopyWithImpl<$Res>
    implements _$ClinicalEventCopyWith<$Res> {
  __$ClinicalEventCopyWithImpl(this._self, this._then);

  final _ClinicalEvent _self;
  final $Res Function(_ClinicalEvent) _then;

/// Create a copy of ClinicalEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? lastModifiedDate = freezed,Object? tests = null,Object? facility = freezed,Object? notes = freezed,}) {
  return _then(_ClinicalEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,lastModifiedDate: freezed == lastModifiedDate ? _self.lastModifiedDate : lastModifiedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,tests: null == tests ? _self._tests : tests // ignore: cast_nullable_to_non_nullable
as List<ClinicalTestResult>,facility: freezed == facility ? _self.facility : facility // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
