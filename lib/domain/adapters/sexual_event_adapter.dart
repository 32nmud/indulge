import '../../data/models/sexual_event.dart';
import '../../data/models/location.dart';
import '../../data/models/person.dart';
import '../../data/models/sexual_activity.dart';
import '../../domain/database/models/event.dart' as dbEvent;
import '../../domain/database/models/sexual_activity.dart' as dbAct;
import '../../domain/database/models/sexual_activity_type.dart' as dbActType;
import '../../domain/database/models/person.dart' as dbPerson;
import '../../domain/database/models/location.dart' as dbLocation;
import '../../domain/database/models/address.dart' as dbAddress;
import '../../domain/database/models/coordinate.dart' as dbCoordinate;
import '../../domain/database/models/enums.dart' as dbEnum;

/// Translates between the SQLite row objects (in
/// `lib/domain/database/models/...`) and the UI‑centric DTOs
/// defined in `lib/data/models/sexual_event.dart`.
class SexualEventAdapter {
  /// Convert a fully‑fetched set of rows into a single `SexualEvent` DTO.
  static SexualEvent toDomain({
    required dbEvent.Event event,
    required List<dbPerson.Person> participants,
    required List<dbAct.SexualActivity> activities,
    required List<dbActType.SexualActivityType> activityTypes,
    dbLocation.Location? location,
    dbAddress.Address? address,
    dbCoordinate.Coordinate? coordinate,
  }) {
    Location? locationDto;
    if (location != null && (address != null || coordinate != null)) {
      locationDto = Location(
        id: location.id,
        address: address?.line1,
        city: address?.city,
        state: address?.state,
        zip: address?.zip,
        lat: coordinate?.lat,
        long: coordinate?.long,
      );
    }

    // Map participants
    final participantDtos = participants
        .map((p) => Person(
              id: p.id,
              firstName: p.firstName,
              lastName: p.lastName,
              nickname: p.nickname,
              locationId: p.locationId,
            ))
        .toList();

    // Map activities + their types
    final activityDtos = activities.map((a) {
      final type = activityTypes.firstWhere(
        (t) => t.id == a.activityId,
        orElse: () => dbActType.SexualActivityType(
          id: null,
          name: '',
          minParticipants: 0,
          maxParticipants: 0,
          displayCharacter: '',
          isRisky: false,
        ),
      );
      return SexualActivity(
        id: a.id,
        eventId: a.eventId,
        activityId: a.activityId,
        name: type.name,
        minParticipants: type.minParticipants,
        maxParticipants: type.maxParticipants,
        displayCharacter: type.displayCharacter,
        isRisky: type.isRisky,
      );
    }).toList();

    return SexualEvent(
      baseEventId: event.id,
      date: event.date,
      location: locationDto,
      participants: participantDtos,
      activities: activityDtos,
    );
  }

  /// Convert a UI‑centric DTO back into the DB‑specific representation
  /// that can be inserted or updated in the `event` table.
  /// Only the columns that belong to the `event` table are returned here.
  static dbEvent.Event toDatabase(SexualEvent dto) => dbEvent.Event(
        id: dto.baseEventId,
        date: dto.date,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        eventType: dbEnum.EventType.sexual,
        locationId: dto.location?.id,
        notes: null,
      );
}
