import 'package:indulge/data/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class DatabaseSeed {
  final Database db;

  final Map<String, String> seedFiles = {
    "sexualActivityType": "assets/sql/seed_data/sexual_activity_types.json",
  };

  final Map<String, String> devSeedFiles = {
    "sexualEventType": "assets/sql/development_seed_data/sexual_events.json",
  };

  final Map<String, String> tableMap = {
    "sexualActivityType": "sexual_activity_type",
    "sexualEventType": "sexual_event",
  };

  final Map<String, dynamic> modelMap = {
    "sexualActivityType": SexualActivityType,
    "sexualEventType": SexualEvent,
  };

  DatabaseSeed({required this.db});

  /// Load the production seed file(s)
  Future<void> loadSeeds() async {
    await _loadSeedsFromMap(seedFiles);
  }

  /// Load the development seed file(s)
  Future<void> loadDevSeeds() async {
    await _loadSeedsFromMap(devSeedFiles);
  }

  /// Internal method to load seeds from a file map
  Future<void> _loadSeedsFromMap(Map<String, String> files) async {
    for (final entry in files.entries) {
      final key = entry.key;
      final filePath = entry.value;

      try {
        await _loadAndSeedFile(key, filePath);
      } catch (e) {
        print('Error loading seed file $filePath: $e');
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
      print('No resources found in $filePath');
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
          case "sexualActivityType":
            await _seedSexualActivityType(txn, tableName, resourceData);
            break;
          case "sexualEventType":
            await _seedSexualEventType(txn, tableName, resourceData);
            break;
          default:
            throw Exception('Unknown seed key: $key');
        }
      }
    });

    print('Successfully seeded $key from $filePath');
  }

  /// Seed sexual activity types with their properties
  Future<void> _seedSexualActivityType(
    Transaction txn,
    String tableName,
    Map<String, dynamic> resourceData,
  ) async {
    // Create the model with properties
    final activityType = SexualActivityType.fromJson(resourceData);

    // Insert into database
    await txn.rawInsert(
      'INSERT OR REPLACE INTO $tableName (id, last_modified, json) VALUES (?, ?, ?)',
      [
        activityType.id,
        DateTime.now().toIso8601String(),
        jsonEncode(activityType.toJson()),
      ],
    );
  }

  /// Seed sexual event types with their properties
  Future<void> _seedSexualEventType(
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
