import 'package:sqflite/sqflite.dart';
import '../../domain/repositories/sexual_event_repository.dart';
import '../../domain/adapters/sexual_event_adapter.dart';
import '../../domain/database/models/event.dart' as dbEvent;
import '../../domain/database/models/sexual_activity.dart' as dbAct;
import '../../domain/database/models/sexual_activity_type.dart' as dbActType;
import '../../domain/database/models/person.dart' as dbPerson;
import '../../domain/database/models/location.dart' as dbLocation;
import '../../domain/database/models/enums.dart' as dbEnums;
import '../../domain/database/models/address.dart' as dbAddress;
import '../../domain/database/models/coordinate.dart' as dbCoordinate;
import '../../data/models/sexual_event.dart';
import '../../domain/database/database_engine.dart';

class SexualEventRepositoryImpl implements SexualEventRepository {
  final Database _db;

  SexualEventRepositoryImpl._(this._db);

  static Future<SexualEventRepository> create() async {
    final db = await DatabaseEngine.buildLocalConnection();
    return SexualEventRepositoryImpl._(db);
  }

  @override
  Future<SexualEvent?> getById(int id) async {
    final eventRows = await _db.query(
      'event',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (eventRows.isEmpty) return null;
    final dbEvt = dbEvent.Event.fromMap(eventRows.first);
    if (dbEvt.eventType != dbEnums.EventType.sexual) return null;

    final locRows = await _db.query(
      'location',
      where: 'id = ?',
      whereArgs: [dbEvt.locationId],
      limit: 1,
    );
    final loc = dbLocation.Location.fromMap(locRows.first);

    List<Map<String, Object?>>? addressRow;
    List<Map<String, Object?>>? coordinateRow;
    dbAddress.Address? dbAdd;
    dbCoordinate.Coordinate? dbCoord;

    if (loc.addressId != null) {
      addressRow = await _db.rawQuery('''
        SELECT * FROM address WHERE id = ?;
      ''', [loc.addressId]);
      dbAdd = dbAddress.Address.fromMap(addressRow.first);
    }

    if (loc.coordinateId != null) {
      coordinateRow = await _db.rawQuery('''
        SELECT * FROM coordinate WHERE id = ?;
      ''', [loc.coordinateId]);
      dbCoord = dbCoordinate.Coordinate.fromMap(coordinateRow.first);
    }

    final partRows = await _db.rawQuery('''
      SELECT p.* FROM person p
      JOIN event_participant ep ON ep.person_id = p.id
      WHERE ep.event_id = ?
    ''', [id]);

    final participants =
        partRows.map((r) => dbPerson.Person.fromMap(r)).toList();

    final actRows = await _db.rawQuery('''
      SELECT * FROM sexual_activity sa WHERE sa.event_id = ?
    ''', [id]);

    final activities =
        actRows.map((r) => dbAct.SexualActivity.fromMap(r)).toList();

    final actTypeRows = await _db.rawQuery('''
      SELECT * FROM sexual_activity_type WHERE id IN (?)
    ''', activities.map((activity) => activity.activityId).toList());

    final actTypes = actTypeRows
        .map((r) => dbActType.SexualActivityType.fromMap(r))
        .toList();

    return SexualEventAdapter.toDomain(
      event: dbEvt,
      participants: participants,
      activities: activities,
      activityTypes: actTypes,
      location: loc,
      address: dbAdd,
      coordinate: dbCoord,
    );
  }

  @override
  Future<List<SexualEvent>> getByDate(DateTime date) async {
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
      final id = await _db.insert('event', dbEvt.toMap());
      return id;
    } else {
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
    await _db.delete('sexual_activity', where: 'event_id = ?', whereArgs: [id]);
    await _db
        .delete('event_participant', where: 'event_id = ?', whereArgs: [id]);
    await _db.delete('event', where: 'id = ?', whereArgs: [id]);
  }
}
