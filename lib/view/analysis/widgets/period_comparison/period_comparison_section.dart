import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/analysis_event_type.dart';
import '../../models/period_comparison_data.dart';

/// Quick-select presets for period comparison.
enum PeriodPreset {
  lastYearVsThisYear,
  lastMonthVsThisMonth,
  lastWeekVsThisWeek,
  custom,
}

class PeriodComparisonSection extends StatelessWidget {
  final PeriodComparisonData data;
  final PeriodPreset selectedPreset;
  final DateTimeRange? customFirstPeriod;
  final DateTimeRange? customSecondPeriod;
  final ValueChanged<PeriodPreset> onPresetChanged;
  final ValueChanged<DateTimeRange?> onCustomFirstPeriodChanged;
  final ValueChanged<DateTimeRange?> onCustomSecondPeriodChanged;

  const PeriodComparisonSection({
    super.key,
    required this.data,
    required this.selectedPreset,
    required this.onPresetChanged,
    this.customFirstPeriod,
    this.customSecondPeriod,
    required this.onCustomFirstPeriodChanged,
    required this.onCustomSecondPeriodChanged,
  });

  /// Resolves the effective first period (baseline) based on preset or custom.
  DateTimeRange? get _effectiveFirstPeriod {
    switch (selectedPreset) {
      case PeriodPreset.lastYearVsThisYear:
        return _lastYear();
      case PeriodPreset.lastMonthVsThisMonth:
        return _lastMonth();
      case PeriodPreset.lastWeekVsThisWeek:
        return _lastWeek();
      case PeriodPreset.custom:
        return customFirstPeriod;
    }
  }

  /// Resolves the effective second period based on preset or custom.
  DateTimeRange? get _effectiveSecondPeriod {
    switch (selectedPreset) {
      case PeriodPreset.lastMonthVsThisMonth:
        return _thisMonth();
      case PeriodPreset.lastWeekVsThisWeek:
        return _thisWeek();
      case PeriodPreset.lastYearVsThisYear:
        return _thisYear();
      case PeriodPreset.custom:
        return customSecondPeriod;
    }
  }

  // ── Date range helpers ──────────────────────────────────────────────

  /// Previous calendar month, first day through last day.
  static DateTimeRange _lastMonth() {
    final now = DateTime.now();
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final lastOfPrevMonth = firstOfThisMonth.subtract(const Duration(days: 1));
    final firstOfPrevMonth = DateTime(
      lastOfPrevMonth.year,
      lastOfPrevMonth.month,
      1,
    );
    return DateTimeRange(start: firstOfPrevMonth, end: lastOfPrevMonth);
  }

  /// Current calendar month, first day through today.
  static DateTimeRange _thisMonth() {
    final now = DateTime.now();
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    return DateTimeRange(start: firstOfThisMonth, end: now);
  }

  /// Previous ISO week (Monday–Sunday).
  static DateTimeRange _lastWeek() {
    final now = DateTime.now();
    // Monday of the current week
    final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final mondayLastWeek = mondayThisWeek.subtract(const Duration(days: 7));
    final sundayLastWeek = mondayThisWeek.subtract(const Duration(days: 1));
    return DateTimeRange(
      start: DateTime(
        mondayLastWeek.year,
        mondayLastWeek.month,
        mondayLastWeek.day,
      ),
      end: DateTime(
        sundayLastWeek.year,
        sundayLastWeek.month,
        sundayLastWeek.day,
        23,
        59,
        59,
      ),
    );
  }

  /// Current ISO week (Monday through today).
  static DateTimeRange _thisWeek() {
    final now = DateTime.now();
    final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    return DateTimeRange(
      start: DateTime(
        mondayThisWeek.year,
        mondayThisWeek.month,
        mondayThisWeek.day,
      ),
      end: now,
    );
  }

