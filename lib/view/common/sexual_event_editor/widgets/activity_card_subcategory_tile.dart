import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/sexual_event_editor/widgets/activity_property_row.dart';
import 'package:indulge/view/common/sexual_event_editor/widgets/callbacks.dart';

/// A subcategory tile within an [ActivityCard], showing an expandable
/// section of activities for a given subcategory.
class ActivityCardSubcategoryTile extends StatelessWidget {
  final SexualActivityCategory subcategory;
  final EventActivity activity;
  final Map<String, SexualActivityCategory> availableActivityCategories;
  final List<Person> availablePersons;
  final Person? myself;
  final OnShowRolePicker onShowRolePicker;
  final OnToggleProperty onToggleProperty;
  final OnIncrementCount onIncrementCount;
  final OnDecrementCount onDecrementCount;
  final OnToggleSolo onToggleSolo;

  const ActivityCardSubcategoryTile({
    super.key,
    required this.subcategory,
    required this.activity,
    required this.availableActivityCategories,
    required this.availablePersons,
    required this.myself,
    required this.onShowRolePicker,
    required this.onToggleProperty,
    required this.onIncrementCount,
    required this.onDecrementCount,
    required this.onToggleSolo,
  });

  @override
  Widget build(BuildContext context) {
    final subcategoryId = subcategory.id;
    final activities = List<SexualActivity>.from(subcategory.activities)
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

    final title = subcategory.displayCharacter != null
        ? '${subcategory.displayCharacter}  ${subcategory.name}'
        : subcategory.name;

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
                    (sexualActivity) => ActivityPropertyRow(
                      sexualActivity: sexualActivity,
                      activity: activity,
                      availableActivityCategories: availableActivityCategories,
                      availablePersons: availablePersons,
                      myself: myself,
                      categoryId: subcategoryId,
                      onShowRolePicker: onShowRolePicker,
                      onToggleProperty: onToggleProperty,
                      onIncrementCount: onIncrementCount,
                      onDecrementCount: onDecrementCount,
                      onToggleSolo: onToggleSolo,
                    ),
                  )
                  .toList(),
      ),
    );
  }
}
