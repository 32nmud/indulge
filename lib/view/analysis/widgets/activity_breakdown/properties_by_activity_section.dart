import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/data/models.dart';
import '../common/expandable_activity_card.dart';
import 'package:indulge/view/common/dialogs/category_filter_dialog.dart';
import 'package:indulge/services/preferences_service.dart';
import '../../models/analysis_event_type.dart';
import '../../models/activity_breakdown_data.dart';

class PropertiesByActivitySection extends StatefulWidget {
  final ActivityBreakdownData data;
  final AnalysisEventType? filterType;

  const PropertiesByActivitySection({
    super.key,
    required this.data,
    this.filterType,
  });

  @override
  State<PropertiesByActivitySection> createState() =>
      _PropertiesByActivitySectionState();
}

class _PropertiesByActivitySectionState
    extends State<PropertiesByActivitySection> {
  final Set<String> _expandedActivities = {};

  @override
  void initState() {
    super.initState();
    // No manual listeners here — we'll use ValueListenableBuilder in build().
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> counts;
    if (widget.filterType == null) {
      counts = widget.data.activityCountsThisYear;
    } else {
      counts = widget.data.activityCountsByType[widget.filterType!] ?? {};
    }

    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort activities by count
    final sortedActivities = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Acquire PreferencesService once (no listen) and use its notifier with
    // ValueListenableBuilder so only the filtered portion rebuilds when prefs change.
    final prefs = Provider.of<PreferencesService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The icon and the list both depend on the persisted selection.
            // Use a single ValueListenableBuilder to rebuild them together but
            // avoid AnimatedSize / ticker usage so height changes don't rely on
            // an animation controller which could interact with scrolling.
            ValueListenableBuilder<List<String>>(
              valueListenable: prefs.propertiesCategorySelectedIdsNotifier,
              builder: (context, selectedList, _) {
                final selectedSet = selectedList.toSet();

                // Header row: title + icon button (updates with selection)
                final header = Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activities by Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        selectedSet.isEmpty
                            ? Icons.filter_list
                            : Icons.filter_list_alt,
                        color: selectedSet.isNotEmpty
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () =>
                          _showCategoryFilter(context, prefs, selectedSet),
                      tooltip: 'Filter categories',
                    ),
                  ],
                );

                final visibleEntries = sortedActivities.where((entry) {
                  if (selectedSet.isEmpty) return true;
                  return selectedSet.contains(entry.key);
                }).toList();

                // If nothing is visible due to a filter, show a helpful message.
                if (visibleEntries.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No categories match the selected filter.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ],
                  );
                }

                // Normal content: header + filtered list of ExpandableActivityCard
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 16),
                    Column(
                      children: visibleEntries.map((entry) {
                        final activityTypeId = entry.key;
                        final activityCount = entry.value;
                        final activityCategory =
                            widget.data.activityCategories[activityTypeId];
                        final isExpanded = _expandedActivities.contains(
                          activityTypeId,
                        );

                        // Get properties for this activity type from the events
                        final activityProperties = _getPropertiesForActivity(
                          activityTypeId,
                        );

                        // Get enriched properties (from data and provider)
                        final enrichedProperties = _getEnrichedProperties(
                          activityProperties.keys.toSet(),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ExpandableActivityCard(
                            title: activityCategory?.name ?? 'Unknown',
                            emoji: activityCategory?.displayCharacter,
                            subtitle:
                                '$activityCount activit${activityCount != 1 ? 'ies' : 'y'}',
                            badgeCount: activityProperties.length,
                            badgeLabel: activityProperties.length == 1
                                ? 'activity'
                                : 'activities',
                            isExpanded: isExpanded,
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedActivities.remove(activityTypeId);
                                } else {
                                  _expandedActivities.add(activityTypeId);
                                }
                              });
                            },
                            activityCountsMap: activityProperties,
                            availableActivities: enrichedProperties,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Get enriched properties (from data and provider state)
  Map<String, SexualActivity> _getEnrichedProperties(Set<String> propertyIds) {
    final result = <String, SexualActivity>{};

    for (final propertyId in propertyIds) {
      var property = widget.data.sexualActivities[propertyId];

      if (property == null) {
        final store = context.read<EventStateStore>();
        property = store.state.sexualActivities?[propertyId];
      }

      if (property != null) {
        result[propertyId] = property;
      }
    }

    return result;
  }

  /// Get properties used for a specific activity type with their counts
  Map<String, int> _getPropertiesForActivity(String activityTypeId) {
    final propertyCountsForActivity = <String, int>{};

    List<SexualEvent> events;
    if (widget.filterType == null) {
      events = widget.data.events;
    } else {
      events = widget.data.eventsByType[widget.filterType!] ?? [];
    }

    for (final event in events) {
      for (final activity in event.activities) {
        if (activity.category.reference == activityTypeId) {
          for (final participant in activity.participants) {
            for (final activityCount in participant.activityCounts) {
              // Use categoryReference + activityName as the activity identifier
              final catRef = activityCount.categoryReference.reference;
              final actName = activityCount.activityName;
              final activityId = '$catRef:$actName';
              propertyCountsForActivity[activityId] =
                  (propertyCountsForActivity[activityId] ?? 0) +
                  activityCount.count;
            }
          }
        }
      }
    }

    // Sort by count descending
    final sortedEntries = propertyCountsForActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  Future<void> _showCategoryFilter(
    BuildContext context,
    PreferencesService prefs,
    Set<String> currentSelected,
  ) async {
    final categoriesMap = widget.data.activityCategories;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => CategoryFilterDialog(
        categoriesMap: categoriesMap,
        selectedIds: currentSelected,
      ),
    );

    if (result != null) {
      // Persist the user's selection via PreferencesService; allow the notifier
      // to update the UI via ValueListenableBuilder. If persistence fails,
      // fall back to updating local expanded state only (no preferences change).
      try {
        await prefs.setPropertiesCategorySelectedIds(result.toList());
      } catch (_) {
        // Best-effort fallback: do nothing (the UI remains as-is). Avoid local
        // setState here to prevent layout changes while scrolling.
      }
    }
  }
}
