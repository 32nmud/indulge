// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sexual_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SexualEvent {

 String get id; DateTime get date; DateTime? get lastModifiedDate; List<EventActivity> get activities; String? get notes;
/// Create a copy of SexualEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SexualEventCopyWith<SexualEvent> get copyWith => _$SexualEventCopyWithImpl<SexualEvent>(this as SexualEvent, _$identity);

  /// Serializes this SexualEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SexualEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.lastModifiedDate, lastModifiedDate) || other.lastModifiedDate == lastModifiedDate)&&const DeepCollectionEquality().equals(other.activities, activities)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,lastModifiedDate,const DeepCollectionEquality().hash(activities),notes);

@override
String toString() {
  return 'SexualEvent(id: $id, date: $date, lastModifiedDate: $lastModifiedDate, activities: $activities, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $SexualEventCopyWith<$Res>  {
  factory $SexualEventCopyWith(SexualEvent value, $Res Function(SexualEvent) _then) = _$SexualEventCopyWithImpl;
@useResult
$Res call({
 String id, DateTime date, DateTime? lastModifiedDate, List<EventActivity> activities, String? notes
});




}
/// @nodoc
class _$SexualEventCopyWithImpl<$Res>
    implements $SexualEventCopyWith<$Res> {
  _$SexualEventCopyWithImpl(this._self, this._then);

  final SexualEvent _self;
  final $Res Function(SexualEvent) _then;

/// Create a copy of SexualEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? lastModifiedDate = freezed,Object? activities = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,lastModifiedDate: freezed == lastModifiedDate ? _self.lastModifiedDate : lastModifiedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,activities: null == activities ? _self.activities : activities // ignore: cast_nullable_to_non_nullable
as List<EventActivity>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SexualEvent].
extension SexualEventPatterns on SexualEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SexualEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SexualEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SexualEvent value)  $default,){
final _that = this;
switch (_that) {
case _SexualEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SexualEvent value)?  $default,){
final _that = this;
switch (_that) {
case _SexualEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime date,  DateTime? lastModifiedDate,  List<EventActivity> activities,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SexualEvent() when $default != null:
return $default(_that.id,_that.date,_that.lastModifiedDate,_that.activities,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime date,  DateTime? lastModifiedDate,  List<EventActivity> activities,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _SexualEvent():
return $default(_that.id,_that.date,_that.lastModifiedDate,_that.activities,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime date,  DateTime? lastModifiedDate,  List<EventActivity> activities,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _SexualEvent() when $default != null:
return $default(_that.id,_that.date,_that.lastModifiedDate,_that.activities,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SexualEvent extends SexualEvent {
  const _SexualEvent({this.id = "", required this.date, this.lastModifiedDate, required final  List<EventActivity> activities, this.notes}): _activities = activities,super._();
  factory _SexualEvent.fromJson(Map<String, dynamic> json) => _$SexualEventFromJson(json);

@override@JsonKey() final  String id;
@override final  DateTime date;
@override final  DateTime? lastModifiedDate;
 final  List<EventActivity> _activities;
@override List<EventActivity> get activities {
  if (_activities is EqualUnmodifiableListView) return _activities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activities);
}

@override final  String? notes;

/// Create a copy of SexualEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SexualEventCopyWith<_SexualEvent> get copyWith => __$SexualEventCopyWithImpl<_SexualEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SexualEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SexualEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.lastModifiedDate, lastModifiedDate) || other.lastModifiedDate == lastModifiedDate)&&const DeepCollectionEquality().equals(other._activities, _activities)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,lastModifiedDate,const DeepCollectionEquality().hash(_activities),notes);

@override
String toString() {
  return 'SexualEvent(id: $id, date: $date, lastModifiedDate: $lastModifiedDate, activities: $activities, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$SexualEventCopyWith<$Res> implements $SexualEventCopyWith<$Res> {
  factory _$SexualEventCopyWith(_SexualEvent value, $Res Function(_SexualEvent) _then) = __$SexualEventCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime date, DateTime? lastModifiedDate, List<EventActivity> activities, String? notes
});




}
/// @nodoc
class __$SexualEventCopyWithImpl<$Res>
    implements _$SexualEventCopyWith<$Res> {
  __$SexualEventCopyWithImpl(this._self, this._then);

  final _SexualEvent _self;
  final $Res Function(_SexualEvent) _then;

/// Create a copy of SexualEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? lastModifiedDate = freezed,Object? activities = null,Object? notes = freezed,}) {
  return _then(_SexualEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,lastModifiedDate: freezed == lastModifiedDate ? _self.lastModifiedDate : lastModifiedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,activities: null == activities ? _self._activities : activities // ignore: cast_nullable_to_non_nullable
as List<EventActivity>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
