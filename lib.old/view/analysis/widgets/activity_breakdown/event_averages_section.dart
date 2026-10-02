import 'package:flutter/material.dart';
import '../../models/analysis_event_type.dart';
import '../../models/activity_breakdown_data.dart';

class EventAveragesSection extends StatefulWidget {
  final ActivityBreakdownData data;
  final AnalysisEventType? filterType;

  const EventAveragesSection({super.key, required this.data, this.filterType});

  @override
  State<EventAveragesSection> createState() => _EventAveragesSectionState();
}

/// Cached computed values so the heavy per-event loops only run when [data]
/// or [filterType] actually changes, not on every build call.
class _ComputedAverages {
  final String eventsPerWeek;
  final String eventsPerMonth;
  final String activitiesPerWeek;
  final String activitiesPerMonth;
  final String partnersPerEvent;
  final String activitiesPerEvent;
  final String actionablePerEvent;
  final String gearPerEvent;

  const _ComputedAverages({
    required this.eventsPerWeek,
    required this.eventsPerMonth,
    required this.activitiesPerWeek,
    required this.activitiesPerMonth,
    required this.partnersPerEvent,
    required this.activitiesPerEvent,
    required this.actionablePerEvent,
    required this.gearPerEvent,
  });

  /// Compute averages from the overall data (no filter).
  factory _ComputedAverages.fromOverall(ActivityBreakdownData data) {
    return _ComputedAverages(
      eventsPerWeek: data.averageEventsPerWeek.toStringAsFixed(1),
      eventsPerMonth: data.averageEventsPerMonth.toStringAsFixed(1),
      activitiesPerWeek: data.averageActivitiesPerWeek.toStringAsFixed(1),
      activitiesPerMonth: data.averageActivitiesPerMonth.toStringAsFixed(1),
      partnersPerEvent: data.averagePartnersPerEvent.toStringAsFixed(1),
      activitiesPerEvent: data.averageActivitiesPerEvent.toStringAsFixed(1),
      actionablePerEvent: data.averageActionableActivitiesPerEvent
          .toStringAsFixed(1),
      gearPerEvent: data.averageGearPerEvent.toStringAsFixed(1),
    );
  }

  /// Compute averages for a specific event type filter.
  factory _ComputedAverages.fromFiltered(
    ActivityBreakdownData data,
    AnalysisEventType filterType,
  ) {
    final events = data.eventsByType[filterType] ?? [];
    final count = events.length;

    // Compute the actual date span covered by the data window so that
    // per-week and per-month rates are proportional to the real timeframe
    // rather than being back-calculated from overall averages.
    final double daySpan;
    if (data.startDate != null && data.endDate != null) {
      daySpan = data.endDate!.difference(data.startDate!).inDays.toDouble();
    } else if (events.isNotEmpty) {
      final earliest = events
          .map((e) => e.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final latest = events
          .map((e) => e.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      daySpan = latest.difference(earliest).inDays.toDouble();
    } else {
      daySpan = 365.0;
    }
    final weeks = daySpan > 0 ? daySpan / 7.0 : 1.0;
    final months = daySpan > 0 ? daySpan / 30.4375 : 1.0;

    int totalActivities = 0;
    int totalActionable = 0;
    int totalGear = 0;
    int totalPartners = 0;

    for (final event in events) {
      totalActivities += event.activities.length;

      for (final act in event.activities) {
        for (final p in act.participants) {
          for (final ac in p.activityCounts) {
            final compositeKey =
                '${ac.categoryReference.reference}:${ac.activityName}';
            final sexualActivity = data.sexualActivities[compositeKey];
            final isActionable = sexualActivity?.isActionable ?? true;
            if (isActionable) {
              totalActionable += ac.count;
            } else {
              totalGear += ac.count;
            }
          }
        }
      }

      if (filterType == AnalysisEventType.solo) {
        // Solo implies 0 partners
      } else if (filterType == AnalysisEventType.couple) {
        totalPartners += 1;
      } else {
        final uniqueParticipants = <String>{};
        for (final act in event.activities) {
          for (final p in act.participants) {
            uniqueParticipants.add(p.participant.reference);
          }
        }
        if (uniqueParticipants.isNotEmpty) {
          totalPartners += uniqueParticipants.length - 1;
        }
      }
    }

    return _ComputedAverages(
      eventsPerWeek: (count / weeks).toStringAsFixed(1),
      eventsPerMonth: (count / months).toStringAsFixed(1),
      activitiesPerWeek: (totalActivities / weeks).toStringAsFixed(1),
      activitiesPerMonth: (totalActivities / months).toStringAsFixed(1),
      partnersPerEvent: (count > 0 ? totalPartners / count : 0).toStringAsFixed(
        1,
      ),
      activitiesPerEvent: (count > 0 ? totalActivities / count : 0)
          .toStringAsFixed(1),
      actionablePerEvent: (count > 0 ? totalActionable / count : 0)
          .toStringAsFixed(1),
      gearPerEvent: (count > 0 ? totalGear / count : 0).toStringAsFixed(1),
    );
  }
}

class _EventAveragesSectionState extends State<EventAveragesSection> {
  late _ComputedAverages _averages;

  @override
  void initState() {
    super.initState();
    _averages = _compute(widget.data, widget.filterType);
  }

  @override
  void didUpdateWidget(covariant EventAveragesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.filterType != widget.filterType) {
      _averages = _compute(widget.data, widget.filterType);
    }
  }

  static _ComputedAverages _compute(
    ActivityBreakdownData data,
    AnalysisEventType? filterType,
  ) {
    if (filterType == null) {
      return _ComputedAverages.fromOverall(data);
    }
    return _ComputedAverages.fromFiltered(data, filterType);
  }

  @override
  Widget build(BuildContext context) {
    final eventsPerWeek = _averages.eventsPerWeek;
    final eventsPerMonth = _averages.eventsPerMonth;
    final activitiesPerWeek = _averages.activitiesPerWeek;
    final activitiesPerMonth = _averages.activitiesPerMonth;
    final partnersPerEvent = _averages.partnersPerEvent;
    final activitiesPerEvent = _averages.activitiesPerEvent;
    final actionablePerEvent = _averages.actionablePerEvent;
    final gearPerEvent = _averages.gearPerEvent;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Event Averages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Events per week / month
            Row(
              children: [
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Events/Week',
                    value: eventsPerWeek,
                    icon: Icons.calendar_view_week,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Events/Month',
                    value: eventsPerMonth,
                    icon: Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Categories per week / month
            Row(
              children: [
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Categories/Week',
                    value: activitiesPerWeek,
                    icon: Icons.event_note,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Categories/Month',
                    value: activitiesPerMonth,
                    icon: Icons.event_available,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Partners + categories per event
            Row(
              children: [
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Unique Partners/Event',
                    value: partnersPerEvent,
                    icon: Icons.people,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Categories/Event',
                    value: activitiesPerEvent,
                    icon: Icons.event_note,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Activities/Event (actionable only) + Items/Event (gear only)
            Row(
              children: [
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Activities/Event',
                    value: actionablePerEvent,
                    icon: Icons.sports_martial_arts,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Items/Event',
                    value: gearPerEvent,
                    icon: Icons.hardware,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
