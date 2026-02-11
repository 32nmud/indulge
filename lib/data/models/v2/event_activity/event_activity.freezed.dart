// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventActivity {

 Reference get category; List<ActivityParticipant> get participants;
/// Create a copy of EventActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventActivityCopyWith<EventActivity> get copyWith => _$EventActivityCopyWithImpl<EventActivity>(this as EventActivity, _$identity);

  /// Serializes this EventActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventActivity&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.participants, participants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,const DeepCollectionEquality().hash(participants));

@override
String toString() {
  return 'EventActivity(category: $category, participants: $participants)';
}


}

/// @nodoc
abstract mixin class $EventActivityCopyWith<$Res>  {
  factory $EventActivityCopyWith(EventActivity value, $Res Function(EventActivity) _then) = _$EventActivityCopyWithImpl;
@useResult
$Res call({
 Reference category, List<ActivityParticipant> participants
});


$ReferenceCopyWith<$Res> get category;

}
/// @nodoc
class _$EventActivityCopyWithImpl<$Res>
    implements $EventActivityCopyWith<$Res> {
  _$EventActivityCopyWithImpl(this._self, this._then);

  final EventActivity _self;
  final $Res Function(EventActivity) _then;

/// Create a copy of EventActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? participants = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Reference,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<ActivityParticipant>,
  ));
}
/// Create a copy of EventActivity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res> get category {
  
  return $ReferenceCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [EventActivity].
extension EventActivityPatterns on EventActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventActivity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventActivity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventActivity value)  $default,){
final _that = this;
switch (_that) {
case _EventActivity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventActivity value)?  $default,){
final _that = this;
switch (_that) {
case _EventActivity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Reference category,  List<ActivityParticipant> participants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventActivity() when $default != null:
return $default(_that.category,_that.participants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Reference category,  List<ActivityParticipant> participants)  $default,) {final _that = this;
switch (_that) {
case _EventActivity():
return $default(_that.category,_that.participants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Reference category,  List<ActivityParticipant> participants)?  $default,) {final _that = this;
switch (_that) {
case _EventActivity() when $default != null:
return $default(_that.category,_that.participants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventActivity implements EventActivity {
  const _EventActivity({this.category = const Reference(), final  List<ActivityParticipant> participants = const []}): _participants = participants;
  factory _EventActivity.fromJson(Map<String, dynamic> json) => _$EventActivityFromJson(json);

@override@JsonKey() final  Reference category;
 final  List<ActivityParticipant> _participants;
@override@JsonKey() List<ActivityParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}


/// Create a copy of EventActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventActivityCopyWith<_EventActivity> get copyWith => __$EventActivityCopyWithImpl<_EventActivity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventActivityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventActivity&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._participants, _participants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,const DeepCollectionEquality().hash(_participants));

@override
String toString() {
  return 'EventActivity(category: $category, participants: $participants)';
}


}

/// @nodoc
abstract mixin class _$EventActivityCopyWith<$Res> implements $EventActivityCopyWith<$Res> {
  factory _$EventActivityCopyWith(_EventActivity value, $Res Function(_EventActivity) _then) = __$EventActivityCopyWithImpl;
@override @useResult
$Res call({
 Reference category, List<ActivityParticipant> participants
});


@override $ReferenceCopyWith<$Res> get category;

}
/// @nodoc
class __$EventActivityCopyWithImpl<$Res>
    implements _$EventActivityCopyWith<$Res> {
  __$EventActivityCopyWithImpl(this._self, this._then);

  final _EventActivity _self;
  final $Res Function(_EventActivity) _then;

/// Create a copy of EventActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? participants = null,}) {
  return _then(_EventActivity(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Reference,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<ActivityParticipant>,
  ));
}

/// Create a copy of EventActivity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res> get category {
  
  return $ReferenceCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
