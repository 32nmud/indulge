import 'package:sqflite/sqflite.dart';
import 'package:meta/meta.dart';
import '../../domain/repositories/sexual_event_repository.dart';
import '../../domain/adapters/sexual_event_adapter.dart';
import '../../domain/database/models/event.dart' as dbEvent;
import '../../domain/database/models/sexual_activity.dart' as dbAct;
import '../../domain/database/models/sexual_activity_type.dart' as dbActType;
import '../../domain/database/models/person.dart' as dbPerson;
import '../../domain/database/models/location.dart' as dbLocation;
import '../../domain/database/models/enums.dart' as dbEnum;
import '../../data/models/sexual_event.dart';

/// Concrete implementation of [SexualEventRepository] that talks
/// directly to SQLite.  It uses the adapters to translate between
/// the database row objects and the UI‑centric DTOs.
class SexualEventRepositoryImpl implements SexualEventRepository {
  final Database _db;

  SexualEventRepositoryImpl(this._db);

  @override
  Future<SexualEvent?> getById(int id) async {
    // 1. Load the base event row
    final eventRows = await _db.query(
      'event',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (eventRows.isEmpty) return null;
    final dbEvt = dbEvent.Event.fromMap(eventRows.first);

    // 2. Load related data
    final locRows = await _db.query(
      'location',
      where: 'id = ?',
      whereArgs: [dbEvt.locationId],
      limit: 1,
    );
    final loc = dbLocation.Location.fromMap(locRows.first);

    final partRows = await _db.rawQuery('''
      SELECT p.* FROM person p
      JOIN event_participant ep ON ep.person_id = p.id
      WHERE ep.event_id = ?
    ''', [id]);

    final participants =
        partRows.map((r) => dbPerson.Person.fromMap(r)).toList();

    final actRows = await _db.rawQuery('''
      SELECT sa.*, sat.* FROM sexual_activity sa
      JOIN sexual_activity_type sat ON sa.activity_id = sat.id
      WHERE sa.event_id = ?
    ''', [id]);

    final activities =
        actRows.map((r) => dbAct.SexualActivity.fromMap(r)).toList();
    final actTypes =
        actRows.map((r) => dbActType.SexualActivityType.fromMap(r)).toList();

    // 3. Build the domain DTO
    return SexualEventAdapter.toDomain(
      event: dbEvt,
      loc: loc,
      participants: participants,
      activities: activities,
      activityTypes: actTypes,
    );
  }

  @override
  Future<List<SexualEvent>> getByDate(DateTime date) async {
    // Keep the time component out of the comparison.
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final rows = await _db.query(
      'event',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );

    final events = <SexualEvent>[];
    for (final row in rows) {
      final evt = await getById(row['id'] as int);
      if (evt != null) events.add(evt);
    }
    return events;
  }

  @override
  Future<int> save(SexualEvent event) async {
    final dbEvt = SexualEventAdapter.toDatabase(event);

    if (event.baseEventId == null) {
      // Insert new event
      final id = await _db.insert('event', dbEvt.toMap());
      return id;
    } else {
      // Update existing event
      await _db.update(
        'event',
        dbEvt.toMap(),
        where: 'id = ?',
        whereArgs: [event.baseEventId],
      );
      return event.baseEventId!;
    }
  }

  @override
  Future<void> delete(int id) async {
    // Remove dependent rows first
    await _db.delete('sexual_activity', where: 'event_id = ?', whereArgs: [id]);
    await _db
        .delete('event_participant', where: 'event_id = ?', whereArgs: [id]);
    await _db.delete('event', where: 'id = ?', whereArgs: [id]);
  }
}
