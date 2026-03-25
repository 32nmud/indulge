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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Myself (if logged in) - only for non-actionable activities
        if (myself != null && !sexualActivity.isActionable)
          _buildMyselfAvatar(context, categoryRef),

        // Other participants (excluding self)
        ...activity.participants
            .where(
              (p) => myself == null || p.participant.reference != myself!.id,
            )
            .map(
              (participant) =>
                  _buildParticipantAvatar(context, participant, categoryRef),
            ),
      ],
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
                person: myself!,
                radius: 20,
                showName: true,
                isSelected: isSelected,
                onTap: () => _onAvatarTap(context, isSelected),
              ),
              if (isSelected && sexualActivity.isActionable)
                _buildRoleBadge(context, activityCount.role),
            ],
          ),
          if (isSelected) _buildCountControls(context, categoryRef),
        ],
      ),
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
                onTap: () => _onAvatarTap(
                  context,
                  isSelected,
                  personId: personId,
                  currentRole: activityCount.role,
                ),
              ),
              if (isSelected && sexualActivity.isActionable)
                _buildRoleBadge(context, activityCount.role),
            ],
          ),
          if (isSelected)
            _buildCountControls(context, categoryRef, personId: personId),
        ],
      ),
    );
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

  Widget _buildCountControls(
    BuildContext context,
    String categoryRef, {
    String? personId,
  }) {
    final id = personId ?? myself!.id;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => onIncrementCount(
              sexualActivity.name,
              id,
              categoryId: categoryId,
            ),
            tooltip: 'Increase count',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_getCount(categoryRef, id)}',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => onDecrementCount(
              sexualActivity.name,
              id,
              categoryId: categoryId,
            ),
            tooltip: 'Decrease count',
          ),
        ],
      ),
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
