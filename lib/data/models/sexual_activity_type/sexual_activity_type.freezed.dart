// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sexual_activity_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SexualActivityType {

 String get id; DateTime? get lastUpdateDate; String get name; String? get displayCharacter; int get minParticipants; int get maxParticipants; List<Reference> get properties; bool get requiresPartner;
/// Create a copy of SexualActivityType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SexualActivityTypeCopyWith<SexualActivityType> get copyWith => _$SexualActivityTypeCopyWithImpl<SexualActivityType>(this as SexualActivityType, _$identity);

  /// Serializes this SexualActivityType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SexualActivityType&&(identical(other.id, id) || other.id == id)&&(identical(other.lastUpdateDate, lastUpdateDate) || other.lastUpdateDate == lastUpdateDate)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayCharacter, displayCharacter) || other.displayCharacter == displayCharacter)&&(identical(other.minParticipants, minParticipants) || other.minParticipants == minParticipants)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&const DeepCollectionEquality().equals(other.properties, properties)&&(identical(other.requiresPartner, requiresPartner) || other.requiresPartner == requiresPartner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lastUpdateDate,name,displayCharacter,minParticipants,maxParticipants,const DeepCollectionEquality().hash(properties),requiresPartner);

@override
String toString() {
  return 'SexualActivityType(id: $id, lastUpdateDate: $lastUpdateDate, name: $name, displayCharacter: $displayCharacter, minParticipants: $minParticipants, maxParticipants: $maxParticipants, properties: $properties, requiresPartner: $requiresPartner)';
}


}

