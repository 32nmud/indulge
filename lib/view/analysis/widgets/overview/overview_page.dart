import 'package:flutter/material.dart';

import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/navigation_helper.dart';
import 'package:intl/intl.dart';
import '../../models/overview_data.dart';
import 'overview_stats_section.dart';
import 'monthly_activity_chart.dart';
import 'records_section.dart';
import 'calendar_heatmap.dart';
import '../common/page_title.dart';
import 'analysis_location_heatmap.dart';

class OverviewPage extends StatelessWidget {
  final OverviewData data;
  final bool showCurrentMonthStats;

  const OverviewPage({
    super.key,
    required this.data,
    this.showCurrentMonthStats = true,
  });

  @override
  Widget build(BuildContext context) {
    // Compute date range for the heatmap — cover all events plus today.
    final now = DateTime.now();
    final earliest = data.events.isNotEmpty
        ? data.events.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b)
        : now.subtract(const Duration(days: 364));
    final heatmapStart = DateTime(earliest.year, earliest.month, earliest.day);
    final heatmapEnd = DateTime(now.year, now.month, now.day);

    // Collect geolocated event locations (synchronous — no async needed).
    final geoLocations = <Location>[];
    for (final ev in data.events) {
      final loc = ev.location;
      if (loc != null) geoLocations.add(loc);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const PageTitle(
          title: 'Overview',
          icon: Icons.dashboard,
          subtitle: 'Key stats, streaks, and summary',
        ),
        OverviewStatsSection(
          data: data,
          showCurrentMonthStats: showCurrentMonthStats,
        ),
        MonthlyActivityChart(data: data),
        const SizedBox(height: 16),

        // ── Activity calendar heatmap ─────────────────────────────────────
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: CalendarHeatmap(
              dailyCounts: data.dailyCounts,
              startDate: heatmapStart,
              endDate: heatmapEnd,
              onDaySelected: (date) {
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                // Only navigate if the day actually has events.
                if (data.dailyCounts.containsKey(dateStr)) {
                  final dayStart = DateTime(date.year, date.month, date.day);
                  final dayEnd = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    23,
                    59,
                    59,
                  );
                  NavigationHelper.of(context)?.navigateToSearch(
                    dateRange: DateTimeRange(start: dayStart, end: dayEnd),
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        RecordsSection(data: data),
        const SizedBox(height: 16),

        // ── Event locations heatmap (moved to bottom) ─────────────────────
        if (geoLocations.isNotEmpty)
          AnalysisLocationHeatmap(locations: geoLocations),
        if (geoLocations.isNotEmpty) const SizedBox(height: 16),
      ],
    );
  }
}