  /// Previous calendar year (Jan 1 - Dec 31 of last year).
  static DateTimeRange _lastYear() {
    final now = DateTime.now();
    final lastYear = now.year - 1;
    final start = DateTime(lastYear, 1, 1);
    final end = DateTime(lastYear, 12, 31, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

  /// Current calendar year (Jan 1 of this year through today).
  static DateTimeRange _thisYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    return DateTimeRange(start: start, end: now);
  }

  // ── Preset labels ───────────────────────────────────────────────────

  static String presetLabel(PeriodPreset preset) {
    switch (preset) {
      case PeriodPreset.lastMonthVsThisMonth:
        return 'Month';
      case PeriodPreset.lastWeekVsThisWeek:
        return 'Week';
      case PeriodPreset.lastYearVsThisYear:
        return 'Year';
      case PeriodPreset.custom:
        return 'Custom';
    }
  }

  static String _presetSubtitle(PeriodPreset preset) {
    switch (preset) {
      case PeriodPreset.lastMonthVsThisMonth:
        return 'Last month vs this month';
      case PeriodPreset.lastWeekVsThisWeek:
        return 'Last week vs this week';
      case PeriodPreset.lastYearVsThisYear:
        return 'Last year vs this year';
      case PeriodPreset.custom:
        return 'Pick any two date ranges';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final firstPeriod = _effectiveFirstPeriod;
    final secondPeriod = _effectiveSecondPeriod;

    final firstPeriodStats = firstPeriod == null
        ? null
        : _calculatePeriodStats(firstPeriod);
    final secondPeriodStats = secondPeriod == null
        ? null
        : _calculatePeriodStats(secondPeriod);

    final hasComparison = firstPeriod != null && secondPeriod != null;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Period Comparison',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _presetSubtitle(selectedPreset),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // ── Quick preset chips ────────────────────────────────────
            _buildPresetChips(context),
            const SizedBox(height: 16),

            // ── Custom date pickers (only in custom mode) ─────────────
            if (selectedPreset == PeriodPreset.custom) ...[
              _buildPeriodSelector(
                context,
                title: 'Period 1 (baseline)',
                dateRange: customFirstPeriod,
                icon: Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => _selectPeriod(context, isFirst: true),
              ),
              const SizedBox(height: 12),
              _buildPeriodSelector(
                context,
                title: 'Period 2',
                dateRange: customSecondPeriod,
                icon: Icons.calendar_month,
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => _selectPeriod(context, isFirst: false),
              ),
            ] else ...[
              // Show read-only summary of the preset ranges
              _buildPresetRangeSummary(context, firstPeriod, secondPeriod),
            ],

            if (hasComparison &&
                firstPeriodStats != null &&
                secondPeriodStats != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Comparison Results
              _buildStatComparison(
                context,
                'Events',
                firstPeriodStats.events,
                secondPeriodStats.events,
                Icons.event,
              ),
              const SizedBox(height: 12),
              _buildStatComparison(
                context,
                'Unique Participants',
                firstPeriodStats.uniqueParticipants,
                secondPeriodStats.uniqueParticipants,
                Icons.people,
              ),
              const SizedBox(height: 12),
              _buildStatComparison(
                context,
                'Total Activities',
                firstPeriodStats.totalActivities,
                secondPeriodStats.totalActivities,
                Icons.list_alt,
              ),
              const SizedBox(height: 12),
              _buildStatComparison(
                context,
                'Unique Activities',
                firstPeriodStats.uniqueProperties,
                secondPeriodStats.uniqueProperties,
                Icons.label,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Event type breakdown
              Text(
                'Event Types',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildEventTypeComparison(
                context,
                firstPeriodStats,
                secondPeriodStats,
              ),
              const SizedBox(height: 16),
              // Average activities per event
              _buildAverageComparison(
                context,
                'Avg Activities/Event',
                firstPeriodStats.averageActivitiesPerEvent,
                secondPeriodStats.averageActivitiesPerEvent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Preset chips ──────────────────────────────────────────────────

  Widget _buildPresetChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PeriodPreset.values.map((preset) {
          final isSelected = selectedPreset == preset;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(presetLabel(preset)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onPresetChanged(preset);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Preset range read-only summary ────────────────────────────────

  Widget _buildPresetRangeSummary(
    BuildContext context,
    DateTimeRange? first,
    DateTimeRange? second,
  ) {
    final dateFormat = DateFormat('MMM d');
    final yearFormat = DateFormat('MMM d, yyyy');
    final theme = Theme.of(context);

    String formatRange(DateTimeRange? range, String fallback) {
      if (range == null) return fallback;
      final sameYear = range.start.year == range.end.year;
      if (sameYear && range.start.year == DateTime.now().year) {
        return '${dateFormat.format(range.start)} – ${dateFormat.format(range.end)}';
      }
      return '${yearFormat.format(range.start)} – ${yearFormat.format(range.end)}';
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.4),
              ),
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.primary.withOpacity(0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Period 1',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRange(first, '—'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.compare_arrows,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.4),
              ),
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.secondary.withOpacity(0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Period 2',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRange(second, '—'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Custom period selector (tap to open date range picker) ────────

  Widget _buildPeriodSelector(
    BuildContext context, {
    required String title,
    required DateTimeRange? dateRange,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final hasSelection = dateRange != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasSelection
                ? color
                : Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
          color: hasSelection ? color.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasSelection
                        ? '${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}'
                        : 'Tap to select',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hasSelection
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(hasSelection ? Icons.edit : Icons.add, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPeriod(
    BuildContext context, {
    required bool isFirst,
  }) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: data.events.isNotEmpty
          ? data.events
                .map((e) => e.date)
                .reduce((a, b) => a.isBefore(b) ? a : b)
          : DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: isFirst ? customFirstPeriod : customSecondPeriod,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: isFirst
                  ? Theme.of(ctx).colorScheme.primary
                  : Theme.of(ctx).colorScheme.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isFirst) {
        onCustomFirstPeriodChanged(picked);
      } else {
        onCustomSecondPeriodChanged(picked);
      }
    }
  }

  // ── Stat comparison row ───────────────────────────────────────────

  Widget _buildStatComparison(
    BuildContext context,
    String label,
    int firstValue,
    int secondValue,
    IconData icon,
  ) {
    final hasChange = firstValue != secondValue;
    final isIncrease = secondValue > firstValue;
    final changeColor = isIncrease ? Colors.green : Colors.red;
    final changeIcon = isIncrease ? Icons.trending_up : Icons.trending_down;

    double percentageChange = 0.0;
    if (hasChange && firstValue > 0) {
      percentageChange = ((secondValue - firstValue) / firstValue * 100).abs();
    } else if (hasChange && firstValue == 0 && secondValue > 0) {
      percentageChange = 100.0;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // First period
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Period 1',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstValue.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow or equals
              Icon(
                hasChange ? changeIcon : Icons.drag_handle,
                color: hasChange ? changeColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 8),
              // Second period
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Period 2',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      secondValue.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasChange) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: changeColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: changeColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${percentageChange.toStringAsFixed(1)}% ${isIncrease ? 'increase' : 'decrease'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Event type comparison ─────────────────────────────────────────

  Widget _buildEventTypeComparison(
    BuildContext context,
    _PeriodStats firstStats,
    _PeriodStats secondStats,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildEventTypeColumn(
            context,
            'Period 1',
            firstStats.soloEvents,
            firstStats.coupleEvents,
            firstStats.groupEvents,
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildEventTypeColumn(
            context,
            'Period 2',
            secondStats.soloEvents,
            secondStats.coupleEvents,
            secondStats.groupEvents,
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildEventTypeColumn(
    BuildContext context,
    String title,
    int solo,
    int couple,
    int group, {
    required bool isPrimary,
  }) {
    final color = isPrimary
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[700]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        _buildEventTypeStat(context, 'Solo', solo, Icons.person, color),
        const SizedBox(height: 4),
        _buildEventTypeStat(context, 'Couple', couple, Icons.people, color),
        const SizedBox(height: 4),
        _buildEventTypeStat(context, 'Group', group, Icons.groups, color),
      ],
    );
  }

  Widget _buildEventTypeStat(
    BuildContext context,
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Average comparison ────────────────────────────────────────────

  Widget _buildAverageComparison(
    BuildContext context,
    String label,
    double firstValue,
    double secondValue,
  ) {
    final hasChange = (firstValue - secondValue).abs() > 0.01;
    final isIncrease = secondValue > firstValue;
    final changeColor = isIncrease ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Period 1',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      firstValue.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                hasChange
                    ? (isIncrease ? Icons.trending_up : Icons.trending_down)
                    : Icons.drag_handle,
                color: hasChange ? changeColor : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Period 2',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      secondValue.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Period stats calculation ───────────────────────────────────────

  _PeriodStats _calculatePeriodStats(DateTimeRange range) {
    final periodEvents = data.events
        .where(
          (e) =>
              e.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(range.end.add(const Duration(days: 1))),
        )
        .toList();

    final events = periodEvents.length;

    // Count unique participants
    final participantIds = <String>{};
    for (final event in periodEvents) {
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          final id = participant.participant.reference;
          // Only include IDs present in personCounts (excludes "Me")
          if (id.isNotEmpty && data.personCounts.containsKey(id)) {
            participantIds.add(id);
          }
        }
      }
    }
    final uniqueParticipants = participantIds.length;

    // Count total activities
    final totalActivities = periodEvents.fold<int>(
      0,
      (sum, e) => sum + e.activities.length,
    );

    // Count unique properties (activity types)
    final propertyIds = <String>{};
    for (final event in periodEvents) {
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          for (final count in participant.activityCounts) {
            if (count.activityReference.reference.isNotEmpty) {
              propertyIds.add(count.activityReference.reference);
            }
          }
        }
      }
    }
    final uniqueProperties = propertyIds.length;

    // Count event types (solo, couple, group)
    bool isInRange(DateTime date) {
      return date.isAfter(range.start.subtract(const Duration(days: 1))) &&
          date.isBefore(range.end.add(const Duration(days: 1)));
    }

    final soloEvents = (data.eventsByType[AnalysisEventType.solo] ?? [])
        .where((e) => isInRange(e.date))
        .length;

    final coupleEvents = (data.eventsByType[AnalysisEventType.couple] ?? [])
        .where((e) => isInRange(e.date))
        .length;

    final groupEvents = (data.eventsByType[AnalysisEventType.group] ?? [])
        .where((e) => isInRange(e.date))
        .length;

    // Calculate average activities per event
    final averageActivitiesPerEvent = events > 0
        ? totalActivities / events
        : 0.0;

    return _PeriodStats(
      events: events,
      uniqueParticipants: uniqueParticipants,
      totalActivities: totalActivities,
      uniqueProperties: uniqueProperties,
      soloEvents: soloEvents,
      coupleEvents: coupleEvents,
      groupEvents: groupEvents,
      averageActivitiesPerEvent: averageActivitiesPerEvent,
    );
  }
}

class _PeriodStats {
  final int events;
  final int uniqueParticipants;
  final int totalActivities;
  final int uniqueProperties;
  final int soloEvents;
  final int coupleEvents;
  final int groupEvents;
  final double averageActivitiesPerEvent;

  _PeriodStats({
    required this.events,
    required this.uniqueParticipants,
    required this.totalActivities,
    required this.uniqueProperties,
    required this.soloEvents,
    required this.coupleEvents,
    required this.groupEvents,
    required this.averageActivitiesPerEvent,
  });
}
