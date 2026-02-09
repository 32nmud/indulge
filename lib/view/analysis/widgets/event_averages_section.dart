import 'package:flutter/material.dart';
import '../models/analysis_data.dart';

class EventAveragesSection extends StatelessWidget {
  final AnalysisData data;

  const EventAveragesSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Averages',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        data.timeWindowLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
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
                    value: data.averageEventsPerWeek.toStringAsFixed(1),
                    icon: Icons.calendar_view_week,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Events/Month',
                    value: data.averageEventsPerMonth.toStringAsFixed(1),
                    icon: Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Activity Averages
            Row(
              children: [
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Activities/Week',
                    value: data.averageActivitiesPerWeek.toStringAsFixed(1),
                    icon: Icons.event_note,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Activities/Month',
                    value: data.averageActivitiesPerMonth.toStringAsFixed(1),
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
                    value: data.averagePartnersPerEvent.toStringAsFixed(1),
                    icon: Icons.people,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAverageItem(
                    context,
                    label: 'Activities/Event',
                    value: data.averageActivitiesPerEvent.toStringAsFixed(1),
                    icon: Icons.event_note,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAverageItem(
              context,
              label: 'Properties/Event',
              value: data.averagePropertiesPerEvent.toStringAsFixed(1),
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
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.blue[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
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
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }
}
