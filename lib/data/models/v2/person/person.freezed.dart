// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'person.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Person {

 String get id; DateTime get date; DateTime? get lastUpdateDate; Name get name; Reference? get location; DateTime? get birthday; bool get isSelf;// Body info
 String? get bodyType;// bear, twink, otter, butch, doll, etc
 String? get endowment; String? get cutStatus;// cut/uncut
 String? get breastSize; String? get assignedSexAtBirth;// AMAB/AFAB
 String? get height;// Soft/personal info
 String? get gender; String? get hivStatus; String? get herpesStatus; String? get pronouns;// Other
 List<String> get socialLinks;// links to socials/other contacts
 String? get notes;// free notes section
 String? get imageBytes;
/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonCopyWith<Person> get copyWith => _$PersonCopyWithImpl<Person>(this as Person, _$identity);

  /// Serializes this Person to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Person&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.lastUpdateDate, lastUpdateDate) || other.lastUpdateDate == lastUpdateDate)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.isSelf, isSelf) || other.isSelf == isSelf)&&(identical(other.bodyType, bodyType) || other.bodyType == bodyType)&&(identical(other.endowment, endowment) || other.endowment == endowment)&&(identical(other.cutStatus, cutStatus) || other.cutStatus == cutStatus)&&(identical(other.breastSize, breastSize) || other.breastSize == breastSize)&&(identical(other.assignedSexAtBirth, assignedSexAtBirth) || other.assignedSexAtBirth == assignedSexAtBirth)&&(identical(other.height, height) || other.height == height)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.hivStatus, hivStatus) || other.hivStatus == hivStatus)&&(identical(other.herpesStatus, herpesStatus) || other.herpesStatus == herpesStatus)&&(identical(other.pronouns, pronouns) || other.pronouns == pronouns)&&const DeepCollectionEquality().equals(other.socialLinks, socialLinks)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.imageBytes, imageBytes) || other.imageBytes == imageBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,date,lastUpdateDate,name,location,birthday,isSelf,bodyType,endowment,cutStatus,breastSize,assignedSexAtBirth,height,gender,hivStatus,herpesStatus,pronouns,const DeepCollectionEquality().hash(socialLinks),notes,imageBytes]);

@override
String toString() {
  return 'Person(id: $id, date: $date, lastUpdateDate: $lastUpdateDate, name: $name, location: $location, birthday: $birthday, isSelf: $isSelf, bodyType: $bodyType, endowment: $endowment, cutStatus: $cutStatus, breastSize: $breastSize, assignedSexAtBirth: $assignedSexAtBirth, height: $height, gender: $gender, hivStatus: $hivStatus, herpesStatus: $herpesStatus, pronouns: $pronouns, socialLinks: $socialLinks, notes: $notes, imageBytes: $imageBytes)';
}


}

