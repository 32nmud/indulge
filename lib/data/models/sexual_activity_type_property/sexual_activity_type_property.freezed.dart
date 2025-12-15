// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sexual_activity_type_property.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SexualActivityTypeProperty {

 String get id; String get name; String get displayCharacter; bool get canHaveMultipleParticipants;
/// Create a copy of SexualActivityTypeProperty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SexualActivityTypePropertyCopyWith<SexualActivityTypeProperty> get copyWith => _$SexualActivityTypePropertyCopyWithImpl<SexualActivityTypeProperty>(this as SexualActivityTypeProperty, _$identity);

  /// Serializes this SexualActivityTypeProperty to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SexualActivityTypeProperty&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayCharacter, displayCharacter) || other.displayCharacter == displayCharacter)&&(identical(other.canHaveMultipleParticipants, canHaveMultipleParticipants) || other.canHaveMultipleParticipants == canHaveMultipleParticipants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,displayCharacter,canHaveMultipleParticipants);

@override
String toString() {
  return 'SexualActivityTypeProperty(id: $id, name: $name, displayCharacter: $displayCharacter, canHaveMultipleParticipants: $canHaveMultipleParticipants)';
}


}

/// @nodoc
abstract mixin class $SexualActivityTypePropertyCopyWith<$Res>  {
  factory $SexualActivityTypePropertyCopyWith(SexualActivityTypeProperty value, $Res Function(SexualActivityTypeProperty) _then) = _$SexualActivityTypePropertyCopyWithImpl;
@useResult
$Res call({
 String id, String name, String displayCharacter, bool canHaveMultipleParticipants
});




}
/// @nodoc
class _$SexualActivityTypePropertyCopyWithImpl<$Res>
    implements $SexualActivityTypePropertyCopyWith<$Res> {
  _$SexualActivityTypePropertyCopyWithImpl(this._self, this._then);

  final SexualActivityTypeProperty _self;
  final $Res Function(SexualActivityTypeProperty) _then;

/// Create a copy of SexualActivityTypeProperty
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? displayCharacter = null,Object? canHaveMultipleParticipants = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayCharacter: null == displayCharacter ? _self.displayCharacter : displayCharacter // ignore: cast_nullable_to_non_nullable
as String,canHaveMultipleParticipants: null == canHaveMultipleParticipants ? _self.canHaveMultipleParticipants : canHaveMultipleParticipants // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SexualActivityTypeProperty].
extension SexualActivityTypePropertyPatterns on SexualActivityTypeProperty {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SexualActivityTypeProperty value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SexualActivityTypeProperty() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SexualActivityTypeProperty value)  $default,){
final _that = this;
switch (_that) {
case _SexualActivityTypeProperty():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SexualActivityTypeProperty value)?  $default,){
final _that = this;
switch (_that) {
case _SexualActivityTypeProperty() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String displayCharacter,  bool canHaveMultipleParticipants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SexualActivityTypeProperty() when $default != null:
return $default(_that.id,_that.name,_that.displayCharacter,_that.canHaveMultipleParticipants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String displayCharacter,  bool canHaveMultipleParticipants)  $default,) {final _that = this;
switch (_that) {
case _SexualActivityTypeProperty():
return $default(_that.id,_that.name,_that.displayCharacter,_that.canHaveMultipleParticipants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String displayCharacter,  bool canHaveMultipleParticipants)?  $default,) {final _that = this;
switch (_that) {
case _SexualActivityTypeProperty() when $default != null:
return $default(_that.id,_that.name,_that.displayCharacter,_that.canHaveMultipleParticipants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SexualActivityTypeProperty extends SexualActivityTypeProperty {
  const _SexualActivityTypeProperty({this.id = "", this.name = "unknown", this.displayCharacter = "❔", this.canHaveMultipleParticipants = true}): super._();
  factory _SexualActivityTypeProperty.fromJson(Map<String, dynamic> json) => _$SexualActivityTypePropertyFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String displayCharacter;
@override@JsonKey() final  bool canHaveMultipleParticipants;

/// Create a copy of SexualActivityTypeProperty
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SexualActivityTypePropertyCopyWith<_SexualActivityTypeProperty> get copyWith => __$SexualActivityTypePropertyCopyWithImpl<_SexualActivityTypeProperty>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SexualActivityTypePropertyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SexualActivityTypeProperty&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayCharacter, displayCharacter) || other.displayCharacter == displayCharacter)&&(identical(other.canHaveMultipleParticipants, canHaveMultipleParticipants) || other.canHaveMultipleParticipants == canHaveMultipleParticipants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,displayCharacter,canHaveMultipleParticipants);

@override
String toString() {
  return 'SexualActivityTypeProperty(id: $id, name: $name, displayCharacter: $displayCharacter, canHaveMultipleParticipants: $canHaveMultipleParticipants)';
}


}

/// @nodoc
abstract mixin class _$SexualActivityTypePropertyCopyWith<$Res> implements $SexualActivityTypePropertyCopyWith<$Res> {
  factory _$SexualActivityTypePropertyCopyWith(_SexualActivityTypeProperty value, $Res Function(_SexualActivityTypeProperty) _then) = __$SexualActivityTypePropertyCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String displayCharacter, bool canHaveMultipleParticipants
});




}
/// @nodoc
class __$SexualActivityTypePropertyCopyWithImpl<$Res>
    implements _$SexualActivityTypePropertyCopyWith<$Res> {
  __$SexualActivityTypePropertyCopyWithImpl(this._self, this._then);

  final _SexualActivityTypeProperty _self;
  final $Res Function(_SexualActivityTypeProperty) _then;

/// Create a copy of SexualActivityTypeProperty
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? displayCharacter = null,Object? canHaveMultipleParticipants = null,}) {
  return _then(_SexualActivityTypeProperty(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayCharacter: null == displayCharacter ? _self.displayCharacter : displayCharacter // ignore: cast_nullable_to_non_nullable
as String,canHaveMultipleParticipants: null == canHaveMultipleParticipants ? _self.canHaveMultipleParticipants : canHaveMultipleParticipants // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
