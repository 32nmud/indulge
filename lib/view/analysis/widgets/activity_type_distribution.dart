import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analysis_data.dart';

class ActivityTypeDistribution extends StatefulWidget {
  final AnalysisData data;

  const ActivityTypeDistribution({super.key, required this.data});

  @override
  State<ActivityTypeDistribution> createState() =>
      _ActivityTypeDistributionState();
}

class _ActivityTypeDistributionState extends State<ActivityTypeDistribution> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.activityCountsThisYear.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Type Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Total count of each activity type you\'ve done',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(flex: 3, child: _buildPieChart(context)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildLegend(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final sortedEntries = widget.data.activityCountsThisYear.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total from last 12 months
    final totalActivitiesThisYear = sortedEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );

    final colors = [
      Colors.blue,
      Colors.pink,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(sortedEntries.length, (i) {
          final isTouched = i == touchedIndex;
          final fontSize = isTouched ? 16.0 : 12.0;
          final radius = isTouched ? 65.0 : 55.0;
          final color = colors[i % colors.length];

          final entry = sortedEntries[i];
          final percentage = (entry.value / totalActivitiesThisYear * 100)
              .round();

          return PieChartSectionData(
            color: color,
            value: entry.value.toDouble(),
            title: '$percentage%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final sortedEntries = widget.data.activityCountsThisYear.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total from last 12 months
    final totalActivitiesThisYear = sortedEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );

    final colors = [
      Colors.blue,
      Colors.pink,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    return ListView.builder(
      shrinkWrap: true,
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final activityType = widget.data.activityTypes[entry.key];
        final color = colors[index % colors.length];
        final percentage = (entry.value / totalActivitiesThisYear * 100)
            .round();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityType?.displayCharacter ?? '❓',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      activityType?.name ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.value} ($percentage%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