/// @nodoc
abstract mixin class $PersonCopyWith<$Res>  {
  factory $PersonCopyWith(Person value, $Res Function(Person) _then) = _$PersonCopyWithImpl;
@useResult
$Res call({
 String id, DateTime date, DateTime? lastUpdateDate, Name name, Reference? location, DateTime? birthday, bool isSelf, String? bodyType, String? endowment, String? cutStatus, String? breastSize, String? assignedSexAtBirth, String? height, String? gender, String? hivStatus, String? herpesStatus, String? pronouns, List<String> socialLinks, String? notes, String? imageBytes
});


$NameCopyWith<$Res> get name;$ReferenceCopyWith<$Res>? get location;

}
/// @nodoc
class _$PersonCopyWithImpl<$Res>
    implements $PersonCopyWith<$Res> {
  _$PersonCopyWithImpl(this._self, this._then);

  final Person _self;
  final $Res Function(Person) _then;

/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? lastUpdateDate = freezed,Object? name = null,Object? location = freezed,Object? birthday = freezed,Object? isSelf = null,Object? bodyType = freezed,Object? endowment = freezed,Object? cutStatus = freezed,Object? breastSize = freezed,Object? assignedSexAtBirth = freezed,Object? height = freezed,Object? gender = freezed,Object? hivStatus = freezed,Object? herpesStatus = freezed,Object? pronouns = freezed,Object? socialLinks = null,Object? notes = freezed,Object? imageBytes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,lastUpdateDate: freezed == lastUpdateDate ? _self.lastUpdateDate : lastUpdateDate // ignore: cast_nullable_to_non_nullable
as DateTime?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Name,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Reference?,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,isSelf: null == isSelf ? _self.isSelf : isSelf // ignore: cast_nullable_to_non_nullable
as bool,bodyType: freezed == bodyType ? _self.bodyType : bodyType // ignore: cast_nullable_to_non_nullable
as String?,endowment: freezed == endowment ? _self.endowment : endowment // ignore: cast_nullable_to_non_nullable
as String?,cutStatus: freezed == cutStatus ? _self.cutStatus : cutStatus // ignore: cast_nullable_to_non_nullable
as String?,breastSize: freezed == breastSize ? _self.breastSize : breastSize // ignore: cast_nullable_to_non_nullable
as String?,assignedSexAtBirth: freezed == assignedSexAtBirth ? _self.assignedSexAtBirth : assignedSexAtBirth // ignore: cast_nullable_to_non_nullable
as String?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,hivStatus: freezed == hivStatus ? _self.hivStatus : hivStatus // ignore: cast_nullable_to_non_nullable
as String?,herpesStatus: freezed == herpesStatus ? _self.herpesStatus : herpesStatus // ignore: cast_nullable_to_non_nullable
as String?,pronouns: freezed == pronouns ? _self.pronouns : pronouns // ignore: cast_nullable_to_non_nullable
as String?,socialLinks: null == socialLinks ? _self.socialLinks : socialLinks // ignore: cast_nullable_to_non_nullable
as List<String>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,imageBytes: freezed == imageBytes ? _self.imageBytes : imageBytes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NameCopyWith<$Res> get name {
  
  return $NameCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $ReferenceCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [Person].
extension PersonPatterns on Person {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Person value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Person() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Person value)  $default,){
final _that = this;
switch (_that) {
case _Person():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Person value)?  $default,){
final _that = this;
switch (_that) {
case _Person() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime date,  DateTime? lastUpdateDate,  Name name,  Reference? location,  DateTime? birthday,  bool isSelf,  String? bodyType,  String? endowment,  String? cutStatus,  String? breastSize,  String? assignedSexAtBirth,  String? height,  String? gender,  String? hivStatus,  String? herpesStatus,  String? pronouns,  List<String> socialLinks,  String? notes,  String? imageBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Person() when $default != null:
return $default(_that.id,_that.date,_that.lastUpdateDate,_that.name,_that.location,_that.birthday,_that.isSelf,_that.bodyType,_that.endowment,_that.cutStatus,_that.breastSize,_that.assignedSexAtBirth,_that.height,_that.gender,_that.hivStatus,_that.herpesStatus,_that.pronouns,_that.socialLinks,_that.notes,_that.imageBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime date,  DateTime? lastUpdateDate,  Name name,  Reference? location,  DateTime? birthday,  bool isSelf,  String? bodyType,  String? endowment,  String? cutStatus,  String? breastSize,  String? assignedSexAtBirth,  String? height,  String? gender,  String? hivStatus,  String? herpesStatus,  String? pronouns,  List<String> socialLinks,  String? notes,  String? imageBytes)  $default,) {final _that = this;
switch (_that) {
case _Person():
return $default(_that.id,_that.date,_that.lastUpdateDate,_that.name,_that.location,_that.birthday,_that.isSelf,_that.bodyType,_that.endowment,_that.cutStatus,_that.breastSize,_that.assignedSexAtBirth,_that.height,_that.gender,_that.hivStatus,_that.herpesStatus,_that.pronouns,_that.socialLinks,_that.notes,_that.imageBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime date,  DateTime? lastUpdateDate,  Name name,  Reference? location,  DateTime? birthday,  bool isSelf,  String? bodyType,  String? endowment,  String? cutStatus,  String? breastSize,  String? assignedSexAtBirth,  String? height,  String? gender,  String? hivStatus,  String? herpesStatus,  String? pronouns,  List<String> socialLinks,  String? notes,  String? imageBytes)?  $default,) {final _that = this;
switch (_that) {
case _Person() when $default != null:
return $default(_that.id,_that.date,_that.lastUpdateDate,_that.name,_that.location,_that.birthday,_that.isSelf,_that.bodyType,_that.endowment,_that.cutStatus,_that.breastSize,_that.assignedSexAtBirth,_that.height,_that.gender,_that.hivStatus,_that.herpesStatus,_that.pronouns,_that.socialLinks,_that.notes,_that.imageBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Person extends Person {
  const _Person({this.id = "", required this.date, this.lastUpdateDate, required this.name, this.location, this.birthday, this.isSelf = false, this.bodyType, this.endowment, this.cutStatus, this.breastSize, this.assignedSexAtBirth, this.height, this.gender, this.hivStatus, this.herpesStatus, this.pronouns, final  List<String> socialLinks = const [], this.notes, this.imageBytes}): _socialLinks = socialLinks,super._();
  factory _Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

@override@JsonKey() final  String id;
@override final  DateTime date;
@override final  DateTime? lastUpdateDate;
@override final  Name name;
@override final  Reference? location;
@override final  DateTime? birthday;
@override@JsonKey() final  bool isSelf;
// Body info
@override final  String? bodyType;
// bear, twink, otter, butch, doll, etc
@override final  String? endowment;
@override final  String? cutStatus;
// cut/uncut
@override final  String? breastSize;
@override final  String? assignedSexAtBirth;
// AMAB/AFAB
@override final  String? height;
// Soft/personal info
@override final  String? gender;
@override final  String? hivStatus;
@override final  String? herpesStatus;
@override final  String? pronouns;
// Other
 final  List<String> _socialLinks;
// Other
@override@JsonKey() List<String> get socialLinks {
  if (_socialLinks is EqualUnmodifiableListView) return _socialLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_socialLinks);
}

// links to socials/other contacts
@override final  String? notes;
// free notes section
@override final  String? imageBytes;

/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonCopyWith<_Person> get copyWith => __$PersonCopyWithImpl<_Person>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Person&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.lastUpdateDate, lastUpdateDate) || other.lastUpdateDate == lastUpdateDate)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.isSelf, isSelf) || other.isSelf == isSelf)&&(identical(other.bodyType, bodyType) || other.bodyType == bodyType)&&(identical(other.endowment, endowment) || other.endowment == endowment)&&(identical(other.cutStatus, cutStatus) || other.cutStatus == cutStatus)&&(identical(other.breastSize, breastSize) || other.breastSize == breastSize)&&(identical(other.assignedSexAtBirth, assignedSexAtBirth) || other.assignedSexAtBirth == assignedSexAtBirth)&&(identical(other.height, height) || other.height == height)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.hivStatus, hivStatus) || other.hivStatus == hivStatus)&&(identical(other.herpesStatus, herpesStatus) || other.herpesStatus == herpesStatus)&&(identical(other.pronouns, pronouns) || other.pronouns == pronouns)&&const DeepCollectionEquality().equals(other._socialLinks, _socialLinks)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.imageBytes, imageBytes) || other.imageBytes == imageBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,date,lastUpdateDate,name,location,birthday,isSelf,bodyType,endowment,cutStatus,breastSize,assignedSexAtBirth,height,gender,hivStatus,herpesStatus,pronouns,const DeepCollectionEquality().hash(_socialLinks),notes,imageBytes]);

