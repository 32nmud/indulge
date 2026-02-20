import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/person_avatar.dart';

/// A extracted widget for rendering a single activity card used by the
/// Event editor. This mirrors the original `_buildActivityCard` logic but
/// receives all required data and callbacks from the parent.
///
/// The widget is intentionally "dumb" — it does not mutate state itself,
/// it relies on callbacks provided by the parent `EventEditorPage` to make
/// changes to the underlying event model.
class ActivityCard extends StatelessWidget {
  final int activityIndex;
  final EventActivity activity;
  final Map<String, SexualActivityCategory> availableActivityCategories;
  final Map<String, SexualActivity> availableActivities;
  final List<Person> availablePersons;
  final Person? myself;

  // UI state / actions
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onRemove;
  final VoidCallback onShowPersonPicker;

  // Property/participant interactions
  final void Function(int activityIndex, String activityId)
  toggleMyselfForProperty;
  final void Function(int activityIndex, String activityId, String personId)
  toggleParticipantForProperty;
  final void Function(int activityIndex, String activityId, String personId)
  incrementPropertyCount;
  final void Function(int activityIndex, String activityId, String personId)
  decrementPropertyCount;
  // Callback to request removal of a participant (activityIndex + participantIndex)
  final void Function(int activityIndex, int participantIndex)
  onRemoveParticipant;

  const ActivityCard({
    super.key,
    required this.activityIndex,
    required this.activity,
    required this.availableActivityCategories,
    required this.availableActivities,
    required this.availablePersons,
    required this.myself,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onRemove,
    required this.onShowPersonPicker,
    required this.toggleMyselfForProperty,
    required this.toggleParticipantForProperty,
    required this.incrementPropertyCount,
    required this.decrementPropertyCount,
    required this.onRemoveParticipant,
  });

