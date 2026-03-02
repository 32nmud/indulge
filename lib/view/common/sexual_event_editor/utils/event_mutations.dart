/*
  Helpers for mutating SexualEvent model immutably.

  These functions take a SexualEvent and return a new SexualEvent with the
  requested modification applied. They intentionally avoid side effects so
  they can be unit-tested easily and used from UI code that manages state.

  Usage:
    import 'package:indulge/view/event_editor/utils/event_mutations.dart';

    final updated = addActivity(oldEvent, category);
*/

import 'package:indulge/data/models.dart';

SexualEvent addActivity(
  SexualEvent event,
  SexualActivityCategory activityCategory,
) {
  final newActivity = EventActivity(
    category: Reference(
      reference: activityCategory.id,
      resourceType: 'SexualActivityCategory',
    ),
    participants: [],
  );

  final updatedActivities = [...event.activities, newActivity];

  return event.copyWith(activities: updatedActivities);
}

SexualEvent removeActivity(SexualEvent event, int activityIndex) {
  if (activityIndex < 0 || activityIndex >= event.activities.length) {
    return event;
  }
  final updatedActivities = List<EventActivity>.from(event.activities)
    ..removeAt(activityIndex);

  return event.copyWith(activities: updatedActivities);
}

/// Adds a participant to the activity at [activityIndex].
/// If the participant (by id) already exists in that activity, the original
/// event is returned unchanged.
SexualEvent addParticipant(
  SexualEvent event,
  int activityIndex,
  Person person,
) {
  if (activityIndex < 0 || activityIndex >= event.activities.length) {
    return event;
  }

  final updatedActivities = List<EventActivity>.from(event.activities);
  final activity = updatedActivities[activityIndex];

  final alreadyExists = activity.participants.any(
    (p) => p.participant.reference == person.id,
  );

  if (alreadyExists) return event;

  final newParticipant = ActivityParticipant(
    participant: Reference(reference: person.id, resourceType: 'Person'),
    activityCounts: [],
  );

  updatedActivities[activityIndex] = activity.copyWith(
    participants: [...activity.participants, newParticipant],
  );

  return event.copyWith(activities: updatedActivities);
}

SexualEvent removeParticipant(
  SexualEvent event,
  int activityIndex,
  int participantIndex,
) {
  if (activityIndex < 0 || activityIndex >= event.activities.length) {
    return event;
  }
  final updatedActivities = List<EventActivity>.from(event.activities);
  final activity = updatedActivities[activityIndex];

  if (participantIndex < 0 ||
      participantIndex >= activity.participants.length) {
    return event;
  }

  final updatedParticipants = List<ActivityParticipant>.from(
    activity.participants,
  )..removeAt(participantIndex);

  updatedActivities[activityIndex] = activity.copyWith(
    participants: updatedParticipants,
  );

  return event.copyWith(activities: updatedActivities);
}

/// Toggle the given activity (identified by [activityName]) on behalf of
/// [myselfId] for the activity at [activityIndex]. If the "me" participant
/// does not exist, it is created. If removing the last activity for "me",
/// the participant entry is removed.
///
/// [categoryId] should be the subcategory ID when the activity comes from a
/// subcategory, otherwise the parent EventActivity category ID. This ensures
/// activities with the same name in different (sub)categories are stored
/// distinctly.
SexualEvent toggleMyselfForProperty(
  SexualEvent event,
  int activityIndex,
  String myselfId, {
  String activityName = '',
  String? categoryId,
}) {
  if (activityIndex < 0 || activityIndex >= event.activities.length) {
    return event;
  }

  final updatedActivities = List<EventActivity>.from(event.activities);
  final activity = updatedActivities[activityIndex];
  final resolvedCategoryId = categoryId ?? activity.category.reference;

  final meIndex = activity.participants.indexWhere(
    (p) => p.participant.reference == myselfId,
  );

  List<ActivityParticipant> updatedParticipants;

  if (meIndex == -1) {
    final newParticipant = ActivityParticipant(
      participant: Reference(reference: myselfId, resourceType: 'Person'),
      activityCounts: [
        ActivityCount(
          categoryReference: Reference(
            reference: resolvedCategoryId,
            resourceType: 'SexualActivityCategory',
          ),
          activityName: activityName,
          count: 1,
        ),
      ],
    );
    updatedParticipants = [...activity.participants, newParticipant];
  } else {
    final meParticipant = activity.participants[meIndex];
    final hasActivity = meParticipant.activityCounts.any(
      (ac) =>
          ac.activityName == activityName &&
          ac.categoryReference.reference == resolvedCategoryId,
    );

    List<ActivityCount> newCounts;
    if (hasActivity) {
      newCounts = meParticipant.activityCounts
          .where(
            (ac) =>
                !(ac.activityName == activityName &&
                    ac.categoryReference.reference == resolvedCategoryId),
          )
          .toList();
    } else {
      newCounts = [
        ...meParticipant.activityCounts,
        ActivityCount(
          categoryReference: Reference(
            reference: resolvedCategoryId,
            resourceType: 'SexualActivityCategory',
          ),
          activityName: activityName,
          count: 1,
        ),
      ];
    }

    updatedParticipants = List<ActivityParticipant>.from(activity.participants);

    if (newCounts.isEmpty) {
      updatedParticipants.removeAt(meIndex);
    } else {
      updatedParticipants[meIndex] = meParticipant.copyWith(
        activityCounts: newCounts,
      );
    }
  }

  updatedActivities[activityIndex] = activity.copyWith(
    participants: updatedParticipants,
  );

  return event.copyWith(activities: updatedActivities);
}

