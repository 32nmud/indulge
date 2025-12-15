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

 Reference get type; List<SexualActivityParticipant> get participants;
/// Create a copy of SexualActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SexualActivityCopyWith<SexualActivity> get copyWith => _$SexualActivityCopyWithImpl<SexualActivity>(this as SexualActivity, _$identity);

  /// Serializes this SexualActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SexualActivity&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.participants, participants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(participants));

@override
String toString() {
  return 'SexualActivity(type: $type, participants: $participants)';
}


}

/// @nodoc
abstract mixin class $SexualActivityCopyWith<$Res>  {
  factory $SexualActivityCopyWith(SexualActivity value, $Res Function(SexualActivity) _then) = _$SexualActivityCopyWithImpl;
@useResult
$Res call({
 Reference type, List<SexualActivityParticipant> participants
});


$ReferenceCopyWith<$Res> get type;

}
/// @nodoc
class _$SexualActivityCopyWithImpl<$Res>
    implements $SexualActivityCopyWith<$Res> {
  _$SexualActivityCopyWithImpl(this._self, this._then);

  final SexualActivity _self;
  final $Res Function(SexualActivity) _then;

/// Create a copy of SexualActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? participants = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as Reference,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<SexualActivityParticipant>,
  ));
}
/// Create a copy of SexualActivity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res> get type {
  
  return $ReferenceCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Reference type,  List<SexualActivityParticipant> participants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SexualActivity() when $default != null:
return $default(_that.type,_that.participants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Reference type,  List<SexualActivityParticipant> participants)  $default,) {final _that = this;
switch (_that) {
case _SexualActivity():
return $default(_that.type,_that.participants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Reference type,  List<SexualActivityParticipant> participants)?  $default,) {final _that = this;
switch (_that) {
case _SexualActivity() when $default != null:
return $default(_that.type,_that.participants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SexualActivity implements SexualActivity {
  const _SexualActivity({this.type = const Reference(), final  List<SexualActivityParticipant> participants = const []}): _participants = participants;
  factory _SexualActivity.fromJson(Map<String, dynamic> json) => _$SexualActivityFromJson(json);

@override@JsonKey() final  Reference type;
 final  List<SexualActivityParticipant> _participants;
@override@JsonKey() List<SexualActivityParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SexualActivity&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._participants, _participants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_participants));

@override
String toString() {
  return 'SexualActivity(type: $type, participants: $participants)';
}


}

/// @nodoc
abstract mixin class _$SexualActivityCopyWith<$Res> implements $SexualActivityCopyWith<$Res> {
  factory _$SexualActivityCopyWith(_SexualActivity value, $Res Function(_SexualActivity) _then) = __$SexualActivityCopyWithImpl;
@override @useResult
$Res call({
 Reference type, List<SexualActivityParticipant> participants
});


@override $ReferenceCopyWith<$Res> get type;

}
/// @nodoc
class __$SexualActivityCopyWithImpl<$Res>
    implements _$SexualActivityCopyWith<$Res> {
  __$SexualActivityCopyWithImpl(this._self, this._then);

  final _SexualActivity _self;
  final $Res Function(_SexualActivity) _then;

/// Create a copy of SexualActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? participants = null,}) {
  return _then(_SexualActivity(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as Reference,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<SexualActivityParticipant>,
  ));
}

/// Create a copy of SexualActivity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res> get type {
  
  return $ReferenceCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}

// dart format on
