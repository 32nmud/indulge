import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/navigation_helper.dart';
import '../../models/analysis_event_type.dart';
import '../../models/activity_breakdown_data.dart';

class ActivityTypeDistribution extends StatefulWidget {
  final ActivityBreakdownData data;
  final AnalysisEventType? filterType;

  const ActivityTypeDistribution({
    super.key,
    required this.data,
    this.filterType,
  });

  @override
  State<ActivityTypeDistribution> createState() =>
      _ActivityTypeDistributionState();
}

class _ActivityTypeDistributionState extends State<ActivityTypeDistribution> {
  int touchedIndex = -1;

  /// When non-null we are in drill-down mode showing this parent's subcategories.
  String? _drilledParentId;

  // ── Data helpers ────────────────────────────────────────────────────────

  /// Top-level counts (parent category IDs → count).
  Map<String, int> get _topLevelCounts {
    if (widget.filterType == null) {
      return widget.data.activityCountsThisYear;
    }
    return widget.data.activityCountsByType[widget.filterType!] ?? {};
  }

  /// Direct subcategory children of [parentId].
  List<SexualActivityCategory> _subsOf(String parentId) {
    final parent = widget.data.allCategoriesMap[parentId];
    if (parent == null) return [];
    final result = <SexualActivityCategory>[];
    for (final ref in parent.subCategories) {
      final sub = widget.data.allCategoriesMap[ref.reference];
      if (sub != null) result.add(sub);
    }
    return result;
  }

  /// Whether [parentId] has any direct subcategory children.
  bool _hasSubcategories(String parentId) {
    final parent = widget.data.allCategoriesMap[parentId];
    if (parent == null) return false;
    return parent.subCategories.any((ref) => ref.reference.isNotEmpty);
  }

  /// Build subcategory counts for the drilled-in parent by scanning events
  /// and reading ActivityCount.categoryReference.reference.
  Map<String, int> _subcategoryCountsFor(String parentId) {
    final subIds = _subsOf(parentId).map((s) => s.id).toSet();
    if (subIds.isEmpty) return {};

    final events = widget.filterType == null
        ? widget.data.events
        : (widget.data.eventsByType[widget.filterType!] ?? []);

    final counts = <String, int>{};
    for (final event in events) {
      for (final activity in event.activities) {
        // Only consider activity blocks logged under this parent.
        if (activity.category.reference != parentId) continue;
        for (final participant in activity.participants) {
          for (final ac in participant.activityCounts) {
            final id = ac.categoryReference.reference;
            if (subIds.contains(id)) {
              counts[id] = (counts[id] ?? 0) + 1;
            }
          }
        }
      }
    }
    return counts;
  }

  // ── Chart colours ────────────────────────────────────────────────────────

  static const List<Color> _colors = [
    Colors.blue,
    Colors.pink,
    Colors.purple,
    Colors.orange,
    Colors.green,
    Colors.teal,
    Colors.red,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_topLevelCounts.isEmpty) return const SizedBox.shrink();

    final isDrilled = _drilledParentId != null;
    final counts = isDrilled
        ? _subcategoryCountsFor(_drilledParentId!)
        : _topLevelCounts;

    // If we drilled in but there are actually no subcategory counts recorded
    // yet, fall back gracefully.
    final effectiveCounts = (isDrilled && counts.isEmpty)
        ? _topLevelCounts
        : counts;
    final effectiveDrilled = (isDrilled && counts.isEmpty) ? false : isDrilled;

