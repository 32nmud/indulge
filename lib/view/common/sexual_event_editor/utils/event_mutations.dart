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
  bool participantFound = false;

  for (var participant in activity.participants) {
    if (participant.participant.reference != personId) {
      updatedParticipants.add(participant);
      continue;
    }
    participantFound = true;

    final hasActivity = participant.activityCounts.any(
      (ac) =>
          ac.activityName == activityName &&
          ac.categoryReference.reference == resolvedCategoryId,
    );

    List<ActivityCount> newCounts;
    if (hasActivity) {
      // Set count to 0 instead of removing to preserve role for future toggling
      newCounts = participant.activityCounts.map((ac) {
        if (ac.activityName == activityName &&
            ac.categoryReference.reference == resolvedCategoryId) {
          return ac.copyWith(count: 0);
        }
        return ac;
      }).toList();
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

  // If participant wasn't found, add them as a new participant
  if (!participantFound) {
    updatedParticipants.add(
      ActivityParticipant(
        participant: Reference(reference: personId, resourceType: 'Person'),
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
      ),
    );
  }

  updatedActivities[activityIndex] = activity.copyWith(
    participants: updatedParticipants,
  );

  return event.copyWith(activities: updatedActivities);
}

/// Toggle a participant's activity with a specific role.
/// If the participant doesn't exist, they are added.
/// If the activity exists with the same role, it is removed.
/// If the activity exists with a different role, the role is updated.
/// If the activity doesn't exist (count: 0), it is added with the selected role.
SexualEvent toggleParticipantActivity(
  SexualEvent event,
  int activityIndex,
  String activityName,
  String personId,
  ActivityRole role, {
  String? categoryId,
}) {
  if (activityIndex < 0 || activityIndex >= event.activities.length) {
    return event;
  }

  final updatedActivities = List<EventActivity>.from(event.activities);
  final activity = updatedActivities[activityIndex];
  final resolvedCategoryId = categoryId ?? activity.category.reference;

  final updatedParticipants = <ActivityParticipant>[];
  bool participantFound = false;

  for (var participant in activity.participants) {
    if (participant.participant.reference != personId) {
      updatedParticipants.add(participant);
      continue;
    }
    participantFound = true;

    final existingIndex = participant.activityCounts.indexWhere(
      (ac) =>
          ac.activityName == activityName &&
          ac.categoryReference.reference == resolvedCategoryId,
    );

    List<ActivityCount> newCounts;
    if (existingIndex >= 0) {
      final existing = participant.activityCounts[existingIndex];
      if (existing.count == 0) {
        // Activity exists but count is 0 - add it with the selected role
        newCounts = List<ActivityCount>.from(participant.activityCounts);
        newCounts[existingIndex] = existing.copyWith(count: 1, role: role);
      } else if (existing.role == role && existing.count > 0) {
        // Activity exists with same role and count > 0 - remove it (toggle off)
        newCounts = List<ActivityCount>.from(participant.activityCounts)
          ..removeAt(existingIndex);
      } else {
        // Activity exists with different role or count - update the role
        newCounts = List<ActivityCount>.from(participant.activityCounts);
        newCounts[existingIndex] = existing.copyWith(count: 1, role: role);
      }
    } else {
      // Activity doesn't exist - add it with the role
      newCounts = [
        ...participant.activityCounts,
        ActivityCount(
          categoryReference: Reference(
            reference: resolvedCategoryId,
            resourceType: 'SexualActivityCategory',
          ),
          activityName: activityName,
          count: 1,
          role: role,
        ),
      ];
    }

    updatedParticipants.add(participant.copyWith(activityCounts: newCounts));
  }

  if (!participantFound) {
    // Participant doesn't exist - create them with the activity
    final newParticipant = ActivityParticipant(
      participant: Reference(reference: personId, resourceType: 'Person'),
      activityCounts: [
        ActivityCount(
          categoryReference: Reference(
            reference: resolvedCategoryId,
            resourceType: 'SexualActivityCategory',
          ),
          activityName: activityName,
          count: 1,
          role: role,
        ),
      ],
    );
    updatedParticipants.add(newParticipant);
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

/// Toggle solo mode for a specific participant's activity.
/// When enabling solo, marks the activity as solo and removes other participants
/// from THIS SPECIFIC ACTIVITY only (they keep their other activities).
/// When disabling solo, clears the solo flag and restores visibility.
SexualEvent toggleSolo(
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

  int? participantIndex;
  int? activityCountIndex;

  for (int i = 0; i < activity.participants.length; i++) {
    final p = activity.participants[i];
    if (p.participant.reference == personId) {
      participantIndex = i;
      for (int j = 0; j < p.activityCounts.length; j++) {
        final ac = p.activityCounts[j];
        if (ac.activityName == activityName &&
            ac.categoryReference.reference == resolvedCategoryId) {
          activityCountIndex = j;
          break;
        }
      }
      break;
    }
  }

  bool currentSolo = false;
  if (participantIndex != null && activityCountIndex != null) {
    currentSolo = activity
        .participants[participantIndex]
        .activityCounts[activityCountIndex]
        .solo;
  }
  final newSoloState = !currentSolo;

  List<ActivityParticipant> updatedParticipants;

  if (participantIndex != null) {
    // Existing participant found
    final participant = activity.participants[participantIndex];

    if (activityCountIndex != null) {
      // Participant has this activity - update solo flag
      final updatedCounts = List<ActivityCount>.from(
        participant.activityCounts,
      );
      updatedCounts[activityCountIndex] = updatedCounts[activityCountIndex]
          .copyWith(solo: newSoloState);

      // Build updated participants list
      updatedParticipants = [
        participant.copyWith(activityCounts: updatedCounts),
      ];

      // Add back other participants (filtering THIS activity when enabling solo)
      for (final p in activity.participants) {
        if (p.participant.reference == personId) continue;
        if (newSoloState) {
          // Filter out THIS activity from other participants
          final filteredCounts = p.activityCounts
              .where(
                (ac) =>
                    !(ac.activityName == activityName &&
                        ac.categoryReference.reference == resolvedCategoryId),
              )
              .toList();
          // Keep participant with filtered counts (empty if this was their only activity)
          updatedParticipants.add(p.copyWith(activityCounts: filteredCounts));
        } else {
          // Keep all activities when disabling solo
          updatedParticipants.add(p);
        }
      }
    } else {
      // Participant doesn't have this activity yet - add it
      final newActivityCount = ActivityCount(
        categoryReference: Reference(
          reference: resolvedCategoryId,
          resourceType: 'SexualActivityCategory',
        ),
        activityName: activityName,
        count: 0,
        solo: newSoloState,
      );

      updatedParticipants = [
        participant.copyWith(
          activityCounts: [...participant.activityCounts, newActivityCount],
        ),
      ];

      // When enabling solo, filter THIS activity from other participants
      // When disabling solo, keep all participants as-is
      for (final p in activity.participants) {
        if (p.participant.reference == personId) continue;
        if (newSoloState) {
          final filteredCounts = p.activityCounts
              .where(
                (ac) =>
                    !(ac.activityName == activityName &&
                        ac.categoryReference.reference == resolvedCategoryId),
              )
              .toList();
          // Keep participant with filtered counts (empty if this was their only activity)
          updatedParticipants.add(p.copyWith(activityCounts: filteredCounts));
        } else {
          updatedParticipants.add(p);
        }
      }
    }
  } else {
    // New participant - add them and handle solo filtering for existing participants
    final newParticipant = ActivityParticipant(
      participant: Reference(reference: personId, resourceType: 'Person'),
      activityCounts: [
        ActivityCount(
          categoryReference: Reference(
            reference: resolvedCategoryId,
            resourceType: 'SexualActivityCategory',
          ),
          activityName: activityName,
          count: 0,
          solo: newSoloState,
        ),
      ],
    );

    updatedParticipants = [newParticipant];

    // When enabling solo, filter THIS activity from existing participants
    // When disabling solo, keep all participants as-is
    for (final p in activity.participants) {
      if (p.participant.reference == personId) continue;
      if (newSoloState) {
        final filteredCounts = p.activityCounts
            .where(
              (ac) =>
                  !(ac.activityName == activityName &&
                      ac.categoryReference.reference == resolvedCategoryId),
            )
            .toList();
        // Keep participant with filtered counts (empty if this was their only activity)
        updatedParticipants.add(p.copyWith(activityCounts: filteredCounts));
      } else {
        updatedParticipants.add(p);
      }
    }
  }

  updatedActivities[activityIndex] = activity.copyWith(
    participants: updatedParticipants,
  );

  return event.copyWith(activities: updatedActivities);
}
