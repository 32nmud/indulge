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
    Map<DateTime, int> normalizedResults = Map();
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

  Future<List<SexualActivityType>> getAllSexualActivityTypes() async {
    final rows = await _db.query('sexual_activity_type');

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

  Future<List<SexualActivityTypeProperty>>
  getAllSexualActivityTypeProperties() async {
    final rows = await _db.query('sexual_activity_type_property');

    final List<SexualActivityTypeProperty> properties = [];
    for (final row in rows) {
      properties.add(
        SexualActivityTypeProperty.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
      );
    }

    return properties;
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

    if (participant.propertyCounts.isEmpty) return [];

    final List<SexualActivityTypeProperty> properties = [];
    for (var propertyCount in participant.propertyCounts) {
      final rows = await _db.query(
        'sexual_activity_type_property',
        where: 'id = ?',
        whereArgs: [propertyCount.propertyReference.reference],
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

  /// Removes all activities of a specific type from an event
  Future<void> removeActivityByTypeId(
    String eventId,
    String activityTypeId,
  ) async {
    _logger.info(
      'Removing activities with type $activityTypeId from event $eventId',
    );

    final event = await getById(eventId);
    if (event == null) return;

    final updatedActivities = event.activities
        .where((activity) => activity.type.reference != activityTypeId)
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

    final updatedActivities = <SexualActivity>[];
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
      final updatedActivities = <SexualActivity>[];

      for (final activity in event.activities) {
        final updatedParticipants = <SexualActivityParticipant>[];

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
  Future<void> saveActivityType(SexualActivityType activityType) async {
    _logger.info('Saving activity type: ${activityType.id}');

    await _db.insert('sexual_activity_type', {
      'id': activityType.id,
      'last_modified': DateTime.now().toIso8601String(),
      'json': jsonEncode(activityType.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Deletes an activity type and removes it from all events
  Future<void> deleteActivityType(String id) async {
    _logger.info('Deleting activity type: $id');

    // First, remove all activities of this type from all events
    final rows = await _db.query('sexual_event');

    for (final row in rows) {
      final event = SexualEvent.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      final updatedActivities = event.activities
          .where((activity) => activity.type.reference != id)
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

    // Then delete the activity type
    await _db.delete('sexual_activity_type', where: 'id = ?', whereArgs: [id]);
  }

  /// Checks if an activity type is used in any events
  Future<bool> isActivityTypeUsed(String activityTypeId) async {
    _logger.info('Checking if activity type is used: $activityTypeId');

    final rows = await _db.query('sexual_event');

    for (final row in rows) {
      final event = SexualEvent.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      for (final activity in event.activities) {
        if (activity.type.reference == activityTypeId) {
          return true;
        }
      }
    }

    return false;
  }

  /// Saves an activity property to the database
  Future<void> saveActivityProperty(SexualActivityTypeProperty property) async {
    _logger.info('Saving activity property: ${property.id}');

    await _db.insert(
      'sexual_activity_type_property',
      {
        'id': property.id,
        'last_modified': DateTime.now().toIso8601String(),
        'json': jsonEncode(property.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes an activity property and removes it from all activity types
  Future<void> deleteActivityProperty(String id) async {
    _logger.info('Deleting activity property: $id');

    // First, remove this property from all activity types
    final activityTypeRows = await _db.query('sexual_activity_type');

    for (final row in activityTypeRows) {
      final activityType = SexualActivityType.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      final updatedProperties = activityType.properties
          .where((ref) => ref.reference != id)
          .toList();

      // Only save if properties were removed
      if (updatedProperties.length != activityType.properties.length) {
        final updatedType = activityType.copyWith(
          properties: updatedProperties,
        );
        await saveActivityType(updatedType);
      }
    }

    // Second, remove this property from all event activities
    final eventRows = await _db.query('sexual_event');

    for (final row in eventRows) {
      final event = SexualEvent.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      bool eventModified = false;
      final updatedActivities = <SexualActivity>[];

      for (final activity in event.activities) {
        final updatedParticipants = <SexualActivityParticipant>[];

        for (final participant in activity.participants) {
          // Remove the property reference from this participant
          final updatedPropertyCounts = participant.propertyCounts
              .where((pc) => pc.propertyReference.reference != id)
              .toList();

          // Check if properties were removed
          if (updatedPropertyCounts.length !=
              participant.propertyCounts.length) {
            eventModified = true;
            updatedParticipants.add(
              participant.copyWith(propertyCounts: updatedPropertyCounts),
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

    // Finally, delete the property
    await _db.delete(
      'sexual_activity_type_property',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Checks if an activity property is used in any activity types
  Future<bool> isActivityPropertyUsed(String propertyId) async {
    _logger.info('Checking if activity property is used: $propertyId');

    final rows = await _db.query('sexual_activity_type');

    for (final row in rows) {
      final activityType = SexualActivityType.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

      for (final property in activityType.properties) {
        if (property.reference == propertyId) {
          return true;
        }
      }
    }

    return false;
  }
}
