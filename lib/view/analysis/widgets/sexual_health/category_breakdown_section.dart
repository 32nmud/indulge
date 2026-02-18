import 'package:flutter/material.dart';
import '../../models/sexual_health_analysis_data.dart';
import '../common/expandable_activity_card.dart';

/// Widget showing risky activity breakdown by category for the sexual health period.
class CategoryBreakdownSection extends StatefulWidget {
  final SexualHealthAnalysisData data;

  const CategoryBreakdownSection({super.key, required this.data});

  @override
  State<CategoryBreakdownSection> createState() =>
      _CategoryBreakdownSectionState();
}

class _CategoryBreakdownSectionState extends State<CategoryBreakdownSection> {
  final Set<String> _expandedCategories = {};

  @override
  Widget build(BuildContext context) {
    if (widget.data.riskyActivityCountsByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort categories by risky activity count
    final sortedCategories =
        widget.data.riskyActivityCountsByCategory.entries.toList()
          ..sort((a, b) {
            // Sort by total count across all activities in the category
            final aCount = a.value.values.fold<int>(0, (sum, v) => sum + v);
            final bCount = b.value.values.fold<int>(0, (sum, v) => sum + v);
            return bCount.compareTo(aCount);
          });

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Risky Activities',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Risky activities by category',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.map((entry) {
              final categoryId = entry.key;
              final activityCounts = entry.value;
              final category = widget.data.activityCategories[categoryId];
              final isExpanded = _expandedCategories.contains(categoryId);

              // Calculate total risky count for this category
              final totalCount = activityCounts.values.fold<int>(
                0,
                (sum, v) => sum + v,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExpandableActivityCard(
                  title: category?.name ?? 'Unknown',
                  emoji: category?.displayCharacter,
                  subtitle:
                      '$totalCount risky activit${totalCount == 1 ? 'y' : 'ies'}',
                  badgeCount: activityCounts.length,
                  badgeLabel: activityCounts.length == 1
                      ? 'activity'
                      : 'activities',
                  isExpanded: isExpanded,
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedCategories.remove(categoryId);
                      } else {
                        _expandedCategories.add(categoryId);
                      }
                    });
                  },
                  activityCountsMap: activityCounts,
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
