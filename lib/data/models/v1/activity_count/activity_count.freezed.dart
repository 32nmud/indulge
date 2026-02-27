// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_count.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityCount {

 Reference get activityReference; int get count;
/// Create a copy of ActivityCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityCountCopyWith<ActivityCount> get copyWith => _$ActivityCountCopyWithImpl<ActivityCount>(this as ActivityCount, _$identity);

  /// Serializes this ActivityCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityCount&&(identical(other.activityReference, activityReference) || other.activityReference == activityReference)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activityReference,count);

@override
String toString() {
  return 'ActivityCount(activityReference: $activityReference, count: $count)';
}


}

/// @nodoc
abstract mixin class $ActivityCountCopyWith<$Res>  {
  factory $ActivityCountCopyWith(ActivityCount value, $Res Function(ActivityCount) _then) = _$ActivityCountCopyWithImpl;
@useResult
$Res call({
 Reference activityReference, int count
});


$ReferenceCopyWith<$Res> get activityReference;

}
/// @nodoc
class _$ActivityCountCopyWithImpl<$Res>
    implements $ActivityCountCopyWith<$Res> {
  _$ActivityCountCopyWithImpl(this._self, this._then);

  final ActivityCount _self;
  final $Res Function(ActivityCount) _then;

/// Create a copy of ActivityCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activityReference = null,Object? count = null,}) {
  return _then(_self.copyWith(
activityReference: null == activityReference ? _self.activityReference : activityReference // ignore: cast_nullable_to_non_nullable
as Reference,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ActivityCount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res> get activityReference {
  
  return $ReferenceCopyWith<$Res>(_self.activityReference, (value) {
    return _then(_self.copyWith(activityReference: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActivityCount].
extension ActivityCountPatterns on ActivityCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityCount value)  $default,){
final _that = this;
switch (_that) {
case _ActivityCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityCount value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Reference activityReference,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityCount() when $default != null:
return $default(_that.activityReference,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Reference activityReference,  int count)  $default,) {final _that = this;
switch (_that) {
case _ActivityCount():
return $default(_that.activityReference,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Reference activityReference,  int count)?  $default,) {final _that = this;
switch (_that) {
case _ActivityCount() when $default != null:
return $default(_that.activityReference,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityCount extends ActivityCount {
  const _ActivityCount({this.activityReference = const Reference(), this.count = 1}): super._();
  factory _ActivityCount.fromJson(Map<String, dynamic> json) => _$ActivityCountFromJson(json);

@override@JsonKey() final  Reference activityReference;
@override@JsonKey() final  int count;

/// Create a copy of ActivityCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityCountCopyWith<_ActivityCount> get copyWith => __$ActivityCountCopyWithImpl<_ActivityCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityCountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityCount&&(identical(other.activityReference, activityReference) || other.activityReference == activityReference)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activityReference,count);

@override
String toString() {
  return 'ActivityCount(activityReference: $activityReference, count: $count)';
}


}

/// @nodoc
abstract mixin class _$ActivityCountCopyWith<$Res> implements $ActivityCountCopyWith<$Res> {
  factory _$ActivityCountCopyWith(_ActivityCount value, $Res Function(_ActivityCount) _then) = __$ActivityCountCopyWithImpl;
@override @useResult
$Res call({
 Reference activityReference, int count
});


@override $ReferenceCopyWith<$Res> get activityReference;

}
/// @nodoc
class __$ActivityCountCopyWithImpl<$Res>
    implements _$ActivityCountCopyWith<$Res> {
  __$ActivityCountCopyWithImpl(this._self, this._then);

  final _ActivityCount _self;
  final $Res Function(_ActivityCount) _then;

/// Create a copy of ActivityCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activityReference = null,Object? count = null,}) {
  return _then(_ActivityCount(
activityReference: null == activityReference ? _self.activityReference : activityReference // ignore: cast_nullable_to_non_nullable
as Reference,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ActivityCount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res> get activityReference {
  
  return $ReferenceCopyWith<$Res>(_self.activityReference, (value) {
    return _then(_self.copyWith(activityReference: value));
  });
}
}

// dart format on