  @override
  Widget build(BuildContext context) {
    final activityCategory =
        availableActivityCategories[activity.category.reference];
    final emoji = activityCategory?.displayCharacter ?? '❔';
    final name = activityCategory?.name ?? 'Unknown';

    // Get available properties for this activity type and sort alphabetically
    final availableSexualActivities = <SexualActivity>[];
    if (activityCategory != null) {
      for (var activityRef in activityCategory.activities) {
        final sexualActivity = availableActivities[activityRef.reference];
        if (sexualActivity != null) {
          availableSexualActivities.add(sexualActivity);
        }
      }
      // Sort alphabetically by name
      availableSexualActivities.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity header (always visible, tappable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (activityCategory?.requiresPartner == true)
                            const Text(
                              'Requires partner',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onRemove,
                      tooltip: 'Remove activity',
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Collapsible content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Participants section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Participants',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onShowPersonPicker,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (activity.participants.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activityCategory?.requiresPartner == true
                                  ? 'Add at least one partner to continue'
                                  : 'Add other participants, or toggle properties below to track your own participation',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildParticipantSection(context),
                  // Properties section (show even with no participants for solo-capable activities)
                  if (availableSexualActivities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Activities',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...availableSexualActivities.map((sexualActivity) {
                      return _buildPropertyRow(context, sexualActivity);
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantSection(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activity.participants.asMap().entries.map((entry) {
        final participantIndex = entry.key;
        final participant = entry.value;
        final person = availablePersons.firstWhere(
          (p) => p.id == participant.participant.reference,
          orElse: () => Person(
            date: DateTime.now(),
            name: const Name(given: 'Unknown'),
          ),
        );
        final personName =
            person.name.nickname ?? person.name.given ?? 'Unknown';
        final isSelf = myself != null && person.id == myself!.id;

        return Chip(
          avatar: Icon(
            isSelf ? Icons.account_circle : Icons.person,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: Text(
            personName,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          onDeleted: () => onRemoveParticipant(activityIndex, participantIndex),
          deleteIcon: const Icon(Icons.close, size: 18),
        );
      }).toList(),
    );
  }

  Widget _buildPropertyRow(
    BuildContext context,
    SexualActivity sexualActivity,
  ) {
    final activityCategory =
        availableActivityCategories[activity.category.reference];

    // Use the current working activity state (not from provider)
    final currentActivity = activity;

    // Check if "Me" has this property
    final meParticipant = currentActivity.participants.firstWhere(
      (p) => myself != null && p.participant.reference == myself!.id,
      orElse: () => ActivityParticipant(
        participant: Reference(reference: '', resourceType: 'Person'),
        activityCounts: [],
      ),
    );
    final meActivityCount = meParticipant.activityCounts.firstWhere(
      (ac) => ac.activityReference.reference == sexualActivity.id,
      orElse: () => ActivityCount(
        activityReference: Reference(
          reference: '',
          resourceType: 'SexualActivity',
        ),
        count: 0,
      ),
    );
    final meHasProperty = meActivityCount.count > 0;

    // Determine if "Me" checkbox should be shown (hide if property or category requires partner)
    final activityRequiresPartner = activityCategory?.requiresPartner ?? false;
    final propertyRequiresPartner = sexualActivity.requiresPartner;
    final showMeOption = !activityRequiresPartner && !propertyRequiresPartner;

    // Get non-self participants who have this property
    final participantsWithProperty = <String>[];
    for (var participant in currentActivity.participants) {
      if (myself != null && participant.participant.reference == myself!.id) {
        continue; // Skip "Me"
      }
      final activityCount = participant.activityCounts.firstWhere(
        (ac) => ac.activityReference.reference == sexualActivity.id,
        orElse: () => ActivityCount(
          activityReference: Reference(
            reference: '',
            resourceType: 'SexualActivity',
          ),
          count: 0,
        ),
      );
      if (activityCount.count > 0) {
        participantsWithProperty.add(participant.participant.reference);
      }
    }

    // Check if this activity has any participants with this property marked
    final hasParticipantsWithProperty =
        participantsWithProperty.isNotEmpty || meHasProperty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: hasParticipantsWithProperty
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  sexualActivity.displayCharacter,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sexualActivity.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (sexualActivity.stiRisk)
                  Tooltip(
                    message: 'STI Risk',
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Colors.purple.shade700,
                    ),
                  )
                else if (sexualActivity.healthRisk)
                  Tooltip(
                    message: 'Health Risk',
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Colors.orange.shade700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // "Me" checkbox (only show if property doesn't require partner)
                if (myself != null && showMeOption)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PersonAvatar(
                          person: myself!,
                          radius: 20,
                          showName: true,
                          isSelected: meHasProperty,
                          count: meActivityCount.count > 0
                              ? meActivityCount.count
                              : null,
                          onTap: () {
                            toggleMyselfForProperty(
                              activityIndex,
                              sexualActivity.id,
                            );
                          },
                        ),
                        if (meHasProperty) ...[
                          const SizedBox(width: 4),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => incrementPropertyCount(
                                  activityIndex,
                                  sexualActivity.id,
                                  myself!.id,
                                ),
                                tooltip: 'Increase count',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => decrementPropertyCount(
                                  activityIndex,
                                  sexualActivity.id,
                                  myself!.id,
                                ),
                                tooltip: 'Decrease count',
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                // Other participants (iterate only participants added to this activity)
                ...currentActivity.participants
                    .where((p) {
                      // Filter out "Me" (already handled above)
                      return myself == null ||
                          p.participant.reference != myself!.id;
                    })
                    .map((participant) {
                      final personId = participant.participant.reference;
                      // Find person details from available persons
                      final person = availablePersons.firstWhere(
                        (p) => p.id == personId,
                        orElse: () => Person(
                          id: personId,
                          date: DateTime.now(),
                          name: const Name(given: 'Unknown'),
                        ),
                      );

                      final activityCount = participant.activityCounts
                          .firstWhere(
                            (ac) =>
                                ac.activityReference.reference ==
                                sexualActivity.id,
                            orElse: () => ActivityCount(
                              activityReference: Reference(
                                reference: '',
                                resourceType: 'SexualActivity',
                              ),
                              count: 0,
                            ),
                          );

                      final isSelected = activityCount.count > 0;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PersonAvatar(
                              person: person,
                              radius: 20,
                              showName: true,
                              isSelected: isSelected,
                              count: activityCount.count > 0
                                  ? activityCount.count
                                  : null,
                              onTap: () {
                                toggleParticipantForProperty(
                                  activityIndex,
                                  sexualActivity.id,
                                  personId,
                                );
                              },
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => incrementPropertyCount(
                                      activityIndex,
                                      sexualActivity.id,
                                      personId,
                                    ),
                                    tooltip: 'Increase count',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => decrementPropertyCount(
                                      activityIndex,
                                      sexualActivity.id,
                                      personId,
                                    ),
                                    tooltip: 'Decrease count',
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    })
                    .toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
