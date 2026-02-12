import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/analysis_data.dart';
import '../common/expandable_activity_card.dart';
import 'package:indulge/view/common/dialogs/category_filter_dialog.dart';
import 'package:indulge/services/preferences_service.dart';

class PropertyPartnerSection extends StatefulWidget {
  final AnalysisData data;

  const PropertyPartnerSection({super.key, required this.data});

  @override
  State<PropertyPartnerSection> createState() => _PropertyPartnerSectionState();
}

class _PropertyPartnerSectionState extends State<PropertyPartnerSection> {
  final Set<String> _expandedActivities = {};

  @override
  Widget build(BuildContext context) {
    if (widget.data.categoryPartnerCountsThisYear.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort categories by unique partner count
    final sortedCategories =
        widget.data.categoryPartnerCountsThisYear.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final prefs = Provider.of<PreferencesService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + filter state are driven by the partner-specific notifier.
            ValueListenableBuilder<List<String>>(
              valueListenable:
                  prefs.partnerPropertiesCategorySelectedIdsNotifier,
              builder: (context, selectedList, _) {
                final selectedSet = selectedList.toSet();

                // Header
                final header = Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Partner Diversity by Category',
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

                final visibleCategories = sortedCategories.where((entry) {
                  if (selectedSet.isEmpty) return true;
                  return selectedSet.contains(entry.key);
                }).toList();

                // Subtitle and helper text
                final subtitle = Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Number of unique partners per category and activity',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );

                if (visibleCategories.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      subtitle,
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    subtitle,
                    const SizedBox(height: 16),
                    Column(
                      children: visibleCategories.map((entry) {
                        final categoryId = entry.key;
                        final partnerCount = entry.value;
                        final category =
                            widget.data.activityCategories[categoryId];
                        final isExpanded = _expandedActivities.contains(
                          categoryId,
                        );

                        // Get activities for this category with their unique partner counts
                        final categoryActivityPartnerCounts =
                            widget
                                .data
                                .categoryActivityPartnerCountsThisYear[categoryId] ??
                            {};

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ExpandableActivityCard(
                            title: category?.name ?? 'Unknown',
                            emoji: category?.displayCharacter,
                            subtitle:
                                '$partnerCount unique partner${partnerCount != 1 ? 's' : ''}',
                            badgeCount: categoryActivityPartnerCounts.length,
                            badgeLabel:
                                categoryActivityPartnerCounts.length == 1
                                ? 'activity'
                                : 'activities',
                            isExpanded: isExpanded,
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedActivities.remove(categoryId);
                                } else {
                                  _expandedActivities.add(categoryId);
                                }
                              });
                            },
                            activityCountsMap: categoryActivityPartnerCounts,
                            availableActivities: widget.data.sexualActivities,
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

  Future<void> _showCategoryFilter(
    BuildContext context,
    PreferencesService prefs,
    Set<String> currentSelected,
  ) async {
    final categories = widget.data.activityCategories.values.toList();

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => CategoryFilterDialog(
        categories: categories,
        selectedIds: currentSelected,
      ),
    );

    if (result != null) {
      try {
        await prefs.setPartnerPropertiesCategorySelectedIds(result.toList());
      } catch (_) {
        // Best-effort fallback: update notifier value directly so UI reflects choice.
        prefs.partnerPropertiesCategorySelectedIdsNotifier.value =
            List.unmodifiable(result.toList());
      }
    }
  }
}
