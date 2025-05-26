import 'encounter.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class SexualEncounter extends Encounter {
  String id;
  List<String> personIds;

  String? location;
  int? overallEnjoyment;
  String? note;

  SexualEncounter._(super.encounterDate, this.id, this.personIds, this.location,
      this.overallEnjoyment, this.note);

  factory SexualEncounter(
    DateTime encounterDate,
    List<String> personIds,
    String? location,
    int? overallEnjoyment,
    String? note,
  ) {
    const uuid = Uuid();
    return SexualEncounter._(
        encounterDate, uuid.v4(), personIds, location, overallEnjoyment, note);
  }

  factory SexualEncounter.fromMap(Map<String, Object?> map) {
    DateTime encounterDate = DateTime.parse(map["encounterDate"] as String);
    String id = map["id"] as String;
    List<String> personIds = [];
    if (map["personIds"] is String) {
      personIds = List<String>.from(jsonDecode(map["personIds"] as String));
    }
    if (map["personIds"] is! String || personIds.isEmpty) {
      throw "A list of IDs must be supplied!";
    }
    String? location = map["location"] as String?;
    int? overallEnjoyment = map["overallEnjoyment"] as int?;
    String? note = map["note"] as String?;

    return SexualEncounter._(
        encounterDate, id, personIds, location, overallEnjoyment, note);
  }
}
