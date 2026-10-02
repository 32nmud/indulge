// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sexual_activity_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SexualActivityCategory {

 String get id; DateTime? get lastUpdateDate; String get name; String? get displayCharacter; int get minParticipants; int get maxParticipants; List<SexualActivity> get activities; bool get requiresPartner; int get sortOrder; List<Reference> get subCategories;
/// Create a copy of SexualActivityCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SexualActivityCategoryCopyWith<SexualActivityCategory> get copyWith => _$SexualActivityCategoryCopyWithImpl<SexualActivityCategory>(this as SexualActivityCategory, _$identity);

  /// Serializes this SexualActivityCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SexualActivityCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.lastUpdateDate, lastUpdateDate) || other.lastUpdateDate == lastUpdateDate)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayCharacter, displayCharacter) || other.displayCharacter == displayCharacter)&&(identical(other.minParticipants, minParticipants) || other.minParticipants == minParticipants)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&const DeepCollectionEquality().equals(other.activities, activities)&&(identical(other.requiresPartner, requiresPartner) || other.requiresPartner == requiresPartner)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other.subCategories, subCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lastUpdateDate,name,displayCharacter,minParticipants,maxParticipants,const DeepCollectionEquality().hash(activities),requiresPartner,sortOrder,const DeepCollectionEquality().hash(subCategories));

@override
String toString() {
  return 'SexualActivityCategory(id: $id, lastUpdateDate: $lastUpdateDate, name: $name, displayCharacter: $displayCharacter, minParticipants: $minParticipants, maxParticipants: $maxParticipants, activities: $activities, requiresPartner: $requiresPartner, sortOrder: $sortOrder, subCategories: $subCategories)';
}


}

/// @nodoc
abstract mixin class $SexualActivityCategoryCopyWith<$Res>  {
  factory $SexualActivityCategoryCopyWith(SexualActivityCategory value, $Res Function(SexualActivityCategory) _then) = _$SexualActivityCategoryCopyWithImpl;
@useResult
$Res call({
 String id, DateTime? lastUpdateDate, String name, String? displayCharacter, int minParticipants, int maxParticipants, List<SexualActivity> activities, bool requiresPartner, int sortOrder, List<Reference> subCategories
});




}
/// @nodoc
class _$SexualActivityCategoryCopyWithImpl<$Res>
    implements $SexualActivityCategoryCopyWith<$Res> {
  _$SexualActivityCategoryCopyWithImpl(this._self, this._then);

  final SexualActivityCategory _self;
  final $Res Function(SexualActivityCategory) _then;

/// Create a copy of SexualActivityCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lastUpdateDate = freezed,Object? name = null,Object? displayCharacter = freezed,Object? minParticipants = null,Object? maxParticipants = null,Object? activities = null,Object? requiresPartner = null,Object? sortOrder = null,Object? subCategories = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lastUpdateDate: freezed == lastUpdateDate ? _self.lastUpdateDate : lastUpdateDate // ignore: cast_nullable_to_non_nullable
as DateTime?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayCharacter: freezed == displayCharacter ? _self.displayCharacter : displayCharacter // ignore: cast_nullable_to_non_nullable
as String?,minParticipants: null == minParticipants ? _self.minParticipants : minParticipants // ignore: cast_nullable_to_non_nullable
as int,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,activities: null == activities ? _self.activities : activities // ignore: cast_nullable_to_non_nullable
as List<SexualActivity>,requiresPartner: null == requiresPartner ? _self.requiresPartner : requiresPartner // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,subCategories: null == subCategories ? _self.subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<Reference>,
  ));
}

}


