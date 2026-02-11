import 'package:flutter/material.dart';
import 'package:indulge/view/common/navigation_helper.dart';
import 'package:indulge/view/common/event_card/event_card.dart';
import 'package:intl/intl.dart';
import '../models/analysis_data.dart';
import 'marquee_text.dart';

class OverviewStatsSection extends StatelessWidget {
  final AnalysisData data;
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

        // Row 5: Solo, Couple, Group events (last 12 months)
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Types',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tap to search',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEventTypeItem(
                          context,
                          icon: Icons.person,
                          label: 'Solo',
                          value: data.soloEventsThisYear,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: _buildEventTypeItem(
                          context,
                          icon: Icons.people,
                          label: 'Couple',
                          value: data.coupleEventsThisYear,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Expanded(
                        child: _buildEventTypeItem(
                          context,
                          icon: Icons.groups,
                          label: 'Group',
                          value: data.groupEventsThisYear,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Busiest Day and Event (Last 12 Months)
        if (data.busiestDay != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(elevation: 2, child: _buildBusiestDayInfo(context)),
          ),
        if (data.busiestDay != null) const SizedBox(height: 12),

        if (data.busiestEvent != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(elevation: 2, child: _buildBusiestEventInfo(context)),
          ),
      ],
    );
  }

  Widget _buildEventTypeItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusiestDayInfo(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(data.busiestDay!);
    final dayEvents = data.events
        .where((e) => DateUtils.isSameDay(e.date, data.busiestDay!))
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Icon(
          Icons.event_busy,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'Busiest Day',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$dateStr • ${data.busiestDayEventCount} events',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: dayEvents
            .map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: EventCard(event: event),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBusiestEventInfo(BuildContext context) {
    final event = data.busiestEvent!;
    final dateStr = DateFormat('MMM d, yyyy').format(event.date);
    final activityCount = event.activities
        .expand((a) => a.participants)
        .expand((p) => p.activityCounts)
        .map((ac) => ac.activityReference.reference)
        .toSet()
        .length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Icon(
          Icons.celebration,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          'Busiest Event',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$dateStr • $activityCount activities',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [EventCard(event: event)],
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
