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

  Future<List<Location>> getAllLocations() async {
    _logger.info('Getting all locations');

    final rows = await _db.query('location');

    final locations = <Location>[];
    for (final row in rows) {
      locations.add(
        Location.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
      );
    }
    return locations;
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
    final rows = await _db.query('sexual_activity_type');

    final List<SexualActivityCategory> categories = [];
    for (final row in rows) {
      categories.add(
        SexualActivityCategory.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
      );
    }

    return categories;
  }

  Future<List<SexualActivity>> getAllSexualActivities() async {
    final rows = await _db.query('sexual_activity_type_property');

    final List<SexualActivity> activities = [];
    for (final row in rows) {
      activities.add(
        SexualActivity.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
      );
    }

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
      'sexual_activity_type',
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

    return categories;
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

  Future<List<SexualActivity>> getSexualActivitiesForParticipant(
    ActivityParticipant participant,
  ) async {
    _logger.info(
      'Getting sexual activities for participant: ${participant.participant.reference}',
    );

    if (participant.activityCounts.isEmpty) return [];

    final List<SexualActivity> activities = [];
    for (var activityCount in participant.activityCounts) {
      final rows = await _db.query(
        'sexual_activity_type_property',
        where: 'id = ?',
        whereArgs: [activityCount.activityReference.reference],
      );

      for (final row in rows) {
        activities.add(
          SexualActivity.fromJson(
            jsonDecode(row['json'] as String) as Map<String, dynamic>,
          ),
        );
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
      'json': jsonEncode(person.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

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

    await _db.insert('sexual_activity_type', {
      'id': activityCategory.id,
      'last_modified': DateTime.now().toIso8601String(),
      'json': jsonEncode(activityCategory.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
    await _db.delete('sexual_activity_type', where: 'id = ?', whereArgs: [id]);
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

  /// Saves a sexual activity to the database
  Future<void> saveSexualActivity(SexualActivity activity) async {
    _logger.info('Saving sexual activity: ${activity.id}');

    await _db.insert(
      'sexual_activity_type_property',
      {
        'id': activity.id,
        'last_modified': DateTime.now().toIso8601String(),
        'json': jsonEncode(activity.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a sexual activity and removes it from all activity categories
  Future<void> deleteSexualActivity(String id) async {
    _logger.info('Deleting sexual activity: $id');

    // First, remove this activity from all activity categories
    final activityCategoryRows = await _db.query('sexual_activity_type');

    for (final row in activityCategoryRows) {
      final activityCategory = SexualActivityCategory.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      final updatedActivities = activityCategory.activities
          .where((ref) => ref.reference != id)
          .toList();

      // Only save if activities were removed
      if (updatedActivities.length != activityCategory.activities.length) {
        final updatedCategory = activityCategory.copyWith(
          activities: updatedActivities,
        );
        await saveActivityCategory(updatedCategory);
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
          // Remove the activity reference from this participant
          final updatedActivityCounts = participant.activityCounts
              .where((ac) => ac.activityReference.reference != id)
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

    // Finally, delete the activity
    await _db.delete(
      'sexual_activity_type_property',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Checks if a sexual activity is used in any activity categories
  Future<bool> isSexualActivityUsed(String activityId) async {
    _logger.info('Checking if sexual activity is used: $activityId');

    final rows = await _db.query('sexual_activity_type');

    for (final row in rows) {
      final activityCategory = SexualActivityCategory.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      for (final activity in activityCategory.activities) {
        if (activity.reference == activityId) {
          return true;
        }
      }
    }

    return false;
  }
}
