// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sexual_activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SexualActivity {

 String get id; String get name; String get displayCharacter; bool get canHaveMultipleParticipants; bool get isRisky; bool get requiresPartner;
/// Create a copy of SexualActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SexualActivityCopyWith<SexualActivity> get copyWith => _$SexualActivityCopyWithImpl<SexualActivity>(this as SexualActivity, _$identity);

  /// Serializes this SexualActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SexualActivity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayCharacter, displayCharacter) || other.displayCharacter == displayCharacter)&&(identical(other.canHaveMultipleParticipants, canHaveMultipleParticipants) || other.canHaveMultipleParticipants == canHaveMultipleParticipants)&&(identical(other.isRisky, isRisky) || other.isRisky == isRisky)&&(identical(other.requiresPartner, requiresPartner) || other.requiresPartner == requiresPartner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,displayCharacter,canHaveMultipleParticipants,isRisky,requiresPartner);

@override
String toString() {
  return 'SexualActivity(id: $id, name: $name, displayCharacter: $displayCharacter, canHaveMultipleParticipants: $canHaveMultipleParticipants, isRisky: $isRisky, requiresPartner: $requiresPartner)';
}


}

/// @nodoc
abstract mixin class $SexualActivityCopyWith<$Res>  {
  factory $SexualActivityCopyWith(SexualActivity value, $Res Function(SexualActivity) _then) = _$SexualActivityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String displayCharacter, bool canHaveMultipleParticipants, bool isRisky, bool requiresPartner
});




}
/// @nodoc
class _$SexualActivityCopyWithImpl<$Res>
    implements $SexualActivityCopyWith<$Res> {
  _$SexualActivityCopyWithImpl(this._self, this._then);

  final SexualActivity _self;
  final $Res Function(SexualActivity) _then;

/// Create a copy of SexualActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? displayCharacter = null,Object? canHaveMultipleParticipants = null,Object? isRisky = null,Object? requiresPartner = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayCharacter: null == displayCharacter ? _self.displayCharacter : displayCharacter // ignore: cast_nullable_to_non_nullable
as String,canHaveMultipleParticipants: null == canHaveMultipleParticipants ? _self.canHaveMultipleParticipants : canHaveMultipleParticipants // ignore: cast_nullable_to_non_nullable
as bool,isRisky: null == isRisky ? _self.isRisky : isRisky // ignore: cast_nullable_to_non_nullable
as bool,requiresPartner: null == requiresPartner ? _self.requiresPartner : requiresPartner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SexualActivity].
extension SexualActivityPatterns on SexualActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SexualActivity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SexualActivity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SexualActivity value)  $default,){
final _that = this;
switch (_that) {
case _SexualActivity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SexualActivity value)?  $default,){
final _that = this;
switch (_that) {
case _SexualActivity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String displayCharacter,  bool canHaveMultipleParticipants,  bool isRisky,  bool requiresPartner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SexualActivity() when $default != null:
return $default(_that.id,_that.name,_that.displayCharacter,_that.canHaveMultipleParticipants,_that.isRisky,_that.requiresPartner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String displayCharacter,  bool canHaveMultipleParticipants,  bool isRisky,  bool requiresPartner)  $default,) {final _that = this;
switch (_that) {
case _SexualActivity():
return $default(_that.id,_that.name,_that.displayCharacter,_that.canHaveMultipleParticipants,_that.isRisky,_that.requiresPartner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String displayCharacter,  bool canHaveMultipleParticipants,  bool isRisky,  bool requiresPartner)?  $default,) {final _that = this;
switch (_that) {
case _SexualActivity() when $default != null:
return $default(_that.id,_that.name,_that.displayCharacter,_that.canHaveMultipleParticipants,_that.isRisky,_that.requiresPartner);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SexualActivity extends SexualActivity {
  const _SexualActivity({this.id = "", this.name = "unknown", this.displayCharacter = "❔", this.canHaveMultipleParticipants = true, this.isRisky = false, this.requiresPartner = false}): super._();
  factory _SexualActivity.fromJson(Map<String, dynamic> json) => _$SexualActivityFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String displayCharacter;
@override@JsonKey() final  bool canHaveMultipleParticipants;
@override@JsonKey() final  bool isRisky;
@override@JsonKey() final  bool requiresPartner;

/// Create a copy of SexualActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SexualActivityCopyWith<_SexualActivity> get copyWith => __$SexualActivityCopyWithImpl<_SexualActivity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SexualActivityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SexualActivity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayCharacter, displayCharacter) || other.displayCharacter == displayCharacter)&&(identical(other.canHaveMultipleParticipants, canHaveMultipleParticipants) || other.canHaveMultipleParticipants == canHaveMultipleParticipants)&&(identical(other.isRisky, isRisky) || other.isRisky == isRisky)&&(identical(other.requiresPartner, requiresPartner) || other.requiresPartner == requiresPartner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,displayCharacter,canHaveMultipleParticipants,isRisky,requiresPartner);

@override
String toString() {
  return 'SexualActivity(id: $id, name: $name, displayCharacter: $displayCharacter, canHaveMultipleParticipants: $canHaveMultipleParticipants, isRisky: $isRisky, requiresPartner: $requiresPartner)';
}


}

/// @nodoc
abstract mixin class _$SexualActivityCopyWith<$Res> implements $SexualActivityCopyWith<$Res> {
  factory _$SexualActivityCopyWith(_SexualActivity value, $Res Function(_SexualActivity) _then) = __$SexualActivityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String displayCharacter, bool canHaveMultipleParticipants, bool isRisky, bool requiresPartner
});




}
/// @nodoc
class __$SexualActivityCopyWithImpl<$Res>
    implements _$SexualActivityCopyWith<$Res> {
  __$SexualActivityCopyWithImpl(this._self, this._then);

  final _SexualActivity _self;
  final $Res Function(_SexualActivity) _then;

/// Create a copy of SexualActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? displayCharacter = null,Object? canHaveMultipleParticipants = null,Object? isRisky = null,Object? requiresPartner = null,}) {
  return _then(_SexualActivity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayCharacter: null == displayCharacter ? _self.displayCharacter : displayCharacter // ignore: cast_nullable_to_non_nullable
as String,canHaveMultipleParticipants: null == canHaveMultipleParticipants ? _self.canHaveMultipleParticipants : canHaveMultipleParticipants // ignore: cast_nullable_to_non_nullable
as bool,isRisky: null == isRisky ? _self.isRisky : isRisky // ignore: cast_nullable_to_non_nullable
as bool,requiresPartner: null == requiresPartner ? _self.requiresPartner : requiresPartner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