@override
String toString() {
  return 'Person(id: $id, date: $date, lastUpdateDate: $lastUpdateDate, name: $name, location: $location, birthday: $birthday, isSelf: $isSelf, bodyType: $bodyType, endowment: $endowment, cutStatus: $cutStatus, breastSize: $breastSize, assignedSexAtBirth: $assignedSexAtBirth, height: $height, gender: $gender, hivStatus: $hivStatus, herpesStatus: $herpesStatus, pronouns: $pronouns, socialLinks: $socialLinks, notes: $notes, imageBytes: $imageBytes)';
}


}

/// @nodoc
abstract mixin class _$PersonCopyWith<$Res> implements $PersonCopyWith<$Res> {
  factory _$PersonCopyWith(_Person value, $Res Function(_Person) _then) = __$PersonCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime date, DateTime? lastUpdateDate, Name name, Reference? location, DateTime? birthday, bool isSelf, String? bodyType, String? endowment, String? cutStatus, String? breastSize, String? assignedSexAtBirth, String? height, String? gender, String? hivStatus, String? herpesStatus, String? pronouns, List<String> socialLinks, String? notes, String? imageBytes
});


@override $NameCopyWith<$Res> get name;@override $ReferenceCopyWith<$Res>? get location;

}
/// @nodoc
class __$PersonCopyWithImpl<$Res>
    implements _$PersonCopyWith<$Res> {
  __$PersonCopyWithImpl(this._self, this._then);

  final _Person _self;
  final $Res Function(_Person) _then;

/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? lastUpdateDate = freezed,Object? name = null,Object? location = freezed,Object? birthday = freezed,Object? isSelf = null,Object? bodyType = freezed,Object? endowment = freezed,Object? cutStatus = freezed,Object? breastSize = freezed,Object? assignedSexAtBirth = freezed,Object? height = freezed,Object? gender = freezed,Object? hivStatus = freezed,Object? herpesStatus = freezed,Object? pronouns = freezed,Object? socialLinks = null,Object? notes = freezed,Object? imageBytes = freezed,}) {
  return _then(_Person(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,lastUpdateDate: freezed == lastUpdateDate ? _self.lastUpdateDate : lastUpdateDate // ignore: cast_nullable_to_non_nullable
as DateTime?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Name,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Reference?,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,isSelf: null == isSelf ? _self.isSelf : isSelf // ignore: cast_nullable_to_non_nullable
as bool,bodyType: freezed == bodyType ? _self.bodyType : bodyType // ignore: cast_nullable_to_non_nullable
as String?,endowment: freezed == endowment ? _self.endowment : endowment // ignore: cast_nullable_to_non_nullable
as String?,cutStatus: freezed == cutStatus ? _self.cutStatus : cutStatus // ignore: cast_nullable_to_non_nullable
as String?,breastSize: freezed == breastSize ? _self.breastSize : breastSize // ignore: cast_nullable_to_non_nullable
as String?,assignedSexAtBirth: freezed == assignedSexAtBirth ? _self.assignedSexAtBirth : assignedSexAtBirth // ignore: cast_nullable_to_non_nullable
as String?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,hivStatus: freezed == hivStatus ? _self.hivStatus : hivStatus // ignore: cast_nullable_to_non_nullable
as String?,herpesStatus: freezed == herpesStatus ? _self.herpesStatus : herpesStatus // ignore: cast_nullable_to_non_nullable
as String?,pronouns: freezed == pronouns ? _self.pronouns : pronouns // ignore: cast_nullable_to_non_nullable
as String?,socialLinks: null == socialLinks ? _self._socialLinks : socialLinks // ignore: cast_nullable_to_non_nullable
as List<String>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,imageBytes: freezed == imageBytes ? _self.imageBytes : imageBytes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NameCopyWith<$Res> get name {
  
  return $NameCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $ReferenceCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}

// dart format on
