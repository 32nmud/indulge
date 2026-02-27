// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sexual_activity_participant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SexualActivityParticipant {

 Reference get participant; List<ActivityCount> get activityCounts;
/// Create a copy of SexualActivityParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SexualActivityParticipantCopyWith<SexualActivityParticipant> get copyWith => _$SexualActivityParticipantCopyWithImpl<SexualActivityParticipant>(this as SexualActivityParticipant, _$identity);

  /// Serializes this SexualActivityParticipant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SexualActivityParticipant&&(identical(other.participant, participant) || other.participant == participant)&&const DeepCollectionEquality().equals(other.activityCounts, activityCounts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,participant,const DeepCollectionEquality().hash(activityCounts));

@override
String toString() {
  return 'SexualActivityParticipant(participant: $participant, activityCounts: $activityCounts)';
}


}

/// @nodoc
abstract mixin class $SexualActivityParticipantCopyWith<$Res>  {
  factory $SexualActivityParticipantCopyWith(SexualActivityParticipant value, $Res Function(SexualActivityParticipant) _then) = _$SexualActivityParticipantCopyWithImpl;
@useResult
$Res call({
 Reference participant, List<ActivityCount> activityCounts
});


$ReferenceCopyWith<$Res> get participant;

}
/// @nodoc
class _$SexualActivityParticipantCopyWithImpl<$Res>
    implements $SexualActivityParticipantCopyWith<$Res> {
  _$SexualActivityParticipantCopyWithImpl(this._self, this._then);

  final SexualActivityParticipant _self;
  final $Res Function(SexualActivityParticipant) _then;

/// Create a copy of SexualActivityParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? participant = null,Object? activityCounts = null,}) {
  return _then(_self.copyWith(
participant: null == participant ? _self.participant : participant // ignore: cast_nullable_to_non_nullable
as Reference,activityCounts: null == activityCounts ? _self.activityCounts : activityCounts // ignore: cast_nullable_to_non_nullable
as List<ActivityCount>,
  ));
}
/// Create a copy of SexualActivityParticipant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res> get participant {
  
  return $ReferenceCopyWith<$Res>(_self.participant, (value) {
    return _then(_self.copyWith(participant: value));
  });
}
}


/// Adds pattern-matching-related methods to [SexualActivityParticipant].
extension SexualActivityParticipantPatterns on SexualActivityParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SexualActivityParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SexualActivityParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SexualActivityParticipant value)  $default,){
final _that = this;
switch (_that) {
case _SexualActivityParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SexualActivityParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _SexualActivityParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Reference participant,  List<ActivityCount> activityCounts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SexualActivityParticipant() when $default != null:
return $default(_that.participant,_that.activityCounts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Reference participant,  List<ActivityCount> activityCounts)  $default,) {final _that = this;
switch (_that) {
case _SexualActivityParticipant():
return $default(_that.participant,_that.activityCounts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Reference participant,  List<ActivityCount> activityCounts)?  $default,) {final _that = this;
switch (_that) {
case _SexualActivityParticipant() when $default != null:
return $default(_that.participant,_that.activityCounts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SexualActivityParticipant extends SexualActivityParticipant {
  const _SexualActivityParticipant({this.participant = const Reference(), final  List<ActivityCount> activityCounts = const []}): _activityCounts = activityCounts,super._();
  factory _SexualActivityParticipant.fromJson(Map<String, dynamic> json) => _$SexualActivityParticipantFromJson(json);

@override@JsonKey() final  Reference participant;
 final  List<ActivityCount> _activityCounts;
@override@JsonKey() List<ActivityCount> get activityCounts {
  if (_activityCounts is EqualUnmodifiableListView) return _activityCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activityCounts);
}


/// Create a copy of SexualActivityParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SexualActivityParticipantCopyWith<_SexualActivityParticipant> get copyWith => __$SexualActivityParticipantCopyWithImpl<_SexualActivityParticipant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SexualActivityParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SexualActivityParticipant&&(identical(other.participant, participant) || other.participant == participant)&&const DeepCollectionEquality().equals(other._activityCounts, _activityCounts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,participant,const DeepCollectionEquality().hash(_activityCounts));

@override
String toString() {
  return 'SexualActivityParticipant(participant: $participant, activityCounts: $activityCounts)';
}


}

/// @nodoc
abstract mixin class _$SexualActivityParticipantCopyWith<$Res> implements $SexualActivityParticipantCopyWith<$Res> {
  factory _$SexualActivityParticipantCopyWith(_SexualActivityParticipant value, $Res Function(_SexualActivityParticipant) _then) = __$SexualActivityParticipantCopyWithImpl;
@override @useResult
$Res call({
 Reference participant, List<ActivityCount> activityCounts
});


@override $ReferenceCopyWith<$Res> get participant;

}
/// @nodoc
class __$SexualActivityParticipantCopyWithImpl<$Res>
    implements _$SexualActivityParticipantCopyWith<$Res> {
  __$SexualActivityParticipantCopyWithImpl(this._self, this._then);

  final _SexualActivityParticipant _self;
  final $Res Function(_SexualActivityParticipant) _then;

/// Create a copy of SexualActivityParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? participant = null,Object? activityCounts = null,}) {
  return _then(_SexualActivityParticipant(
participant: null == participant ? _self.participant : participant // ignore: cast_nullable_to_non_nullable
as Reference,activityCounts: null == activityCounts ? _self._activityCounts : activityCounts // ignore: cast_nullable_to_non_nullable
as List<ActivityCount>,
  ));
}

/// Create a copy of SexualActivityParticipant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res> get participant {
  
  return $ReferenceCopyWith<$Res>(_self.participant, (value) {
    return _then(_self.copyWith(participant: value));
  });
}
}

// dart format on
