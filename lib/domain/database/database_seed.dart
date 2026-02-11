import 'package:indulge/data/models/v2/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:logging/logging.dart';

class DatabaseSeed {
  final Database db;
  final Logger _logger = Logger('DatabaseSeed');

  final Map<String, String> seedFiles = {
    "sexualActivityCategory":
        "assets/sql/seed_data/sexual_activity_categories.json",
    "sexualActivity": "assets/sql/seed_data/sexual_activities.json",
    "person": "assets/sql/seed_data/persons.json",
  };

  final Map<String, String> tableMap = {
    "sexualActivityCategory": "sexual_activity_type",
    "sexualActivity": "sexual_activity_type_property",
    "sexualEvent": "sexual_event",
    "location": "location",
    "person": "person",
  };

  final Map<String, dynamic> modelMap = {
    "sexualActivityCategory": SexualActivityCategory,
    "sexualActivity": SexualActivity,
    "sexualEvent": SexualEvent,
    "location": Location,
    "person": Person,
  };

  DatabaseSeed({required this.db});

  /// Load the production seed file(s)
  Future<void> loadSeeds() async {
    await _loadSeedsFromMap(seedFiles);
  }

  /// Internal method to load seeds from a file map
  Future<void> _loadSeedsFromMap(Map<String, String> files) async {
    for (final entry in files.entries) {
      final key = entry.key;
      final filePath = entry.value;

      try {
        await _loadAndSeedFile(key, filePath);
      } catch (e) {
        _logger.severe('Error loading seed file $filePath: $e');
        rethrow;
      }
    }
  }

  /// Load a single seed file and insert into database
  Future<void> _loadAndSeedFile(String key, String filePath) async {
    // Load the JSON file from assets
    final jsonString = await rootBundle.loadString(filePath);
    final json = jsonDecode(jsonString);

    // Extract the resources array
    final resources = json['resources'] as List<dynamic>? ?? [];

    if (resources.isEmpty) {
      _logger.info('No resources found in $filePath');
      return;
    }

    // Get the table name and model class
    final tableName = tableMap[key];
    if (tableName == null) {
      throw Exception('No table mapping found for key: $key');
    }

    // Process each resource based on the key type
    await db.transaction((txn) async {
      for (Map<String, dynamic> resourceData in resources) {
        switch (key) {
          case "sexualActivityCategory":
            await _seedSexualActivityCategory(txn, tableName, resourceData);
            break;
          case "sexualActivity":
            await _seedSexualActivity(txn, tableName, resourceData);
            break;
          case "sexualEvent":
            await _seedSexualEvent(txn, tableName, resourceData);
            break;
          case "location":
            await _seedLocation(txn, tableName, resourceData);
            break;
          case "person":
            await _seedPerson(txn, tableName, resourceData);
            break;
          default:
            throw Exception('Unknown seed key: $key');
        }
      }
    });

    _logger.info('Successfully seeded $key from $filePath');
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