/// @nodoc
abstract mixin class $SexualActivityTypeCopyWith<$Res>  {
  factory $SexualActivityTypeCopyWith(SexualActivityType value, $Res Function(SexualActivityType) _then) = _$SexualActivityTypeCopyWithImpl;
@useResult
$Res call({
 String id, DateTime? lastUpdateDate, String name, String? displayCharacter, int minParticipants, int maxParticipants, List<Reference> properties, bool requiresPartner
});




}
/// @nodoc
class _$SexualActivityTypeCopyWithImpl<$Res>
    implements $SexualActivityTypeCopyWith<$Res> {
  _$SexualActivityTypeCopyWithImpl(this._self, this._then);

  final SexualActivityType _self;
  final $Res Function(SexualActivityType) _then;

/// Create a copy of SexualActivityType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lastUpdateDate = freezed,Object? name = null,Object? displayCharacter = freezed,Object? minParticipants = null,Object? maxParticipants = null,Object? properties = null,Object? requiresPartner = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lastUpdateDate: freezed == lastUpdateDate ? _self.lastUpdateDate : lastUpdateDate // ignore: cast_nullable_to_non_nullable
as DateTime?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayCharacter: freezed == displayCharacter ? _self.displayCharacter : displayCharacter // ignore: cast_nullable_to_non_nullable
as String?,minParticipants: null == minParticipants ? _self.minParticipants : minParticipants // ignore: cast_nullable_to_non_nullable
as int,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as List<Reference>,requiresPartner: null == requiresPartner ? _self.requiresPartner : requiresPartner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SexualActivityType].
extension SexualActivityTypePatterns on SexualActivityType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SexualActivityType value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SexualActivityType() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SexualActivityType value)  $default,){
final _that = this;
switch (_that) {
case _SexualActivityType():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SexualActivityType value)?  $default,){
final _that = this;
switch (_that) {
case _SexualActivityType() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime? lastUpdateDate,  String name,  String? displayCharacter,  int minParticipants,  int maxParticipants,  List<Reference> properties,  bool requiresPartner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SexualActivityType() when $default != null:
return $default(_that.id,_that.lastUpdateDate,_that.name,_that.displayCharacter,_that.minParticipants,_that.maxParticipants,_that.properties,_that.requiresPartner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime? lastUpdateDate,  String name,  String? displayCharacter,  int minParticipants,  int maxParticipants,  List<Reference> properties,  bool requiresPartner)  $default,) {final _that = this;
switch (_that) {
case _SexualActivityType():
return $default(_that.id,_that.lastUpdateDate,_that.name,_that.displayCharacter,_that.minParticipants,_that.maxParticipants,_that.properties,_that.requiresPartner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime? lastUpdateDate,  String name,  String? displayCharacter,  int minParticipants,  int maxParticipants,  List<Reference> properties,  bool requiresPartner)?  $default,) {final _that = this;
switch (_that) {
case _SexualActivityType() when $default != null:
return $default(_that.id,_that.lastUpdateDate,_that.name,_that.displayCharacter,_that.minParticipants,_that.maxParticipants,_that.properties,_that.requiresPartner);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SexualActivityType extends SexualActivityType {
  const _SexualActivityType({this.id = "", this.lastUpdateDate, required this.name, this.displayCharacter, this.minParticipants = -1, this.maxParticipants = -1, final  List<Reference> properties = const [], this.requiresPartner = false}): _properties = properties,super._();
  factory _SexualActivityType.fromJson(Map<String, dynamic> json) => _$SexualActivityTypeFromJson(json);

@override@JsonKey() final  String id;
@override final  DateTime? lastUpdateDate;
@override final  String name;
@override final  String? displayCharacter;
@override@JsonKey() final  int minParticipants;
@override@JsonKey() final  int maxParticipants;
 final  List<Reference> _properties;
@override@JsonKey() List<Reference> get properties {
  if (_properties is EqualUnmodifiableListView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_properties);
}

@override@JsonKey() final  bool requiresPartner;

/// Create a copy of SexualActivityType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SexualActivityTypeCopyWith<_SexualActivityType> get copyWith => __$SexualActivityTypeCopyWithImpl<_SexualActivityType>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SexualActivityTypeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SexualActivityType&&(identical(other.id, id) || other.id == id)&&(identical(other.lastUpdateDate, lastUpdateDate) || other.lastUpdateDate == lastUpdateDate)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayCharacter, displayCharacter) || other.displayCharacter == displayCharacter)&&(identical(other.minParticipants, minParticipants) || other.minParticipants == minParticipants)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&const DeepCollectionEquality().equals(other._properties, _properties)&&(identical(other.requiresPartner, requiresPartner) || other.requiresPartner == requiresPartner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lastUpdateDate,name,displayCharacter,minParticipants,maxParticipants,const DeepCollectionEquality().hash(_properties),requiresPartner);

@override
String toString() {
  return 'SexualActivityType(id: $id, lastUpdateDate: $lastUpdateDate, name: $name, displayCharacter: $displayCharacter, minParticipants: $minParticipants, maxParticipants: $maxParticipants, properties: $properties, requiresPartner: $requiresPartner)';
}


}

/// @nodoc
abstract mixin class _$SexualActivityTypeCopyWith<$Res> implements $SexualActivityTypeCopyWith<$Res> {
  factory _$SexualActivityTypeCopyWith(_SexualActivityType value, $Res Function(_SexualActivityType) _then) = __$SexualActivityTypeCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime? lastUpdateDate, String name, String? displayCharacter, int minParticipants, int maxParticipants, List<Reference> properties, bool requiresPartner
});




}
/// @nodoc
class __$SexualActivityTypeCopyWithImpl<$Res>
    implements _$SexualActivityTypeCopyWith<$Res> {
  __$SexualActivityTypeCopyWithImpl(this._self, this._then);

  final _SexualActivityType _self;
  final $Res Function(_SexualActivityType) _then;

/// Create a copy of SexualActivityType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lastUpdateDate = freezed,Object? name = null,Object? displayCharacter = freezed,Object? minParticipants = null,Object? maxParticipants = null,Object? properties = null,Object? requiresPartner = null,}) {
  return _then(_SexualActivityType(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lastUpdateDate: freezed == lastUpdateDate ? _self.lastUpdateDate : lastUpdateDate // ignore: cast_nullable_to_non_nullable
as DateTime?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayCharacter: freezed == displayCharacter ? _self.displayCharacter : displayCharacter // ignore: cast_nullable_to_non_nullable
as String?,minParticipants: null == minParticipants ? _self.minParticipants : minParticipants // ignore: cast_nullable_to_non_nullable
as int,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as List<Reference>,requiresPartner: null == requiresPartner ? _self.requiresPartner : requiresPartner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