/// Toggle the property for an existing participant (identified by [personId]).
/// If the participant doesn't exist, returns the original event.
///
/// [categoryId] should be the subcategory ID when the activity comes from a
/// subcategory, otherwise the parent EventActivity category ID.
SexualEvent toggleParticipantForProperty(
  SexualEvent event,
  int activityIndex,
  String activityName,
  String personId, {
  String? categoryId,
}) {
  if (activityIndex < 0 || activityIndex >= event.activities.length) {
    return event;
  }

  final updatedActivities = List<EventActivity>.from(event.activities);
  final activity = updatedActivities[activityIndex];
  final resolvedCategoryId = categoryId ?? activity.category.reference;

  final updatedParticipants = <ActivityParticipant>[];

  for (var participant in activity.participants) {
    if (participant.participant.reference != personId) {
      updatedParticipants.add(participant);
      continue;
    }

    final hasActivity = participant.activityCounts.any(
      (ac) =>
          ac.activityName == activityName &&
          ac.categoryReference.reference == resolvedCategoryId,
    );

    List<ActivityCount> newCounts;
    if (hasActivity) {
      newCounts = participant.activityCounts
          .where(
            (ac) =>
                !(ac.activityName == activityName &&
                    ac.categoryReference.reference == resolvedCategoryId),
          )
          .toList();
    } else {
      newCounts = [
        ...participant.activityCounts,
        ActivityCount(
          categoryReference: Reference(
            reference: resolvedCategoryId,
            resourceType: 'SexualActivityCategory',
          ),
          activityName: activityName,
          count: 1,
        ),
      ];
    }

    updatedParticipants.add(participant.copyWith(activityCounts: newCounts));
  }

  updatedActivities[activityIndex] = activity.copyWith(
    participants: updatedParticipants,
  );

  return event.copyWith(activities: updatedActivities);
}

/// [categoryId] should be the subcategory ID when the activity comes from a
/// subcategory, otherwise the parent EventActivity category ID.
SexualEvent incrementPropertyCount(
  SexualEvent event,
  int activityIndex,
  String activityName,
  String personId, {
  String? categoryId,
}) {
  if (activityIndex < 0 || activityIndex >= event.activities.length) {
    return event;
  }

  final updatedActivities = List<EventActivity>.from(event.activities);
  final activity = updatedActivities[activityIndex];
  final resolvedCategoryId = categoryId ?? activity.category.reference;

  final updatedParticipants = <ActivityParticipant>[];

  for (var participant in activity.participants) {
    if (participant.participant.reference != personId) {
      updatedParticipants.add(participant);
      continue;
    }

    final updatedActivityCounts = participant.activityCounts.map((ac) {
      if (ac.activityName == activityName &&
          ac.categoryReference.reference == resolvedCategoryId) {
        return ac.copyWith(count: ac.count + 1);
      }
      return ac;
    }).toList();

    updatedParticipants.add(
      participant.copyWith(activityCounts: updatedActivityCounts),
    );
  }

  updatedActivities[activityIndex] = activity.copyWith(
    participants: updatedParticipants,
  );

  return event.copyWith(activities: updatedActivities);
}

/// [categoryId] should be the subcategory ID when the activity comes from a
/// subcategory, otherwise the parent EventActivity category ID.
SexualEvent decrementPropertyCount(
  SexualEvent event,
  int activityIndex,
  String activityName,
  String personId, {
  String? categoryId,
}) {
  if (activityIndex < 0 || activityIndex >= event.activities.length) {
    return event;
  }

  final updatedActivities = List<EventActivity>.from(event.activities);
  final activity = updatedActivities[activityIndex];
  final resolvedCategoryId = categoryId ?? activity.category.reference;

  final updatedParticipants = <ActivityParticipant>[];

  for (var participant in activity.participants) {
    if (participant.participant.reference != personId) {
      updatedParticipants.add(participant);
      continue;
    }

    final newCounts = <ActivityCount>[];
    for (var ac in participant.activityCounts) {
      if (ac.activityName == activityName &&
          ac.categoryReference.reference == resolvedCategoryId) {
        if (ac.count > 1) {
          newCounts.add(ac.copyWith(count: ac.count - 1));
        }
        // if count == 1, we remove the entry by not adding it
      } else {
        newCounts.add(ac);
      }
    }

    updatedParticipants.add(participant.copyWith(activityCounts: newCounts));
  }

  updatedActivities[activityIndex] = activity.copyWith(
    participants: updatedParticipants,
  );

  return event.copyWith(activities: updatedActivities);
}
