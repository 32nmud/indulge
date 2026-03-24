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

  // Subcategory data (resolved by parent)
  final List<SexualActivityCategory> subcategories;

  // UI state / actions
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onRemove;
  final VoidCallback onShowPersonPicker;
  final void Function(
    int activityIndex,
    String activityName,
    String personId, {
    String? categoryId,
  })
  onToggleSolo;

  // Toggle participant activity with role selection
  final void Function(
    int activityIndex,
    String activityName,
    String personId,
    ActivityRole role, {
    String? categoryId,
  })
  onToggleParticipantActivity;

  // Property/participant interactions
  final void Function(
    int activityIndex,
    String activityName,
    String personId, {
    String? categoryId,
  })
  toggleParticipantForProperty;
  final void Function(
    int activityIndex,
    String activityName,
    String personId, {
    String? categoryId,
  })
  incrementPropertyCount;
  final void Function(
    int activityIndex,
    String activityName,
    String personId, {
    String? categoryId,
  })
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
    required this.subcategories,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onRemove,
    required this.onShowPersonPicker,
    required this.onToggleSolo,
    required this.toggleParticipantForProperty,
    required this.incrementPropertyCount,
    required this.decrementPropertyCount,
    required this.onToggleParticipantActivity,
    required this.onRemoveParticipant,
  });

  /// Check if the current user has any solo activities in this category
  bool get _userHasSoloActivity {
    if (myself == null) return false;
    final myParticipant = activity.participants.firstWhere(
      (p) => p.participant.reference == myself!.id,
      orElse: () => const ActivityParticipant(),
    );
    return myParticipant.activityCounts.any((ac) => ac.solo);
  }

  @override
  Widget build(BuildContext context) {
    final activityCategory =
        availableActivityCategories[activity.category.reference];
    final emoji = activityCategory?.displayCharacter ?? '❔';
    final name = activityCategory?.name ?? 'Unknown';

    // Activities are directly embedded in the category as List<SexualActivity>.
    // When subcategories exist the flat list is intentionally left empty — each
    // subcategory renders its own ExpansionTile instead.
    final availableSexualActivities = <SexualActivity>[];
    if (subcategories.isEmpty && activityCategory != null) {
      availableSexualActivities.addAll(activityCategory.activities);
      availableSexualActivities.sort(
        (a, b) => a.sortOrder.compareTo(b.sortOrder),
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
                      if (!_userHasSoloActivity)
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
                                  : 'Add other participants, or toggle activities below to track your own participation',
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
                  // Activities section — flat list when no subcategories exist
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
                  // Activities section — one ExpansionTile per subcategory
                  if (subcategories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...subcategories.map(
                      (sub) => _buildSubcategoryTile(context, sub),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubcategoryTile(
    BuildContext context,
    SexualActivityCategory sub,
  ) {
    final subcategoryId = sub.id;
    final activities = List<SexualActivity>.from(sub.activities)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Count how many activities in this subcategory have any participation
    final categoryRef = activity.category.reference;
    final activeCount = activities.where((sexualActivity) {
      return activity.participants.any((participant) {
        return participant.activityCounts.any(
          (ac) =>
              ac.activityName == sexualActivity.name &&
              ac.categoryReference.reference == categoryRef,
        );
      });
    }).length;

    final title = sub.displayCharacter != null
        ? '${sub.displayCharacter}  ${sub.name}'
        : sub.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (activeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        children: activities.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No activities in this category.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ]
            : activities
                  .map(
                    (sexualActivity) => _buildPropertyRow(
                      context,
                      sexualActivity,
                      categoryId: subcategoryId,
                    ),
                  )
                  .toList(),
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
            style: const TextStyle(fontWeight: FontWeight.bold),
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
    SexualActivity sexualActivity, {
    String? categoryId,
  }) {
    final activityCategory =
        availableActivityCategories[activity.category.reference];

    // Use the current working activity state (not from provider)
    final currentActivity = activity;
    // Use the subcategory ID when provided so same-named activities in different
    // (sub)categories are keyed distinctly in ActivityCount.
    final categoryRef = categoryId ?? activity.category.reference;

    // Get current user's ActivityCount for solo toggle
    final myselfActivityCount = currentActivity.participants
        .where((p) => myself != null && p.participant.reference == myself!.id)
        .expand((p) => p.activityCounts)
        .cast<ActivityCount>()
        .firstWhere(
          (ac) =>
              ac.activityName == sexualActivity.name &&
              ac.categoryReference.reference == categoryRef,
          orElse: () => ActivityCount(
            categoryReference: Reference(
              reference: categoryRef,
              resourceType: 'SexualActivityCategory',
            ),
            activityName: sexualActivity.name,
            count: 0,
          ),
        );

    // Get participants who have this activity marked
    final participantsWithProperty = <String>[];
    for (var participant in currentActivity.participants) {
      if (myself != null && participant.participant.reference == myself!.id) {
        continue; // Skip self
      }
      final activityCount = participant.activityCounts.firstWhere(
        (ac) =>
            ac.activityName == sexualActivity.name &&
            ac.categoryReference.reference == categoryRef,
        orElse: () => ActivityCount(
          categoryReference: Reference(
            reference: categoryRef,
            resourceType: 'SexualActivityCategory',
          ),
          activityName: sexualActivity.name,
          count: 0,
        ),
      );
      if (activityCount.count > 0) {
        participantsWithProperty.add(participant.participant.reference);
      }
    }

    // Check if this activity has any participants with this activity marked
    final hasParticipantsWithProperty = participantsWithProperty.isNotEmpty;

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
                if (!sexualActivity.requiresPartner)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Solo',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Switch(
                        value: myselfActivityCount.solo,
                        onChanged: (value) => onToggleSolo(
                          activityIndex,
                          sexualActivity.name,
                          myself!.id,
                          categoryId: categoryId,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (!myselfActivityCount.solo) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Other participants (excluding self)
                  ...currentActivity.participants
                      .where(
                        (p) =>
                            myself == null ||
                            p.participant.reference != myself!.id,
                      )
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
                                  ac.activityName == sexualActivity.name &&
                                  ac.categoryReference.reference == categoryRef,
                              orElse: () => ActivityCount(
                                categoryReference: Reference(
                                  reference: categoryRef,
                                  resourceType: 'SexualActivityCategory',
                                ),
                                activityName: sexualActivity.name,
                                count: 0,
                              ),
                            );

                        final isSelected = activityCount.count > 0;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PersonAvatar(
                                    person: person,
                                    radius: 20,
                                    showName: true,
                                    isSelected: isSelected,
                                    onTap: () {
                                      if (isSelected) {
                                        // Toggle OFF - remove the activity
                                        toggleParticipantForProperty(
                                          activityIndex,
                                          sexualActivity.name,
                                          personId,
                                          categoryId: categoryId,
                                        );
                                      } else {
                                        // Toggle ON - show role picker
                                        _showRolePicker(
                                          context,
                                          activityIndex,
                                          sexualActivity.name,
                                          personId,
                                          activityCount.role,
                                          categoryId: categoryId,
                                        );
                                      }
                                    },
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _roleLabel(activityCount.role),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 16,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => incrementPropertyCount(
                                        activityIndex,
                                        sexualActivity.name,
                                        personId,
                                        categoryId: categoryId,
                                      ),
                                      tooltip: 'Increase count',
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${activityCount.count}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 16,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => decrementPropertyCount(
                                        activityIndex,
                                        sexualActivity.name,
                                        personId,
                                        categoryId: categoryId,
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
          ],
        ),
      ),
    );
  }

  Future<void> _showRolePicker(
    BuildContext context,
    int activityIndex,
    String activityName,
    String personId,
    ActivityRole currentRole, {
    String? categoryId,
  }) async {
    var selectedRole = currentRole;
    final role = await showDialog<ActivityRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ActivityRole.values.map((role) {
            return ListTile(
              leading: Radio<ActivityRole>(
                value: role,
                groupValue: selectedRole,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.of(context).pop(value);
                  }
                },
              ),
              title: Text(_roleLabel(role)),
              onTap: () {
                Navigator.of(context).pop(role);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (role != null) {
      onToggleParticipantActivity(
        activityIndex,
        activityName,
        personId,
        role,
        categoryId: categoryId,
      );
    }
  }

  String _roleLabel(ActivityRole role) {
    switch (role) {
      case ActivityRole.give:
        return 'Give';
      case ActivityRole.receive:
        return 'Receive';
      case ActivityRole.both:
        return 'Both';
      case ActivityRole.participated:
        return 'Participated';
    }
  }
}
