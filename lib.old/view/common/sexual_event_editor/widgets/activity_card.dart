import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/sexual_event_editor/widgets/activity_card_header.dart';
import 'package:indulge/view/common/sexual_event_editor/widgets/activity_card_participants_section.dart';
import 'package:indulge/view/common/sexual_event_editor/widgets/activity_card_subcategory_tile.dart';
import 'package:indulge/view/common/sexual_event_editor/widgets/activity_property_row.dart';
import 'package:indulge/view/common/sexual_event_editor/widgets/role_picker_dialog.dart';

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
          ActivityCardHeader(
            activityCategory: activityCategory,
            emoji: emoji,
            name: name,
            isExpanded: isExpanded,
            onToggleExpanded: onToggleExpanded,
            onRemove: onRemove,
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
                  ActivityCardParticipantsSection(
                    participants: activity.participants,
                    availablePersons: availablePersons,
                    myself: myself,
                    userHasSoloActivity: _userHasSoloActivity,
                    requiresPartner: activityCategory?.requiresPartner ?? false,
                    onShowPersonPicker: onShowPersonPicker,
                    onRemoveParticipant: (participantIndex) =>
                        onRemoveParticipant(activityIndex, participantIndex),
                  ),
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
                      return ActivityPropertyRow(
                        sexualActivity: sexualActivity,
                        activity: activity,
                        availableActivityCategories:
                            availableActivityCategories,
                        availablePersons: availablePersons,
                        myself: myself,
                        categoryId: null,
                        onShowRolePicker: _handleShowRolePicker,
                        onToggleProperty: _handleToggleProperty,
                        onIncrementCount: _handleIncrementCount,
                        onDecrementCount: _handleDecrementCount,
                        onToggleSolo: _handleToggleSolo,
                      );
                    }),
                  ],
                  // Activities section — one ExpansionTile per subcategory
                  if (subcategories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...subcategories.map(
                      (sub) => ActivityCardSubcategoryTile(
                        subcategory: sub,
                        activity: activity,
                        availableActivityCategories:
                            availableActivityCategories,
                        availablePersons: availablePersons,
                        myself: myself,
                        onShowRolePicker: _handleShowRolePicker,
                        onToggleProperty: _handleToggleProperty,
                        onIncrementCount: _handleIncrementCount,
                        onDecrementCount: _handleDecrementCount,
                        onToggleSolo: _handleToggleSolo,
                      ),
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

  // Handlers that adapt callbacks to include activityIndex

  Future<void> _handleShowRolePicker(
    BuildContext context,
    String activityName,
    String personId,
    ActivityRole currentRole, {
    String? categoryId,
  }) async {
    final role = await showRolePickerDialog(context, currentRole);
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

  void _handleToggleProperty(
    String activityName,
    String personId, {
    String? categoryId,
  }) {
    toggleParticipantForProperty(
      activityIndex,
      activityName,
      personId,
      categoryId: categoryId,
    );
  }

  void _handleIncrementCount(
    String activityName,
    String personId, {
    String? categoryId,
  }) {
    incrementPropertyCount(
      activityIndex,
      activityName,
      personId,
      categoryId: categoryId,
    );
  }

  void _handleDecrementCount(
    String activityName,
    String personId, {
    String? categoryId,
  }) {
    decrementPropertyCount(
      activityIndex,
      activityName,
      personId,
      categoryId: categoryId,
    );
  }

  void _handleToggleSolo(
    String activityName,
    String personId, {
    String? categoryId,
  }) {
    onToggleSolo(activityIndex, activityName, personId, categoryId: categoryId);
  }
}
