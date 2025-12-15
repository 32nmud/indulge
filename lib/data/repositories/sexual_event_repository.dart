import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:indulge/data/models.dart';
import '../../domain/database/database_engine.dart';
import 'package:logging/logging.dart';

class SexualEventRepository {
  final Database _db;
  final Logger _logger = Logger('SexualEventRepository');

  SexualEventRepository._(this._db);

  static Future<SexualEventRepository> create() async {
    final db = await DatabaseEngine.buildLocalConnection();
    return SexualEventRepository._(db);
  }

  Future<SexualEvent?> getById(String id) async {
    _logger.info('Getting sexual event by id: $id');

    final eventRows = await _db.query(
      'sexual_event',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (eventRows.isEmpty) return null;
    return SexualEvent.fromJson(
      jsonDecode(eventRows.first["json"] as String) as Map<String, dynamic>,
    );
  }

  Future<List<SexualEvent>> getByDate(DateTime date) async {
    _logger.info('Getting sexual events by date: $date');

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final rows = await _db.query(
      'sexual_event',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );

    final events = <SexualEvent>[];
    for (final row in rows) {
      events.add(
        SexualEvent.fromJson(
          jsonDecode(row["json"] as String) as Map<String, dynamic>,
        ),
      );
    }
    return events;
  }

  Future<Map<DateTime, int>> getDailyEventCount() async {
    _logger.info('Getting daily event count');

    final String sql = '''
      SELECT date, COUNT(id) AS count FROM sexual_event GROUP BY date;
    ''';
    final List<Map<String, Object?>> results = await _db.rawQuery(sql);
    Map<DateTime, int> normalizedResults = Map();
    for (final row in results) {
      DateTime? date = DateTime.tryParse(row['date'] as String? ?? '');
      int? count = row['count'] as int? ?? 0;
      if (date != null && count != 0) {
        date = DateTime(date.year, date.month, date.day);
        normalizedResults.addAll({date: count});
      }
    }

    return normalizedResults;
  }

  Future<List<Person>> getPersonsFromActivity(SexualActivity activity) async {
    _logger.info('Getting persons from activity: $activity');

    List<String> personIds = [];
    for (SexualActivityParticipant participant in activity.participants) {
      if (participant.participant.resourceType == "Person") {
        personIds.add(participant.participant.reference);
      }
    }
    personIds = personIds.toSet().toList();

    if (personIds.isEmpty) return [];

    final placeholders = List.filled(personIds.length, '?').join(',');

    final rows = await _db.query(
      'person',
      where: 'id IN ($placeholders)',
      whereArgs: personIds,
    );

    final List<Person> persons = [];
    for (final row in rows) {
      persons.add(
        Person.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
      );
    }

    return persons;
  }

  Future<List<Person>> getPersonsFromActivities(
    List<SexualActivity> activities,
  ) async {
    _logger.info('Getting persons from activities: $activities');

    List<String> personIds = [];
    for (SexualActivity a in activities) {
      for (SexualActivityParticipant participant in a.participants) {
        if (participant.participant.resourceType == "Person") {
          personIds.add(participant.participant.reference);
        }
      }
    }
    personIds = personIds.toSet().toList();

    if (personIds.isEmpty) return [];

    final placeholders = List.filled(personIds.length, '?').join(',');

    final rows = await _db.query(
      'person',
      where: 'id IN ($placeholders)',
      whereArgs: personIds,
    );

    final List<Person> persons = [];
    for (final row in rows) {
      persons.add(
        Person.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
      );
    }

    return persons;
  }

  Future<List<SexualActivityType>> getSexualActivityTypesByIds(
    List<String> ids,
  ) async {
    _logger.info('Getting sexual activity types by ids: $ids');

    if (ids.isEmpty) return [];
    ids = ids.toSet().toList();

    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db.query(
      'sexual_activity_type',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    final List<SexualActivityType> types = [];
    for (final row in rows) {
      types.add(
        SexualActivityType.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
      );
    }

    return types;
  }

  Future<void> save(SexualEvent event) async {
    _logger.info('Saving sexual event: ${event.id}');

    await _db.insert('sexual_event', {
      'id': event.id,
      'date': event.date.toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
      'json': jsonEncode(event.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteById(String id) async {
    _logger.info('Deleting sexual event: $id');

    await _db.delete('sexual_event', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SexualActivityTypeProperty>>
  getSexualActivityTypePropertiesForParticipant(
    SexualActivityParticipant participant,
  ) async {
    _logger.info(
      'Getting sexual activity type properties for participant: ${participant.participant.reference}',
    );

    if (participant.propertyReferences.isEmpty) return [];

    final List<SexualActivityTypeProperty> properties = [];
    for (Reference reference in participant.propertyReferences) {
      final rows = await _db.query(
        'sexual_activity_type_property',
        where: 'id = ?',
        whereArgs: [reference.reference],
      );

      for (final row in rows) {
        properties.add(
          SexualActivityTypeProperty.fromJson(
            jsonDecode(row['json'] as String) as Map<String, dynamic>,
          ),
        );
      }
    }

    return properties;
  }
}
