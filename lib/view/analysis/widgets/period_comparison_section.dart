import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/analysis_data.dart';

class PeriodComparisonSection extends StatefulWidget {
  final AnalysisData data;

  const PeriodComparisonSection({super.key, required this.data});

  @override
  State<PeriodComparisonSection> createState() =>
      _PeriodComparisonSectionState();
}

class _PeriodComparisonSectionState extends State<PeriodComparisonSection> {
  DateTimeRange? _firstPeriod;
  DateTimeRange? _secondPeriod;

  @override
  Widget build(BuildContext context) {
    // Calculate stats for first period
    final firstPeriodStats = _firstPeriod == null
        ? null
        : _calculatePeriodStats(_firstPeriod!);

    // Calculate stats for second period
    final secondPeriodStats = _secondPeriod == null
        ? null
        : _calculatePeriodStats(_secondPeriod!);

    final hasComparison = _firstPeriod != null && _secondPeriod != null;

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
            const SizedBox(height: 8),
            Text(
              'Compare Period 1 (baseline) vs Period 2',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // First Period Selector (baseline)
            _buildPeriodSelector(
              context,
              title: 'Period 1 (baseline)',
              dateRange: _firstPeriod,
              icon: Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => _selectPeriod(true),
            ),
            const SizedBox(height: 12),
            // Second Period Selector
            _buildPeriodSelector(
              context,
              title: 'Period 2',
              dateRange: _secondPeriod,
              icon: Icons.calendar_month,
              color: Theme.of(context).colorScheme.secondary,
              onTap: () => _selectPeriod(false),
            ),
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
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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

  Future<void> _selectPeriod(bool isFirst) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: widget.data.events.isNotEmpty
          ? widget.data.events
                .map((e) => e.date)
                .reduce((a, b) => a.isBefore(b) ? a : b)
          : DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: isFirst ? _firstPeriod : _secondPeriod,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: isFirst
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFirst) {
          _firstPeriod = picked;
        } else {
          _secondPeriod = picked;
        }
      });
    }
  }

  _PeriodStats _calculatePeriodStats(DateTimeRange range) {
    final periodEvents = widget.data.events
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
          if (participant.participant.reference.isNotEmpty) {
            participantIds.add(participant.participant.reference);
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
        if (activity.category.reference.isNotEmpty) {
          propertyIds.add(activity.category.reference);
        }
      }
    }
    final uniqueProperties = propertyIds.length;

    // Count event types (solo, couple, group)
    int soloEvents = 0;
    int coupleEvents = 0;
    int groupEvents = 0;

    for (final event in periodEvents) {
      final allParticipants = <String>{};
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          if (participant.participant.reference.isNotEmpty) {
            allParticipants.add(participant.participant.reference);
          }
        }
      }

      final partnerCount = allParticipants.length;
      if (partnerCount == 0) {
        soloEvents++;
      } else if (partnerCount == 1) {
        coupleEvents++;
      } else {
        groupEvents++;
      }
    }

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
