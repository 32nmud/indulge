import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/person_avatar.dart';
import 'package:indulge/view/common/sexual_event_editor/widgets/callbacks.dart';

/// A single row in the activities list, showing a sexual activity with
/// participant avatars, count controls, and role indicators.
class ActivityPropertyRow extends StatelessWidget {
  final SexualActivity sexualActivity;
  final EventActivity activity;
  final Map<String, SexualActivityCategory> availableActivityCategories;
  final List<Person> availablePersons;
  final Person? myself;
  final String? categoryId;
  final OnShowRolePicker onShowRolePicker;
  final OnToggleProperty onToggleProperty;
  final OnIncrementCount onIncrementCount;
  final OnDecrementCount onDecrementCount;
  final OnToggleSolo onToggleSolo;

  const ActivityPropertyRow({
    super.key,
    required this.sexualActivity,
    required this.activity,
    required this.availableActivityCategories,
    required this.availablePersons,
    required this.myself,
    this.categoryId,
    required this.onShowRolePicker,
    required this.onToggleProperty,
    required this.onIncrementCount,
    required this.onDecrementCount,
    required this.onToggleSolo,
  });

  @override
  Widget build(BuildContext context) {
    // Use the subcategory ID when provided so same-named activities in different
    // (sub)categories are keyed distinctly in ActivityCount.
    final categoryRef = categoryId ?? activity.category.reference;

    // Get current user's ActivityCount for solo toggle
    final myselfActivityCount = activity.participants
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
    for (var participant in activity.participants) {
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

    final hasParticipantsWithProperty = participantsWithProperty.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: hasParticipantsWithProperty
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityHeader(context, myselfActivityCount),
            if (!myselfActivityCount.solo) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _buildParticipantAvatars(context, categoryRef),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHeader(
    BuildContext context,
    ActivityCount myselfActivityCount,
  ) {
    return Row(
      children: [
        Text(
          sexualActivity.displayCharacter,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            sexualActivity.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        if (!sexualActivity.requiresPartner && sexualActivity.isActionable)
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
                  sexualActivity.name,
                  myself!.id,
                  categoryId: categoryId,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildParticipantAvatars(BuildContext context, String categoryRef) {
    final participants = <Widget>[];

    // Myself (if logged in) - only for non-actionable activities
    if (myself != null && !sexualActivity.isActionable)
      participants.add(_buildMyselfAvatar(context, categoryRef));

    // Other participants (excluding self)
    participants.addAll(
      activity.participants
          .where((p) => myself == null || p.participant.reference != myself!.id)
          .map(
            (participant) =>
                _buildParticipantAvatar(context, participant, categoryRef),
          ),
    );

    return SizedBox(
      height: 100,
      child: ListView(scrollDirection: Axis.horizontal, children: participants),
    );
  }

  Widget _buildMyselfAvatar(BuildContext context, String categoryRef) {
    final activityCount = activity.participants
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

    final isSelected = activityCount.count > 0;

    return _buildParticipantCard(
      context: context,
      person: myself!,
      activityCount: activityCount,
      categoryRef: categoryRef,
      isSelected: isSelected,
      personId: myself!.id,
    );
  }

  Widget _buildParticipantAvatar(
    BuildContext context,
    ActivityParticipant participant,
    String categoryRef,
  ) {
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

    final isSelected = activityCount.count > 0;

    return _buildParticipantCard(
      context: context,
      person: person,
      activityCount: activityCount,
      categoryRef: categoryRef,
      isSelected: isSelected,
      personId: personId,
    );
  }

  Widget _buildParticipantCard({
    required BuildContext context,
    required Person person,
    required ActivityCount activityCount,
    required String categoryRef,
    required bool isSelected,
    required String personId,
  }) {
    final personName = person.name.nickname ?? person.name.given ?? 'Unknown';

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      child: Card(
        elevation: isSelected ? 2 : 0,
        color: isSelected
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected
              ? BorderSide.none
              : BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.5),
                  width: 1,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Avatar+count left, name right
              Row(
                children: [
                  PersonAvatar(
                    person: person,
                    radius: 20,
                    showName: false,
                    isSelected: isSelected,
                    onTap: () => _onAvatarTap(
                      context,
                      isSelected,
                      personId: personId,
                      currentRole: activityCount.role,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      personName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Row 2: Role badge and +/- buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isSelected && sexualActivity.isActionable)
                    _buildRoleBadge(context, activityCount.role)
                  else
                    const SizedBox.shrink(),
                  _buildCountButtons(
                    context,
                    categoryRef,
                    personId,
                    isSelected,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountButtons(
    BuildContext context,
    String categoryRef,
    String personId,
    bool isSelected,
  ) {
    final count = _getCount(categoryRef, personId);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSelected)
          GestureDetector(
            onTap: () => onDecrementCount(
              sexualActivity.name,
              personId,
              categoryId: categoryRef,
            ),
            child: Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
          )
        else
          const SizedBox(width: 20),
        Container(
          constraints: const BoxConstraints(minWidth: 24),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _onIncrementTap(context, isSelected, personId: personId),
          child: Icon(
            Icons.add_circle_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  int _getCount(String categoryRef, String personId) {
    final participant = activity.participants.firstWhere(
      (p) => p.participant.reference == personId,
      orElse: () => const ActivityParticipant(),
    );
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
    return activityCount.count;
  }

  void _onAvatarTap(
    BuildContext context,
    bool isSelected, {
    String? personId,
    ActivityRole? currentRole,
  }) {
    final id = personId ?? myself!.id;
    final role = currentRole ?? ActivityRole.participated;

    if (isSelected) {
      // Toggle OFF - remove the activity
      onToggleProperty(sexualActivity.name, id, categoryId: categoryId);
    } else if (sexualActivity.hasRoles) {
      // Toggle ON - show role picker for activities with roles
      onShowRolePicker(
        context,
        sexualActivity.name,
        id,
        role,
        categoryId: categoryId,
      );
    } else {
      // Toggle ON - for activities without roles, just mark as participated
      onToggleProperty(sexualActivity.name, id, categoryId: categoryId);
    }
  }

  void _onIncrementTap(
    BuildContext context,
    bool isSelected, {
    String? personId,
  }) {
    if (isSelected) {
      // Already added - just increment the count
      onIncrementCount(
        sexualActivity.name,
        personId ?? myself!.id,
        categoryId: categoryId,
      );
    } else {
      // Not added - show role picker and add participant
      final id = personId ?? myself!.id;
      if (sexualActivity.hasRoles) {
        onShowRolePicker(
          context,
          sexualActivity.name,
          id,
          ActivityRole.participated,
          categoryId: categoryId,
        );
      } else {
        // For activities without roles, just mark as participated
        onToggleProperty(sexualActivity.name, id, categoryId: categoryId);
      }
    }
  }

  Widget _buildRoleBadge(BuildContext context, ActivityRole role) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _roleLabel(role),
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  String _roleLabel(ActivityRole role) {
    switch (role) {
      case ActivityRole.give:
        return 'Gave';
      case ActivityRole.receive:
        return 'Received';
      case ActivityRole.both:
        return 'Both';
      case ActivityRole.participated:
        return 'Participated';
    }
  }
}
