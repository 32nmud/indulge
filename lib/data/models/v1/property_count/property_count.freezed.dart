// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'property_count.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PropertyCount {

 Reference get propertyReference; int get count;
/// Create a copy of PropertyCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertyCountCopyWith<PropertyCount> get copyWith => _$PropertyCountCopyWithImpl<PropertyCount>(this as PropertyCount, _$identity);

  /// Serializes this PropertyCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PropertyCount&&(identical(other.propertyReference, propertyReference) || other.propertyReference == propertyReference)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,propertyReference,count);

@override
String toString() {
  return 'PropertyCount(propertyReference: $propertyReference, count: $count)';
}


}

/// @nodoc
abstract mixin class $PropertyCountCopyWith<$Res>  {
  factory $PropertyCountCopyWith(PropertyCount value, $Res Function(PropertyCount) _then) = _$PropertyCountCopyWithImpl;
@useResult
$Res call({
 Reference propertyReference, int count
});


$ReferenceCopyWith<$Res> get propertyReference;

}
/// @nodoc
class _$PropertyCountCopyWithImpl<$Res>
    implements $PropertyCountCopyWith<$Res> {
  _$PropertyCountCopyWithImpl(this._self, this._then);

  final PropertyCount _self;
  final $Res Function(PropertyCount) _then;

/// Create a copy of PropertyCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? propertyReference = null,Object? count = null,}) {
  return _then(_self.copyWith(
propertyReference: null == propertyReference ? _self.propertyReference : propertyReference // ignore: cast_nullable_to_non_nullable
as Reference,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of PropertyCount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res> get propertyReference {
  
  return $ReferenceCopyWith<$Res>(_self.propertyReference, (value) {
    return _then(_self.copyWith(propertyReference: value));
  });
}
}


/// Adds pattern-matching-related methods to [PropertyCount].
extension PropertyCountPatterns on PropertyCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PropertyCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PropertyCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PropertyCount value)  $default,){
final _that = this;
switch (_that) {
case _PropertyCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PropertyCount value)?  $default,){
final _that = this;
switch (_that) {
case _PropertyCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Reference propertyReference,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PropertyCount() when $default != null:
return $default(_that.propertyReference,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Reference propertyReference,  int count)  $default,) {final _that = this;
switch (_that) {
case _PropertyCount():
return $default(_that.propertyReference,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Reference propertyReference,  int count)?  $default,) {final _that = this;
switch (_that) {
case _PropertyCount() when $default != null:
return $default(_that.propertyReference,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PropertyCount implements PropertyCount {
  const _PropertyCount({this.propertyReference = const Reference(), this.count = 1});
  factory _PropertyCount.fromJson(Map<String, dynamic> json) => _$PropertyCountFromJson(json);

@override@JsonKey() final  Reference propertyReference;
@override@JsonKey() final  int count;

/// Create a copy of PropertyCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertyCountCopyWith<_PropertyCount> get copyWith => __$PropertyCountCopyWithImpl<_PropertyCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PropertyCountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PropertyCount&&(identical(other.propertyReference, propertyReference) || other.propertyReference == propertyReference)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,propertyReference,count);

@override
String toString() {
  return 'PropertyCount(propertyReference: $propertyReference, count: $count)';
}


}

/// @nodoc
abstract mixin class _$PropertyCountCopyWith<$Res> implements $PropertyCountCopyWith<$Res> {
  factory _$PropertyCountCopyWith(_PropertyCount value, $Res Function(_PropertyCount) _then) = __$PropertyCountCopyWithImpl;
@override @useResult
$Res call({
 Reference propertyReference, int count
});


@override $ReferenceCopyWith<$Res> get propertyReference;

}
/// @nodoc
class __$PropertyCountCopyWithImpl<$Res>
    implements _$PropertyCountCopyWith<$Res> {
  __$PropertyCountCopyWithImpl(this._self, this._then);

  final _PropertyCount _self;
  final $Res Function(_PropertyCount) _then;

/// Create a copy of PropertyCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? propertyReference = null,Object? count = null,}) {
  return _then(_PropertyCount(
propertyReference: null == propertyReference ? _self.propertyReference : propertyReference // ignore: cast_nullable_to_non_nullable
as Reference,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of PropertyCount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res> get propertyReference {
  
  return $ReferenceCopyWith<$Res>(_self.propertyReference, (value) {
    return _then(_self.copyWith(propertyReference: value));
  });
}
}

// dart format on
