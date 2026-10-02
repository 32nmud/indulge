import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:indulge/data/models/versioned_model.dart';
import '../name/name.dart';
import '../reference/reference.dart';
import 'package:uuid/uuid.dart';

part 'person.freezed.dart';
part 'person.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class Person with _$Person implements VersionedModel {
  const Person._();

  const factory Person({
    @Default("") String id,
    required DateTime date,
    DateTime? lastUpdateDate,
    required Name name,
    Reference? location,
    DateTime? birthday,
    @Default(false) bool isSelf,
    // Body info
    String? bodyType, // bear, twink, otter, butch, doll, etc
    String? endowment,
    String? cutStatus, // cut/uncut
    String? breastSize,
    String? assignedSexAtBirth, // AMAB/AFAB
    String? height,
    // Soft/personal info
    String? gender,
    String? hivStatus,
    String? herpesStatus,
    String? pronouns,
    // Other
    @Default([]) List<String> socialLinks, // links to socials/other contacts
    String? notes, // free notes section
    String? imageBytes, // contact image as base64-encoded byte string
    @Default(1) int version,
  }) = _Person;

  // -----------------------------------------------------------------
  // Custom JSON (de)serialization
  // -----------------------------------------------------------------
  factory Person.fromJson(Map<String, dynamic> json) {
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$PersonFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    // Let the generated helper create the map, then inject the constant.
    final map = _$PersonToJson(this as _Person);
    map['resourceType'] = "Person"; // guarantee the correct value
    return map;
  }

  // -----------------------------------------------------------------
  // Fixed getters
  // -----------------------------------------------------------------
  @JsonKey(name: 'resourceType')
  @override
  String get resourceType => "Person";

  @override
  String get id =>
      (this as _Person).id == "" ? const Uuid().v4() : (this as _Person).id;
}
