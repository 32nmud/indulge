import 'package:flutter/material.dart';
import '../../models/analysis_data.dart';
import '../common/expandable_activity_card.dart';

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

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partner Diversity by Category',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Number of unique partners per category and activity',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.map((entry) {
              final categoryId = entry.key;
              final partnerCount = entry.value;
              final category = widget.data.activityCategories[categoryId];
              final isExpanded = _expandedActivities.contains(categoryId);

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
                  badgeLabel: categoryActivityPartnerCounts.length == 1
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
            }),
          ],
        ),
      ),
    );
  }
}
