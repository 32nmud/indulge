import 'package:flutter/material.dart';
import 'package:indulge/view/common/navigation_helper.dart';

import '../../models/overview_data.dart';
import '../../models/analysis_event_type.dart';
import '../../utils/analysis_colors.dart';
import '../common/marquee_text.dart';

class OverviewStatsSection extends StatelessWidget {
  final OverviewData data;
  final bool showCurrentMonthStats;

  const OverviewStatsSection({
    super.key,
    required this.data,
    this.showCurrentMonthStats = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Overview',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // Row 1: Total Events & Unique Partners
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.event,
                  label: 'Total Events',
                  value: data.totalEvents.toString(),
                  color: Colors.blue,
                  subtitle: 'Tap to search',
                  onTap: () {
                    DateTimeRange? range;
                    if (data.startDate != null) {
                      range = DateTimeRange(
                        start: data.startDate!,
                        end: data.endDate ?? DateTime.now(),
                      );
                    }
                    NavigationHelper.of(
                      context,
                    )?.navigateToSearch(dateRange: range);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  label: 'Unique Partners',
                  value: data.uniquePartners.toString(),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),

        // Row 2: Events/Partners this month & year
        if (data.startDate != null && data.endDate == null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.calendar_today,
                    label: 'Events This Month',
                    value: data.eventsThisMonth.toString(),
                    color: Colors.indigo,
                    subtitle: 'Tap to search',
                    onTap: () {
                      final now = DateTime.now();
                      final start = DateTime(now.year, now.month, 1);
                      final end = DateTime(now.year, now.month + 1, 0);
                      NavigationHelper.of(context)?.navigateToSearch(
                        dateRange: DateTimeRange(start: start, end: end),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.groups,
                    label: 'Partners This Month',
                    value: data.uniquePartnersThisMonth.toString(),
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Row 3: Current Streak & Longest Streak
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Current Streak',
                  value: data.currentStreak.toString(),
                  color: Theme.of(context).colorScheme.tertiary,
                  subtitle: data.currentStreak != 1 ? 'days' : 'day',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events,
                  label: 'Longest Streak',
                  value: data.longestStreak.toString(),
                  color: Theme.of(context).colorScheme.secondary,
                  subtitle: data.longestStreak != 1 ? 'days' : 'day',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 4: Partner Ratio
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _PartnerRatioCard(
            knownPartners: data.knownPartners,
            anonymousInstances: data.anonymousPartnerInstances,
          ),
        ),
        const SizedBox(height: 12),

        // Row 5: Event Types Breakdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Event Types',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: [
                          if ((data.eventCountsByType[AnalysisEventType.solo] ??
                                  0) >
                              0)
                            Expanded(
                              flex: data
                                  .eventCountsByType[AnalysisEventType.solo]!,
                              child: Container(color: AnalysisColors.solo),
                            ),
                          if ((data.eventCountsByType[AnalysisEventType
                                      .couple] ??
                                  0) >
                              0)
                            Expanded(
                              flex: data
                                  .eventCountsByType[AnalysisEventType.couple]!,
                              child: Container(color: AnalysisColors.couple),
                            ),
                          if ((data.eventCountsByType[AnalysisEventType
                                      .group] ??
                                  0) >
                              0)
                            Expanded(
                              flex: data
                                  .eventCountsByType[AnalysisEventType.group]!,
                              child: Container(color: AnalysisColors.group),
                            ),
                          if ((data.eventCountsByType[AnalysisEventType.solo] ??
                                      0) +
                                  (data.eventCountsByType[AnalysisEventType
                                          .couple] ??
                                      0) +
                                  (data.eventCountsByType[AnalysisEventType
                                          .group] ??
                                      0) ==
                              0)
                            Expanded(
                              child: Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Legend / Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildEventTypeLegendItem(
                          context,
                          label: 'Solo',
                          count:
                              data.eventCountsByType[AnalysisEventType.solo] ??
                              0,
                          color: AnalysisColors.solo,
                        ),
                      ),
                      Expanded(
                        child: _buildEventTypeLegendItem(
                          context,
                          label: 'Couple',
                          count:
                              data.eventCountsByType[AnalysisEventType
                                  .couple] ??
                              0,
                          color: AnalysisColors.couple,
                        ),
                      ),
                      Expanded(
                        child: _buildEventTypeLegendItem(
                          context,
                          label: 'Group',
                          count:
                              data.eventCountsByType[AnalysisEventType.group] ??
                              0,
                          color: AnalysisColors.group,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventTypeLegendItem(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        DateTimeRange? range;
        if (data.startDate != null) {
          range = DateTimeRange(
            start: data.startDate!,
            end: data.endDate ?? DateTime.now(),
          );
        }

        NavigationHelper.of(
          context,
        )?.navigateToSearch(eventType: label, dateRange: range);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MarqueeText(
                      text: label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerRatioCard extends StatelessWidget {
  final int knownPartners;
  final int anonymousInstances;

  const _PartnerRatioCard({
    required this.knownPartners,
    required this.anonymousInstances,
  });

  @override
  Widget build(BuildContext context) {
    final total = knownPartners + anonymousInstances;
    final knownPercentage = total > 0
        ? (knownPartners / total * 100).round()
        : 0;
    final anonPercentage = total > 0
        ? (anonymousInstances / total * 100).round()
        : 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Partner Ratio',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$knownPartners',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Known ($knownPercentage%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$anonymousInstances',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Anon ($anonPercentage%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
