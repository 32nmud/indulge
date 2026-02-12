import 'package:flutter/material.dart';
import '../../models/analysis_data.dart';
import 'overview_stats_section.dart';
import 'monthly_activity_chart.dart';
import 'calendar_heatmap.dart';
import 'records_section.dart';
import '../common/page_title.dart';
import 'package:indulge/view/common/navigation_helper.dart';

class OverviewPage extends StatelessWidget {
  final AnalysisData data;
  final bool showCurrentMonthStats;

  const OverviewPage({
    super.key,
    required this.data,
    this.showCurrentMonthStats = true,
  });

  @override
  Widget build(BuildContext context) {
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
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CalendarHeatmap(
              dailyCounts: data.dailyCounts,
              startDate:
                  data.startDate ??
                  DateTime.now().subtract(const Duration(days: 365)),
              endDate: data.endDate ?? DateTime.now(),
              onDaySelected: (date) {
                NavigationHelper.of(context)?.navigateToSearch(
                  dateRange: DateTimeRange(start: date, end: date),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        RecordsSection(data: data),
        const SizedBox(height: 16),
      ],
    );
  }
}
