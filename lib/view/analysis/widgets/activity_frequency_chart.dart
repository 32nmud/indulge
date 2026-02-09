import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/analysis_data.dart';

class ActivityFrequencyChart extends StatelessWidget {
  final AnalysisData data;

  const ActivityFrequencyChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.dailyCounts.isEmpty) {
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
              'Activity Frequency',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Events over time',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(height: 200, child: _buildChart(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final sortedDates = data.dailyCounts.keys.toList()..sort();

    if (sortedDates.isEmpty) {
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

    // Create data points
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      final count = data.dailyCounts[sortedDates[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxYRounded = (maxY / 5).ceil() * 5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxYRounded > 0 ? maxYRounded / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1,
            );
          },
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
              reservedSize: 30,
              interval: _calculateInterval(sortedDates.length),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedDates.length) {
                  return const Text('');
                }

                final date = DateTime.parse(sortedDates[index]);
                final format = sortedDates.length > 30
                    ? DateFormat('MMM')
                    : DateFormat('MMM d');

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    format.format(date),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxYRounded > 0 ? maxYRounded / 5 : 1,
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
        minX: 0,
        maxX: (sortedDates.length - 1).toDouble(),
        minY: 0,
        maxY: maxYRounded > 0 ? maxYRounded.toDouble() : 5,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: sortedDates.length <= 31,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                if (index < 0 || index >= sortedDates.length) {
                  return null;
                }
                final date = DateTime.parse(sortedDates[index]);
                final count = barSpot.y.toInt();

                return LineTooltipItem(
                  '${DateFormat('MMM d, yyyy').format(date)}\n$count event${count != 1 ? 's' : ''}',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateInterval(int dataPointCount) {
    if (dataPointCount <= 7) return 1;
    if (dataPointCount <= 14) return 2;
    if (dataPointCount <= 31) return 5;
    if (dataPointCount <= 90) return 15;
    return 30;
  }
}