/// Adds pattern-matching-related methods to [SexualActivityCategory].
extension SexualActivityCategoryPatterns on SexualActivityCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SexualActivityCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SexualActivityCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SexualActivityCategory value)  $default,){
final _that = this;
switch (_that) {
case _SexualActivityCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SexualActivityCategory value)?  $default,){
final _that = this;
switch (_that) {
case _SexualActivityCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime? lastUpdateDate,  String name,  String? displayCharacter,  int minParticipants,  int maxParticipants,  List<SexualActivity> activities,  bool requiresPartner,  int sortOrder,  List<Reference> subCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SexualActivityCategory() when $default != null:
return $default(_that.id,_that.lastUpdateDate,_that.name,_that.displayCharacter,_that.minParticipants,_that.maxParticipants,_that.activities,_that.requiresPartner,_that.sortOrder,_that.subCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime? lastUpdateDate,  String name,  String? displayCharacter,  int minParticipants,  int maxParticipants,  List<SexualActivity> activities,  bool requiresPartner,  int sortOrder,  List<Reference> subCategories)  $default,) {final _that = this;
switch (_that) {
case _SexualActivityCategory():
return $default(_that.id,_that.lastUpdateDate,_that.name,_that.displayCharacter,_that.minParticipants,_that.maxParticipants,_that.activities,_that.requiresPartner,_that.sortOrder,_that.subCategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime? lastUpdateDate,  String name,  String? displayCharacter,  int minParticipants,  int maxParticipants,  List<SexualActivity> activities,  bool requiresPartner,  int sortOrder,  List<Reference> subCategories)?  $default,) {final _that = this;
switch (_that) {
case _SexualActivityCategory() when $default != null:
return $default(_that.id,_that.lastUpdateDate,_that.name,_that.displayCharacter,_that.minParticipants,_that.maxParticipants,_that.activities,_that.requiresPartner,_that.sortOrder,_that.subCategories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SexualActivityCategory extends SexualActivityCategory {
  const _SexualActivityCategory({this.id = "", this.lastUpdateDate, required this.name, this.displayCharacter, this.minParticipants = -1, this.maxParticipants = -1, final  List<SexualActivity> activities = const [], this.requiresPartner = false, this.sortOrder = 0, final  List<Reference> subCategories = const []}): _activities = activities,_subCategories = subCategories,super._();
  factory _SexualActivityCategory.fromJson(Map<String, dynamic> json) => _$SexualActivityCategoryFromJson(json);

@override@JsonKey() final  String id;
@override final  DateTime? lastUpdateDate;
@override final  String name;
@override final  String? displayCharacter;
@override@JsonKey() final  int minParticipants;
@override@JsonKey() final  int maxParticipants;
 final  List<SexualActivity> _activities;
@override@JsonKey() List<SexualActivity> get activities {
  if (_activities is EqualUnmodifiableListView) return _activities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activities);
}

@override@JsonKey() final  bool requiresPartner;
@override@JsonKey() final  int sortOrder;
 final  List<Reference> _subCategories;
@override@JsonKey() List<Reference> get subCategories {
  if (_subCategories is EqualUnmodifiableListView) return _subCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subCategories);
}


/// Create a copy of SexualActivityCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SexualActivityCategoryCopyWith<_SexualActivityCategory> get copyWith => __$SexualActivityCategoryCopyWithImpl<_SexualActivityCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SexualActivityCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SexualActivityCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.lastUpdateDate, lastUpdateDate) || other.lastUpdateDate == lastUpdateDate)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayCharacter, displayCharacter) || other.displayCharacter == displayCharacter)&&(identical(other.minParticipants, minParticipants) || other.minParticipants == minParticipants)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&const DeepCollectionEquality().equals(other._activities, _activities)&&(identical(other.requiresPartner, requiresPartner) || other.requiresPartner == requiresPartner)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other._subCategories, _subCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lastUpdateDate,name,displayCharacter,minParticipants,maxParticipants,const DeepCollectionEquality().hash(_activities),requiresPartner,sortOrder,const DeepCollectionEquality().hash(_subCategories));

@override
String toString() {
  return 'SexualActivityCategory(id: $id, lastUpdateDate: $lastUpdateDate, name: $name, displayCharacter: $displayCharacter, minParticipants: $minParticipants, maxParticipants: $maxParticipants, activities: $activities, requiresPartner: $requiresPartner, sortOrder: $sortOrder, subCategories: $subCategories)';
}


}

/// @nodoc
abstract mixin class _$SexualActivityCategoryCopyWith<$Res> implements $SexualActivityCategoryCopyWith<$Res> {
  factory _$SexualActivityCategoryCopyWith(_SexualActivityCategory value, $Res Function(_SexualActivityCategory) _then) = __$SexualActivityCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime? lastUpdateDate, String name, String? displayCharacter, int minParticipants, int maxParticipants, List<SexualActivity> activities, bool requiresPartner, int sortOrder, List<Reference> subCategories
});




}
/// @nodoc
class __$SexualActivityCategoryCopyWithImpl<$Res>
    implements _$SexualActivityCategoryCopyWith<$Res> {
  __$SexualActivityCategoryCopyWithImpl(this._self, this._then);

  final _SexualActivityCategory _self;
  final $Res Function(_SexualActivityCategory) _then;

/// Create a copy of SexualActivityCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lastUpdateDate = freezed,Object? name = null,Object? displayCharacter = freezed,Object? minParticipants = null,Object? maxParticipants = null,Object? activities = null,Object? requiresPartner = null,Object? sortOrder = null,Object? subCategories = null,}) {
  return _then(_SexualActivityCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lastUpdateDate: freezed == lastUpdateDate ? _self.lastUpdateDate : lastUpdateDate // ignore: cast_nullable_to_non_nullable
as DateTime?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayCharacter: freezed == displayCharacter ? _self.displayCharacter : displayCharacter // ignore: cast_nullable_to_non_nullable
as String?,minParticipants: null == minParticipants ? _self.minParticipants : minParticipants // ignore: cast_nullable_to_non_nullable
as int,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,activities: null == activities ? _self._activities : activities // ignore: cast_nullable_to_non_nullable
as List<SexualActivity>,requiresPartner: null == requiresPartner ? _self.requiresPartner : requiresPartner // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,subCategories: null == subCategories ? _self._subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<Reference>,
  ));
}


}

// dart format on
