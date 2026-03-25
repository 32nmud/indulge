import 'package:indulge/data/models.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
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

          if (file.name.contains('sexual_activities/')) {
            await _seedSexualActivityCategory(txn, 'sexual_activities', json);
          } else if (file.name.contains('persons/')) {
            await _seedPerson(txn, 'person', json);
          } else if (file.name.contains('sexual_events/')) {
            await _seedSexualEvent(txn, 'sexual_event', json);
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
    String resourceId = resourceData["id"];
    String resourceName = resourceData["name"];
    _logger.info(
      "Seeding sexual activity category with id: $resourceId, name: $resourceName",
    );
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

  /// Seed person types with their properties
  Future<void> _seedPerson(
    Transaction txn,
    String tableName,
    Map<String, dynamic> resourceData,
  ) async {
    // Create the model with properties
    String resourceId = resourceData["id"];
    _logger.info("Seeding person with id: $resourceId");
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
    String resourceId = resourceData["id"];
    _logger.info("Seeding sexual event with id: $resourceId");
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
