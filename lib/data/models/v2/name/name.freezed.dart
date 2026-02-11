// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'name.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Name {

 String? get given; String? get family; String? get nickname;
/// Create a copy of Name
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NameCopyWith<Name> get copyWith => _$NameCopyWithImpl<Name>(this as Name, _$identity);

  /// Serializes this Name to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Name&&(identical(other.given, given) || other.given == given)&&(identical(other.family, family) || other.family == family)&&(identical(other.nickname, nickname) || other.nickname == nickname));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,given,family,nickname);

@override
String toString() {
  return 'Name(given: $given, family: $family, nickname: $nickname)';
}


}

/// @nodoc
abstract mixin class $NameCopyWith<$Res>  {
  factory $NameCopyWith(Name value, $Res Function(Name) _then) = _$NameCopyWithImpl;
@useResult
$Res call({
 String? given, String? family, String? nickname
});




}
/// @nodoc
class _$NameCopyWithImpl<$Res>
    implements $NameCopyWith<$Res> {
  _$NameCopyWithImpl(this._self, this._then);

  final Name _self;
  final $Res Function(Name) _then;

/// Create a copy of Name
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? given = freezed,Object? family = freezed,Object? nickname = freezed,}) {
  return _then(_self.copyWith(
given: freezed == given ? _self.given : given // ignore: cast_nullable_to_non_nullable
as String?,family: freezed == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Name].
extension NamePatterns on Name {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Name value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Name() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Name value)  $default,){
final _that = this;
switch (_that) {
case _Name():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Name value)?  $default,){
final _that = this;
switch (_that) {
case _Name() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? given,  String? family,  String? nickname)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Name() when $default != null:
return $default(_that.given,_that.family,_that.nickname);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? given,  String? family,  String? nickname)  $default,) {final _that = this;
switch (_that) {
case _Name():
return $default(_that.given,_that.family,_that.nickname);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? given,  String? family,  String? nickname)?  $default,) {final _that = this;
switch (_that) {
case _Name() when $default != null:
return $default(_that.given,_that.family,_that.nickname);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Name implements Name {
  const _Name({this.given, this.family, this.nickname});
  factory _Name.fromJson(Map<String, dynamic> json) => _$NameFromJson(json);

@override final  String? given;
@override final  String? family;
@override final  String? nickname;

/// Create a copy of Name
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NameCopyWith<_Name> get copyWith => __$NameCopyWithImpl<_Name>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NameToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Name&&(identical(other.given, given) || other.given == given)&&(identical(other.family, family) || other.family == family)&&(identical(other.nickname, nickname) || other.nickname == nickname));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,given,family,nickname);

@override
String toString() {
  return 'Name(given: $given, family: $family, nickname: $nickname)';
}


}

/// @nodoc
abstract mixin class _$NameCopyWith<$Res> implements $NameCopyWith<$Res> {
  factory _$NameCopyWith(_Name value, $Res Function(_Name) _then) = __$NameCopyWithImpl;
@override @useResult
$Res call({
 String? given, String? family, String? nickname
});




}
/// @nodoc
class __$NameCopyWithImpl<$Res>
    implements _$NameCopyWith<$Res> {
  __$NameCopyWithImpl(this._self, this._then);

  final _Name _self;
  final $Res Function(_Name) _then;

/// Create a copy of Name
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? given = freezed,Object? family = freezed,Object? nickname = freezed,}) {
  return _then(_Name(
given: freezed == given ? _self.given : given // ignore: cast_nullable_to_non_nullable
as String?,family: freezed == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
