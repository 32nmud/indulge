import 'dart:convert';

import 'package:indulge/data/models.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/database/database_engine.dart';

/// Repository that manages persistence for `ClinicalEvent` resources.
///
/// Clinical events are stored as JSON blobs in the `clinical_event` table.
/// The table schema used elsewhere in the project contains at least:
///  - `id` TEXT PRIMARY KEY
///  - `date` TEXT (ISO8601)
///  - `last_modified` TEXT (ISO8601 nullable)
///  - `json` TEXT (the serialized ClinicalEvent)
class ClinicalEventRepository {
  final Database _db;
  final Logger _logger = Logger('ClinicalEventRepository');

  ClinicalEventRepository._(this._db);

  /// Create a repository instance backed by the local DB connection.
  static Future<ClinicalEventRepository> create() async {
    final db = await DatabaseEngine.buildLocalConnection();
    return ClinicalEventRepository._(db);
  }

  /// Save (insert or update) a clinical event.
  Future<void> save(ClinicalEvent event) async {
    _logger.info('Saving clinical event: ${event.id}');
    final jsonStr = jsonEncode(event.toJson());
    await _db.insert('clinical_event', {
      'id': event.id,
      'date': event.date.toIso8601String(),
      'last_modified': event.lastModifiedDate?.toIso8601String(),
      'json': jsonStr,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Delete a clinical event by id.
  Future<void> deleteById(String id) async {
    _logger.info('Deleting clinical event: $id');
    await _db.delete('clinical_event', where: 'id = ?', whereArgs: [id]);
  }

  /// Get a single clinical event by id, or null if not found.
  Future<ClinicalEvent?> getById(String id) async {
    _logger.info('Fetching clinical event by id: $id');
    final rows = await _db.query(
      'clinical_event',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    try {
      final jsonMap =
          jsonDecode(rows.first['json'] as String) as Map<String, dynamic>;
      return ClinicalEvent.fromJson(jsonMap);
    } catch (e, st) {
      _logger.warning(
        'Failed to parse clinical_event JSON for id $id: $e\n$st',
      );
      return null;
    }
  }

  /// Get all clinical events (unsorted order as returned by DB).
  Future<List<ClinicalEvent>> getAllEvents() async {
    _logger.info('Fetching all clinical events');
    final rows = await _db.query('clinical_event');
    final events = <ClinicalEvent>[];
    for (final row in rows) {
      try {
        final jsonMap =
            jsonDecode(row['json'] as String) as Map<String, dynamic>;
        events.add(ClinicalEvent.fromJson(jsonMap));
      } catch (e, st) {
        _logger.warning('Failed to parse clinical_event row: $e\n$st');
      }
    }
    return events;
  }

  /// Get clinical events for a specific date (local day).
  ///
  /// This returns events where `date` is >= start of the provided day and < next day.
  Future<List<ClinicalEvent>> getByDate(DateTime date) async {
    _logger.info('Fetching clinical events for date: $date');
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _db.query(
      'clinical_event',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );

    final events = <ClinicalEvent>[];
    for (final row in rows) {
      try {
        final jsonMap =
            jsonDecode(row['json'] as String) as Map<String, dynamic>;
        events.add(ClinicalEvent.fromJson(jsonMap));
      } catch (e, st) {
        _logger.warning(
          'Failed to parse clinical_event row for date $date: $e\n$st',
        );
      }
    }
    return events;
  }

  /// Returns a map of date-only -> bool indicating whether at least one clinical
  /// event exists for that date within the provided range (inclusive start, exclusive end).
  ///
  /// This is useful for calendar highlighting where presence (not counts) is required.
  Future<Map<DateTime, bool>> getDailyPresence(
    DateTime start,
    DateTime end,
  ) async {
    _logger.info(
      'Getting daily clinical event presence between $start and $end',
    );
    // Use DATE(date) grouping similar to sexual events.
    final String sql = '''
      SELECT DATE(date) AS date_only, COUNT(id) AS count
      FROM clinical_event
      WHERE date >= ? AND date < ?
      GROUP BY DATE(date)
    ''';
    final List<Map<String, Object?>> results = await _db.rawQuery(sql, [
      start.toIso8601String(),
      end.toIso8601String(),
    ]);

    final Map<DateTime, bool> presence = {};
    for (final row in results) {
      final dateStr = row['date_only'] as String? ?? '';
      final count = row['count'] as int? ?? 0;
      if (dateStr.isNotEmpty && count > 0) {
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          final normalized = DateTime(parsed.year, parsed.month, parsed.day);
          presence[normalized] = true;
        }
      }
    }
    return presence;
  }

  /// Finds the most recent date when the given `testType` was performed.
  ///
  /// Returns `null` if there are no tests of that type.
  Future<DateTime?> getLastTestDateFor(TestType testType) async {
    _logger.info('Getting last test date for $testType');

    // Query all events ordered by date descending and scan for the desired test type.
    // This is intentionally conservative and correct; if performance becomes a concern
    // we can add a normalized clinical_test table in a future migration.
    final rows = await _db.query('clinical_event', orderBy: 'date DESC');

    for (final row in rows) {
      try {
        final jsonMap =
            jsonDecode(row['json'] as String) as Map<String, dynamic>;
        final event = ClinicalEvent.fromJson(jsonMap);
        final has = event.tests.any((t) => t.testType == testType);
        if (has) return event.date;
      } catch (e, st) {
        _logger.warning(
          'Error parsing clinical_event row while searching last test date: $e\n$st',
        );
      }
    }
    return null;
  }

  /// Returns the most recent `ClinicalTestResult` per `TestType`.
  ///
  /// The returned map will contain entries only for tests that have at least
  /// one recorded result. If multiple results exist for the same test type,
  /// the most recent (by ClinicalEvent.date) is used.
  Future<Map<TestType, ClinicalTestResult>> getLatestTestResults() async {
    _logger.info('Fetching latest test results per test type');

    final rows = await _db.query('clinical_event', orderBy: 'date DESC');

    final Map<TestType, ClinicalTestResult> latest = {};

    for (final row in rows) {
      try {
        final jsonMap =
            jsonDecode(row['json'] as String) as Map<String, dynamic>;
        final event = ClinicalEvent.fromJson(jsonMap);

        for (final test in event.tests) {
          // If we already have an entry for this test type, it came from a newer
          // event because rows are ordered DESC; skip older ones.
          if (!latest.containsKey(test.testType)) {
            latest[test.testType] = test;
          }
        }
      } catch (e, st) {
        _logger.warning(
          'Failed to parse clinical_event row while computing latest tests: $e\n$st',
        );
      }
    }

    return latest;
  }
}
