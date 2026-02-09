import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/analysis_data.dart';

class MonthlyActivityChart extends StatelessWidget {
  final AnalysisData data;

  const MonthlyActivityChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.monthlyCounts.isEmpty) {
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
              'Monthly Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              data.timeWindowLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total activities per month',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(height: 250, child: _buildChart(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    // For "All Time" view, show last 12 months to keep chart readable
    // For other views, show all months in the selected time window
    final now = DateTime.now();
    final twelveMonthsAgo = DateTime(now.year, now.month - 11, 1);

    // If startDate is null (All Time), limit to last 12 months
    // Otherwise show all data from the selected window
    final shouldLimitTo12Months = data.startDate == null;

    final filteredMonths =
        data.monthlyCounts.entries
            .where((entry) {
              if (!shouldLimitTo12Months) {
                return true; // Show all months for specific time windows
              }
              final monthDate = DateTime.parse('${entry.key}-01');
              return monthDate.isAfter(
                twelveMonthsAgo.subtract(const Duration(days: 1)),
              );
            })
            .map((e) => e.key)
            .toList()
          ..sort();

    final sortedMonths = filteredMonths;

    if (sortedMonths.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      );
    }

    // Calculate max value for better scaling from filtered data
    final maxCount = sortedMonths.isEmpty
        ? 0
        : sortedMonths
              .map((key) => data.monthlyCounts[key] ?? 0)
              .reduce((a, b) => a > b ? a : b);
    final maxY = (maxCount / 5).ceil() * 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY.toDouble() : 5,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (group.x.toInt() >= 0 &&
                  group.x.toInt() < sortedMonths.length) {
                final monthKey = sortedMonths[group.x.toInt()];
                final date = DateTime.parse('$monthKey-01');
                final count = rod.toY.toInt();
                return BarTooltipItem(
                  '${DateFormat('MMMM yyyy').format(date)}\n$count activit${count != 1 ? 'ies' : 'y'}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }
              return null;
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedMonths.length) {
                  return const Text('');
                }

                final monthKey = sortedMonths[index];
                final date = DateTime.parse('$monthKey-01');

                // Show month abbreviation and year on separate lines
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${DateFormat('MMM').format(date)}\n${DateFormat('yy').format(date)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY > 0 ? maxY / 5 : 1,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
            left: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1,
            );
          },
        ),
        barGroups: List.generate(sortedMonths.length, (index) {
          final monthKey = sortedMonths[index];
          final count = data.monthlyCounts[monthKey] ?? 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: Colors.blue,
                width: sortedMonths.length > 12 ? 12 : 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
