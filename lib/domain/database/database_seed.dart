import 'package:indulge/data/models/v2/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:archive/archive.dart';

class DatabaseSeed {
  final Database db;
  final Logger _logger = Logger('DatabaseSeed');
  final String seedZipPath = 'assets/seed.zip';

  DatabaseSeed({required this.db});

  /// Load the seed zip file and import data
  Future<void> loadSeeds() async {
    try {
      final byteData = await rootBundle.load(seedZipPath);
      final bytes = byteData.buffer.asUint8List();
      final archive = ZipDecoder().decodeBytes(bytes);

      await db.transaction((txn) async {
        for (final file in archive) {
          if (!file.isFile) continue;
          if (!file.name.endsWith('.json')) continue;

          final content = utf8.decode(file.content as List<int>);
          final json = jsonDecode(content) as Map<String, dynamic>;

          if (file.name.contains('categories/')) {
            await _seedSexualActivityCategory(
              txn,
              'sexual_activity_type',
              json,
            );
          } else if (file.name.contains('activities/')) {
            await _seedSexualActivity(
              txn,
              'sexual_activity_type_property',
              json,
            );
          } else if (file.name.contains('persons/')) {
            await _seedPerson(txn, 'person', json);
          } else if (file.name.contains('sexual_events/')) {
            await _seedSexualEvent(txn, 'sexual_event', json);
          } else if (file.name.contains('locations/')) {
            await _seedLocation(txn, 'location', json);
          }
        }
      });

      _logger.info('Successfully seeded database from $seedZipPath');
    } catch (e) {
      _logger.severe('Error loading seed zip: $e');
      rethrow;
    }
  }

  /// Seed sexual activity categories with their activities
  Future<void> _seedSexualActivityCategory(
    Transaction txn,
    String tableName,
    Map<String, dynamic> resourceData,
  ) async {
    // Create the model with properties
    final activityCategory = SexualActivityCategory.fromJson(resourceData);

    // Insert into database
    await txn.rawInsert(
      'INSERT OR REPLACE INTO $tableName (id, last_modified, json) VALUES (?, ?, ?)',
      [
        activityCategory.id,
        DateTime.now().toIso8601String(),
        jsonEncode(activityCategory.toJson()),
      ],
    );
  }

  /// Seed sexual activities
  Future<void> _seedSexualActivity(
    Transaction txn,
    String tableName,
    Map<String, dynamic> resourceData,
  ) async {
    // Create the model with properties
    final sexualActivity = SexualActivity.fromJson(resourceData);

    // Insert into database
    await txn.rawInsert(
      'INSERT OR REPLACE INTO $tableName (id, last_modified, json) VALUES (?, ?, ?)',
      [
        sexualActivity.id,
        DateTime.now().toIso8601String(),
        jsonEncode(sexualActivity.toJson()),
      ],
    );
  }

  /// Seed location types with their properties
  Future<void> _seedLocation(
    Transaction txn,
    String tableName,
    Map<String, dynamic> resourceData,
  ) async {
    // Create the model with properties
    final location = Location.fromJson(resourceData);

    // Insert into database
    await txn.rawInsert(
      'INSERT OR REPLACE INTO $tableName (id, last_modified, json) VALUES (?, ?, ?)',
      [
        location.id,
        DateTime.now().toIso8601String(),
        jsonEncode(location.toJson()),
      ],
    );
  }

  /// Seed person types with their properties
  Future<void> _seedPerson(
    Transaction txn,
    String tableName,
    Map<String, dynamic> resourceData,
  ) async {
    // Create the model with properties
    final person = Person.fromJson(resourceData);

    // Insert into database
    await txn.rawInsert(
      'INSERT OR REPLACE INTO $tableName (id, last_modified, json) VALUES (?, ?, ?)',
      [
        person.id,
        DateTime.now().toIso8601String(),
        jsonEncode(person.toJson()),
      ],
    );
  }

  /// Seed sexual event types with their properties
  Future<void> _seedSexualEvent(
    Transaction txn,
    String tableName,
    Map<String, dynamic> resourceData,
  ) async {
    // Create the model with properties
    final eventType = SexualEvent.fromJson(resourceData);

    // Insert into database
    await txn.rawInsert(
      'INSERT OR REPLACE INTO $tableName (id, date, last_modified, json) VALUES (?, ?, ?, ?)',
      [
        eventType.id,
        eventType.date.toIso8601String(),
        eventType.lastModifiedDate == null
            ? DateTime.now().toIso8601String()
            : eventType.lastModifiedDate!.toIso8601String(),
        jsonEncode(eventType.toJson()),
      ],
    );
  }
}
