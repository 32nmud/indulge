import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:indulge/data/models.dart';

import '../../services/database_connection_service.dart';
import 'package:logging/logging.dart';

class SexualEventRepository {
  final Database _db;
  final Logger _logger = Logger('SexualEventRepository');

  SexualEventRepository._(this._db);

  static Future<SexualEventRepository> create() async {
    final db = DatabaseConnectionService.instance.database;
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
      SELECT DATE(date) AS date_only, COUNT(id) AS count
      FROM sexual_event
      GROUP BY DATE(date);
    ''';
    final List<Map<String, Object?>> results = await _db.rawQuery(sql);
    Map<DateTime, int> normalizedResults = {};
    for (final row in results) {
      DateTime? date = DateTime.tryParse(row['date_only'] as String? ?? '');
      int? count = row['count'] as int? ?? 0;
      if (date != null && count != 0) {
        date = DateTime(date.year, date.month, date.day);
        normalizedResults.addAll({date: count});
      }
    }

    return normalizedResults;
  }

  Future<List<SexualEvent>> getAllEvents() async {
    _logger.info('Getting all sexual events');

    final rows = await _db.query('sexual_event');

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

  Future<List<Person>> getPersonsFromActivity(EventActivity activity) async {
    _logger.info('Getting persons from activity: $activity');

    List<String> personIds = [];
    for (ActivityParticipant participant in activity.participants) {
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
    List<EventActivity> activities,
  ) async {
    _logger.info('Getting persons from activities: $activities');

    List<String> personIds = [];
    for (EventActivity a in activities) {
      for (ActivityParticipant participant in a.participants) {
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

  Future<List<SexualActivityCategory>> getAllSexualActivityCategories() async {
    final rows = await _db.query('sexual_activities');
    _logger.info('DEBUG: Found ${rows.length} rows in sexual_activities table');

    final List<SexualActivityCategory> categories = [];
    for (final row in rows) {
      final jsonStr = row['json'] as String;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      _logger.info('DEBUG: Loading category: ${json['id']} - ${json['name']}');
      categories.add(SexualActivityCategory.fromJson(json));
    }

    // Sort alphabetically by name
    categories.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    _logger.info('DEBUG: Loaded ${categories.length} categories');
    return categories;
  }

  Future<List<SexualActivity>> getAllSexualActivities() async {
    // Activities are now embedded in categories - extract from categories
    final categories = await getAllSexualActivityCategories();
    final List<SexualActivity> activities = [];
    for (final category in categories) {
      for (final activity in category.activities) {
        activities.add(activity);
      }
    }

    // Sort alphabetically by name
    activities.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return activities;
  }

  Future<List<SexualActivityCategory>> getSexualActivityCategoriesByIds(
    List<String> ids,
  ) async {
    _logger.info('Getting sexual activity categories by ids: $ids');

    if (ids.isEmpty) return [];
    ids = ids.toSet().toList();

    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db.query(
      'sexual_activities',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    final List<SexualActivityCategory> categories = [];
    for (final row in rows) {
      categories.add(
        SexualActivityCategory.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
      );
    }

    // Sort alphabetically by name
    categories.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return categories;
  }

  Future<void> save(SexualEvent event) async {
    _logger.info('Saving sexual event: ${event.id}');

    await _db.insert('sexual_event', {
      'id': event.id,
      'date': event.date.toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
      'json': jsonEncode(
        ModelVersionMigration.addVersion(
          event.toJson(),
          ModelVersionMigration.currentVersion,
        ),
      ),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteById(String id) async {
    _logger.info('Deleting sexual event: $id');

    await _db.delete('sexual_event', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SexualActivity>> getSexualActivitiesForParticipant(
    ActivityParticipant participant,
  ) async {
    _logger.info(
      'Getting sexual activities for participant: ${participant.participant.reference}',
    );

    if (participant.activityCounts.isEmpty) return [];

    final List<SexualActivity> activities = [];
    for (var activityCount in participant.activityCounts) {
      // Look up activity by category + name instead of by ID
      final categoryRef = activityCount.categoryReference.reference;
      final activityName = activityCount.activityName;
      if (categoryRef.isEmpty || activityName.isEmpty) continue;

      final categories = await getAllSexualActivityCategories();
      for (final category in categories) {
        if (category.id != categoryRef) continue;
        for (final activity in category.activities) {
          if (activity.name == activityName) {
            activities.add(activity);
            break;
          }
        }
        break;
      }
    }

    return activities;
  }

  /// Removes all activities of a specific category from an event
  Future<void> removeActivityByCategoryId(
    String eventId,
    String activityCategoryId,
  ) async {
    _logger.info(
      'Removing activities with category $activityCategoryId from event $eventId',
    );

    final event = await getById(eventId);
    if (event == null) return;

    final updatedActivities = event.activities
        .where((activity) => activity.category.reference != activityCategoryId)
        .toList();

    final updatedEvent = event.copyWith(
      activities: updatedActivities,
      lastModifiedDate: DateTime.now(),
    );

    await save(updatedEvent);
  }

  /// Removes a participant from all activities in an event
  Future<void> removeParticipantById(String eventId, String personId) async {
    _logger.info('Removing participant $personId from event $eventId');

    final event = await getById(eventId);
    if (event == null) return;

    final updatedActivities = <EventActivity>[];
    for (final activity in event.activities) {
      final updatedParticipants = activity.participants
          .where((participant) => participant.participant.reference != personId)
          .toList();

      updatedActivities.add(
        activity.copyWith(participants: updatedParticipants),
      );
    }

    final updatedEvent = event.copyWith(
      activities: updatedActivities,
      lastModifiedDate: DateTime.now(),
    );

    await save(updatedEvent);
  }

  /// Gets all persons from the database
  Future<List<Person>> getAllPersons() async {
    _logger.info('Getting all persons');

    final rows = await _db.query('person');

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

  /// Gets a person by ID
  Future<Person?> getPersonById(String id) async {
    _logger.info('Getting person by id: $id');

    final rows = await _db.query(
      'person',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Person.fromJson(
      jsonDecode(rows.first['json'] as String) as Map<String, dynamic>,
    );
  }

  /// Saves a person to the database
  Future<void> savePerson(Person person) async {
    _logger.info('Saving person: ${person.id}');

    await _db.insert('person', {
      'id': person.id,
      'last_modified': DateTime.now().toIso8601String(),
      'json': jsonEncode(
        ModelVersionMigration.addVersion(
          person.toJson(),
          ModelVersionMigration.currentVersion,
        ),
      ),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Gets the "Me" person
  /// Gets the "Me" person (the user themselves)
  Future<Person?> getMyself() async {
    _logger.info('Getting myself person');

    final rows = await _db.query(
      'person',
      where: 'json LIKE ?',
      whereArgs: ['%"isSelf":true%'],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Person.fromJson(
      jsonDecode(rows.first['json'] as String) as Map<String, dynamic>,
    );
  }

  /// Deletes a person by ID and replaces them with Anonymous in all events
  /// Cannot delete the "self" person
  Future<void> deletePerson(String id) async {
    _logger.info('Deleting person: $id');

    // Check if this is the self person
    final person = await getPersonById(id);
    if (person?.isSelf == true) {
      throw Exception('Cannot delete yourself');
    }

    // First, update all events that reference this person
    await replacePersonInAllEvents(id, 'anonymous');

    // Then delete the person
    await _db.delete('person', where: 'id = ?', whereArgs: [id]);
  }

  /// Replaces a person with another person in all events
  Future<void> replacePersonInAllEvents(
    String oldPersonId,
    String newPersonId,
  ) async {
    _logger.info(
      'Replacing person $oldPersonId with $newPersonId in all events',
    );

    // Get all events
    final rows = await _db.query('sexual_event');

    for (final row in rows) {
      final event = SexualEvent.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      bool eventModified = false;
      final updatedActivities = <EventActivity>[];

      for (final activity in event.activities) {
        final updatedParticipants = <ActivityParticipant>[];

        for (final participant in activity.participants) {
          if (participant.participant.reference == oldPersonId) {
            // Replace with new person
            updatedParticipants.add(
              participant.copyWith(
                participant: Reference(
                  reference: newPersonId,
                  resourceType: 'Person',
                ),
              ),
            );
            eventModified = true;
          } else {
            updatedParticipants.add(participant);
          }
        }

        updatedActivities.add(
          activity.copyWith(participants: updatedParticipants),
        );
      }

      // Save the event if it was modified
      if (eventModified) {
        final updatedEvent = event.copyWith(
          activities: updatedActivities,
          lastModifiedDate: DateTime.now(),
        );
        await save(updatedEvent);
      }
    }
  }

  /// Saves an activity type to the database
  Future<void> saveActivityCategory(
    SexualActivityCategory activityCategory,
  ) async {
    _logger.info('Saving activity category: ${activityCategory.id}');

    await _db.insert('sexual_activities', {
      'id': activityCategory.id,
      'last_modified': DateTime.now().toIso8601String(),
      'json': jsonEncode(
        ModelVersionMigration.addVersion(
          activityCategory.toJson(),
          ModelVersionMigration.currentVersion,
        ),
      ),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Returns the number of events that use a specific activity category
  Future<int> getEventCountForActivityCategory(String id) async {
    final rows = await _db.query('sexual_event');
    int count = 0;
    for (final row in rows) {
      final event = SexualEvent.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );
      if (event.activities.any((a) => a.category.reference == id)) {
        count++;
      }
    }
    return count;
  }

  /// Deletes an activity category and removes it from all events
  Future<void> deleteActivityCategory(String id) async {
    _logger.info('Deleting activity category: $id');

    // First, remove all activities of this type from all events
    final rows = await _db.query('sexual_event');

    for (final row in rows) {
      final event = SexualEvent.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      final updatedActivities = event.activities
          .where((activity) => activity.category.reference != id)
          .toList();

      // Only save if activities were removed
      if (updatedActivities.length != event.activities.length) {
        final updatedEvent = event.copyWith(
          activities: updatedActivities,
          lastModifiedDate: DateTime.now(),
        );
        await save(updatedEvent);
      }
    }

    // Then delete the activity category
    await _db.delete('sexual_activities', where: 'id = ?', whereArgs: [id]);
  }

  /// Checks if an activity category is used in any events
  Future<bool> isActivityCategoryUsed(String activityCategoryId) async {
    _logger.info('Checking if activity category is used: $activityCategoryId');

    final rows = await _db.query('sexual_event');

    for (final row in rows) {
      final event = SexualEvent.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      for (final activity in event.activities) {
        if (activity.category.reference == activityCategoryId) {
          return true;
        }
      }
    }

    return false;
  }

  /// Saves a sexual activity to the database.
  /// Activities are identified by name + categoryId and are embedded in the
  /// category JSON blob. Find the containing category by matching activity name,
  /// update the entry, then re-save the category.
  Future<void> saveSexualActivity(
    SexualActivity activity, {
    required String categoryId,
  }) async {
    _logger.info('Saving sexual activity: ${activity.name} in $categoryId');

    final categories = await getAllSexualActivityCategories();
    for (final category in categories) {
      if (category.id != categoryId) continue;
      final activityIndex = category.activities.indexWhere(
        (a) => a.name == activity.name,
      );
      if (activityIndex >= 0) {
        final updatedActivities = List<SexualActivity>.from(
          category.activities,
        );
        updatedActivities[activityIndex] = activity;
        await saveActivityCategory(
          category.copyWith(activities: updatedActivities),
        );
        return;
      }
    }

    throw Exception(
      'Activity "${activity.name}" not found in category $categoryId.',
    );
  }

  /// Returns the number of events that use a specific sexual activity
  Future<int> getEventCountForSexualActivity(String id) async {
    final rows = await _db.query('sexual_event');
    int count = 0;
    for (final row in rows) {
      final event = SexualEvent.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      bool found = false;
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          if (participant.activityCounts.any(
            (ac) => ac.categoryReference.reference == id,
          )) {
            found = true;
            break;
          }
        }
        if (found) break;
      }
      if (found) count++;
    }
    return count;
  }

  /// Returns the number of events that contain a specific activity identified
  /// by both [categoryId] and [activityName].
  Future<int> getEventCountForSpecificActivity({
    required String categoryId,
    required String activityName,
  }) async {
    final rows = await _db.query('sexual_event');
    int count = 0;
    for (final row in rows) {
      final event = SexualEvent.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      bool found = false;
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          if (participant.activityCounts.any(
            (ac) =>
                ac.categoryReference.reference == categoryId &&
                ac.activityName == activityName,
          )) {
            found = true;
            break;
          }
        }
        if (found) break;
      }
      if (found) count++;
    }
    return count;
  }

  /// Deletes a sexual activity and removes it from all activity categories
  /// Uses categoryId and activityName to identify the activity
  Future<void> deleteSexualActivity({
    required String categoryId,
    required String activityName,
  }) async {
    _logger.info(
      'Deleting sexual activity: $activityName in category $categoryId',
    );

    // First, remove this activity from the activity category
    final categories = await getAllSexualActivityCategories();

    for (final category in categories) {
      if (category.id != categoryId) continue;
      final activityIndex = category.activities.indexWhere(
        (a) => a.name == activityName,
      );
      if (activityIndex >= 0) {
        final updatedActivities = List<SexualActivity>.from(category.activities)
          ..removeAt(activityIndex);
        final updatedCategory = category.copyWith(
          activities: updatedActivities,
        );
        await saveActivityCategory(updatedCategory);
        break;
      }
    }

    // Second, remove this activity from all event activities
    final eventRows = await _db.query('sexual_event');

    for (final row in eventRows) {
      final event = SexualEvent.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      bool eventModified = false;
      final updatedActivities = <EventActivity>[];

      for (final activity in event.activities) {
        final updatedParticipants = <ActivityParticipant>[];

        for (final participant in activity.participants) {
          // Remove only the specific activity from this participant.
          // Both the category AND the name must match to identify the exact
          // activity — using || would incorrectly remove all activities that
          // share either the category or the name.
          final updatedActivityCounts = participant.activityCounts
              .where(
                (ac) =>
                    !(ac.activityName == activityName &&
                        ac.categoryReference.reference == categoryId),
              )
              .toList();

          // Check if activities were removed
          if (updatedActivityCounts.length !=
              participant.activityCounts.length) {
            eventModified = true;
            updatedParticipants.add(
              participant.copyWith(activityCounts: updatedActivityCounts),
            );
          } else {
            updatedParticipants.add(participant);
          }
        }

        // Drop the entire EventActivity (category row) if every participant
        // has no activity counts left after the removal.
        final allEmpty = updatedParticipants.every(
          (p) => p.activityCounts.isEmpty,
        );
        if (!allEmpty) {
          updatedActivities.add(
            activity.copyWith(participants: updatedParticipants),
          );
        }
        // If allEmpty, the category row is silently dropped (eventModified is
        // already true because at least one activityCount was removed above).
      }

      if (eventModified) {
        final updatedEvent = event.copyWith(activities: updatedActivities);
        await save(updatedEvent);
      }
    }
  }

  /// Checks if a specific activity (by name + categoryId) exists in any
  /// activity category.
  Future<bool> isSexualActivityUsed({
    required String categoryId,
    required String activityName,
  }) async {
    _logger.info('Checking if activity "$activityName" exists in $categoryId');

    final rows = await _db.query(
      'sexual_activities',
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    for (final row in rows) {
      final category = SexualActivityCategory.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );
      if (category.activities.any((a) => a.name == activityName)) {
        return true;
      }
    }

    return false;
  }
}