    final parentCat = effectiveDrilled
        ? (widget.data.allCategoriesMap[_drilledParentId!] ??
              widget.data.activityCategories[_drilledParentId!])
        : null;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────────────
            Row(
              children: [
                if (effectiveDrilled) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Back to all categories',
                    onPressed: () => setState(() {
                      _drilledParentId = null;
                      touchedIndex = -1;
                    }),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveDrilled
                            ? '${parentCat?.displayCharacter != null ? '${parentCat!.displayCharacter} ' : ''}${parentCat?.name ?? 'Category'}'
                            : 'Category Breakdown',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        effectiveDrilled
                            ? 'Subcategory breakdown · tap to search'
                            : 'Tap a category to drill in or search',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Chart ────────────────────────────────────────────────────
            SizedBox(
              height: 220,
              child: _buildPieChart(context, effectiveCounts, effectiveDrilled),
            ),

            const SizedBox(height: 16),

            // ── Legend (2-column grid) ────────────────────────────────────
            _buildLegend(context, effectiveCounts, effectiveDrilled),
          ],
        ),
      ),
    );
  }

  // ── Pie chart ────────────────────────────────────────────────────────────

  Widget _buildPieChart(
    BuildContext context,
    Map<String, int> counts,
    bool isDrilled,
  ) {
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sortedEntries.fold<int>(0, (s, e) => s + e.value);
    if (total == 0) return const SizedBox.shrink();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Update hover highlight.
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              if (touchedIndex != -1) {
                setState(() => touchedIndex = -1);
              }
              return;
            }
            final idx = pieTouchResponse.touchedSection!.touchedSectionIndex;
            if (idx != touchedIndex) {
              setState(() => touchedIndex = idx);
            }

            // On tap-up: drill in (if parent with subs) or navigate to search.
            if (event is FlTapUpEvent &&
                idx >= 0 &&
                idx < sortedEntries.length) {
              final entry = sortedEntries[idx];
              _handleTap(context, entry.key, isDrilled);
            }
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(sortedEntries.length, (i) {
          final isTouched = i == touchedIndex;
          final entry = sortedEntries[i];
          final percentage = (entry.value / total * 100).round();
          return PieChartSectionData(
            color: _colors[i % _colors.length],
            value: entry.value.toDouble(),
            title: '$percentage%',
            radius: isTouched ? 65.0 : 55.0,
            titleStyle: TextStyle(
              fontSize: isTouched ? 16.0 : 12.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          );
        }),
      ),
    );
  }

  // ── Legend ───────────────────────────────────────────────────────────────

  Widget _buildLegend(
    BuildContext context,
    Map<String, int> counts,
    bool isDrilled,
  ) {
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sortedEntries.fold<int>(0, (s, e) => s + e.value);
    if (total == 0) return const SizedBox.shrink();

    // Group entries into rows of three for a 3-column layout.
    final rows = <List<MapEntry<String, int>>>[];
    for (var i = 0; i < sortedEntries.length; i += 3) {
      rows.add([
        sortedEntries[i],
        if (i + 1 < sortedEntries.length) sortedEntries[i + 1],
        if (i + 2 < sortedEntries.length) sortedEntries[i + 2],
      ]);
    }

    return Column(
      children: rows.map((pair) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: pair.map((entry) {
            final globalIndex = sortedEntries.indexOf(entry);
            final cat =
                widget.data.allCategoriesMap[entry.key] ??
                widget.data.activityCategories[entry.key];
            final color = _colors[globalIndex % _colors.length];
            final percentage = (entry.value / total * 100).round();
            final canDrillIn = !isDrilled && _hasSubcategories(entry.key);

            return Expanded(
              child: InkWell(
                onTap: () => _handleTap(context, entry.key, isDrilled),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  cat?.displayCharacter ?? '❓',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (canDrillIn) ...[
                                  const SizedBox(width: 1),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              cat?.name ?? 'Unknown',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${entry.value} ($percentage%)',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  // ── Tap handler ──────────────────────────────────────────────────────────

  void _handleTap(BuildContext context, String categoryId, bool isDrilled) {
    if (!isDrilled && _hasSubcategories(categoryId)) {
      // Drill into this parent's subcategory breakdown.
      setState(() {
        _drilledParentId = categoryId;
        touchedIndex = -1;
      });
    } else {
      // Navigate to search filtered by this category.
      NavigationHelper.of(context)?.navigateToSearchWithCategory(categoryId);
    }
  }
}
