import 'package:freezed_annotation/freezed_annotation.dart';
import '../name/name.dart';
import '../reference/reference.dart';
import 'package:uuid/uuid.dart';

part 'person.freezed.dart';
part 'person.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class Person with _$Person {
  const Person._();

  const factory Person({
    @Default("") String id,
    required DateTime date,
    DateTime? lastUpdateDate,
    required Name name,
    Reference? location,
    // HivStatus hivStatus,
    DateTime? birthday,
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
  @override
  @JsonKey(name: 'resourceType')
  String get resourceType => "Person";

  @override
  String get id =>
      (this as _Person).id == "" ? const Uuid().v4() : (this as _Person).id;
}
