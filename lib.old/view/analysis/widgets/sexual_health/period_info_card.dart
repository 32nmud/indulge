import 'package:flutter/material.dart';
import 'package:indulge/view/common/navigation_helper.dart';
import '../../models/sexual_health_analysis_data.dart';

/// Widget showing period information and next test recommendation.
class PeriodInfoCard extends StatelessWidget {
  final SexualHealthAnalysisData data;

  const PeriodInfoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Compute events/week for this period.
    final weeks = data.daysInPeriod > 0 ? data.daysInPeriod / 7.0 : 1.0;
    final eventsPerWeek = data.eventCountInPeriod / weeks;
    final eventsPerWeekStr = eventsPerWeek.toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Search-this-period button
                IconButton(
                  icon: const Icon(Icons.search, size: 18),
                  tooltip: 'Search events in this period',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    NavigationHelper.of(
                      context,
                    )?.navigateToSearch(dateRange: data.periodRange);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Date range + duration ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.isMostRecent ? 'Since Last Test' : 'Between Tests',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${_formatDate(data.periodStartDate)} – ${_formatDate(data.periodEndDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${data.daysInPeriod} days',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            // ── Frequency stats ────────────────────────────────────────
            if (data.eventCountInPeriod > 0) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.event,
                    label: 'Events',
                    value: '${data.eventCountInPeriod}',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.repeat,
                    label: 'Per week',
                    value: eventsPerWeekStr,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.people,
                    label: 'Partners',
                    value: '${data.uniquePartnersInPeriod}',
                  ),
                ],
              ),
            ],

            // ── Next recommended test date (most-recent only) ──────────
            if (data.isMostRecent && data.nextRecommendedTestDate != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Recommended Test',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatDate(data.nextRecommendedTestDate!),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: data.isOverdueForTesting
                                  ? Colors.red
                                  : null,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: data.isOverdueForTesting
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      data.isOverdueForTesting
                          ? '${-data.daysUntilNextTest} days overdue'
                          : '${data.daysUntilNextTest} days away',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: data.isOverdueForTesting
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ── Inline stat chip ──────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
