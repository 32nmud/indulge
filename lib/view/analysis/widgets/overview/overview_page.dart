import 'package:flutter/material.dart';

import 'package:indulge/data/models.dart';
import '../../models/overview_data.dart';
import 'overview_stats_section.dart';
import 'monthly_activity_chart.dart';
import 'records_section.dart';
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

        // Event locations heatmap (per-event)
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<List<Location>>(
              // Build a list of Location objects, preserving duplicates per-event
              future: () async {
                // Build a list of embedded Location objects from events.
                final perEventLocations = <Location>[];
                for (final ev in data.events) {
                  final loc = ev.location;
                  if (loc == null) continue;
                  perEventLocations.add(loc);
                }
                return perEventLocations;
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final locations = snapshot.data ?? [];

                if (locations.isEmpty) {
                  return SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'No event locations to display',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                // Delegate rendering to the aggregated heatmap widget which now
                // receives one Location entry per event (duplicates preserved).
                return AnalysisLocationHeatmap(
                  locations: locations,
                  // Slightly higher gridSize gives better separation for mixed-state data
                  gridSize: 120,
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
