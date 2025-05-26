import 'package:indulge/models/encounter.dart';
import 'package:indulge/models/sexual_encounter.dart';
import 'package:indulge/util/database_engine.dart';
// import 'package:indulge/models/clinic_encounter.dart';
// import 'package:indulge/models/person.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class DataAccess {
  Database db;
  DataAccess._(this.db);
  static Future<DataAccess> create() async => DataAccess._(await DatabaseEngine.buildLocalConnection());

  Future<List<Encounter>> getEncountersInDateRange(
      DateTime startDate, DateTime endDate) async {
    String startDateStr = DateFormat("yyyy-MM-dd").format(startDate);
    String endDateStr = DateFormat("yyyy-MM-dd").format(endDate);
    List<Map<String, Object?>> queryResults = await db.query("sexual_encounter",
        where: "encounterDate >= ? and encounterDate <= ?",
        whereArgs: [startDateStr, endDateStr]);
    List<Encounter> encounters = [];
    for (var result in queryResults) {
      encounters.add(SexualEncounter.fromMap(result));
    }
    return encounters;
  }

  Future<List<Encounter>> getEncountersForDate(DateTime day) async {
    String dateStr = DateFormat("yyyy-MM-dd").format(day);
    List<Map<String, Object?>> queryResults = await db.query("sexual_encounter",
        where: "encounterDate = ?", whereArgs: [dateStr]);
    List<Encounter> encounters = [];
    for (var result in queryResults) {
      encounters.add(SexualEncounter.fromMap(result));
    }
    return encounters;
  }
}
