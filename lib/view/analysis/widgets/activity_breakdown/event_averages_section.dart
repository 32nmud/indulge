import 'package:flutter/material.dart';
import '../../models/analysis_event_type.dart';
import '../../models/activity_breakdown_data.dart';

class EventAveragesSection extends StatelessWidget {
  final ActivityBreakdownData data;
  final AnalysisEventType? filterType;

  const EventAveragesSection({super.key, required this.data, this.filterType});

  @override
  Widget build(BuildContext context) {
    // Calculate values based on filter
    String eventsPerWeek;
    String eventsPerMonth;
    String activitiesPerWeek;
    String activitiesPerMonth;
    String partnersPerEvent;
    String activitiesPerEvent;
    String sexualActivitiesPerEvent;

    if (filterType == null) {
      eventsPerWeek = data.averageEventsPerWeek.toStringAsFixed(1);
      eventsPerMonth = data.averageEventsPerMonth.toStringAsFixed(1);
      activitiesPerWeek = data.averageActivitiesPerWeek.toStringAsFixed(1);
      activitiesPerMonth = data.averageActivitiesPerMonth.toStringAsFixed(1);
      partnersPerEvent = data.averagePartnersPerEvent.toStringAsFixed(1);
      activitiesPerEvent = data.averageActivitiesPerEvent.toStringAsFixed(1);
      sexualActivitiesPerEvent = data.averageSexualActivitiesPerEvent
          .toStringAsFixed(1);
    } else {
      final events = data.eventsByType[filterType!] ?? [];
      final count = events.length;

      // Approximate duration from global data
      // Avoid division by zero
      final weeks = data.averageEventsPerWeek > 0
          ? data.eventsThisYear / data.averageEventsPerWeek
          : 1.0;
      final months = data.averageEventsPerMonth > 0
          ? data.eventsThisYear / data.averageEventsPerMonth
          : 1.0;

      // Totals
      int totalActivities = 0;
      int totalSexualActivities = 0;
      int totalPartners = 0;

      for (final event in events) {
        totalActivities += event.activities.length;
        for (final act in event.activities) {
          for (final p in act.participants) {
            for (final ac in p.activityCounts) {
              totalSexualActivities += ac.count;
            }
          }
        }

        // Partners calculation
        if (filterType == AnalysisEventType.solo) {
          // Solo implies 0 partners
        } else if (filterType == AnalysisEventType.couple) {
          totalPartners += 1;
        } else {
          // Group: estimate based on participants.
          // We don't have easy access to "Me" ID here, but we can count unique participants.
          // Assuming 1 is "Me", partners = count - 1.
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

      eventsPerWeek = (weeks > 0 ? count / weeks : 0).toStringAsFixed(1);
      eventsPerMonth = (months > 0 ? count / months : 0).toStringAsFixed(1);
      activitiesPerWeek = (weeks > 0 ? totalActivities / weeks : 0)
          .toStringAsFixed(1);
      activitiesPerMonth = (months > 0 ? totalActivities / months : 0)
          .toStringAsFixed(1);
      partnersPerEvent = (count > 0 ? totalPartners / count : 0)
          .toStringAsFixed(1);
      activitiesPerEvent = (count > 0 ? totalActivities / count : 0)
          .toStringAsFixed(1);
      sexualActivitiesPerEvent = (count > 0 ? totalSexualActivities / count : 0)
          .toStringAsFixed(1);
    }

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
            // Event Averages
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
            // Category Averages
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
            // Per-Event Averages
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
            _buildAverageItem(
              context,
              label: 'Activities/Event',
              value: sexualActivitiesPerEvent,
              icon: Icons.label,
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
