import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analysis_data.dart';

class TimePatternsSection extends StatelessWidget {
  final AnalysisData data;

  const TimePatternsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.dayOfWeekCounts.isEmpty) {
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
              'Time Patterns',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Average events per day of week',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(height: 200, child: _buildBarChart(context)),
            const SizedBox(height: 16),
            _buildWeekendVsWeekdayComparison(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final maxAverage = data.averageEventsPerDayOfWeek.values.isEmpty
        ? 0.0
        : data.averageEventsPerDayOfWeek.values.reduce((a, b) => a > b ? a : b);

    // Smart scaling: add 20% padding above max value, then round to nice number
    final maxY = _calculateNiceMaxY(maxAverage);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY.toDouble() : 5,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dayName = _getDayName(group.x.toInt() + 1);
              final average = rod.toY;
              return BarTooltipItem(
                '$dayName\n${average.toStringAsFixed(1)} avg events',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
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
              getTitlesWidget: (value, meta) {
                final dayOfWeek = value.toInt() + 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _getDayAbbreviation(dayOfWeek),
                    style: TextStyle(
                      color: _isWeekend(dayOfWeek)
                          ? Colors.orange[700]
                          : Colors.grey[600],
                      fontWeight: _isWeekend(dayOfWeek)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateNiceInterval(maxY),
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                // Show decimal if values are small
                final displayValue = maxY < 5
                    ? value.toStringAsFixed(1)
                    : value.toInt().toString();
                return Text(
                  displayValue,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            left: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateNiceInterval(maxY),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[300], strokeWidth: 1);
          },
        ),
        barGroups: List.generate(7, (index) {
          final dayOfWeek = index + 1; // 1 = Monday, 7 = Sunday
          final average = data.averageEventsPerDayOfWeek[dayOfWeek] ?? 0.0;
          final isWeekend = _isWeekend(dayOfWeek);

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: average,
                color: isWeekend ? Colors.orange : Colors.blue,
                width: 20,
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

  Widget _buildWeekendVsWeekdayComparison(BuildContext context) {
    final weekdayCount =
        (data.dayOfWeekCounts[1] ?? 0) +
        (data.dayOfWeekCounts[2] ?? 0) +
        (data.dayOfWeekCounts[3] ?? 0) +
        (data.dayOfWeekCounts[4] ?? 0) +
        (data.dayOfWeekCounts[5] ?? 0);

    final weekendCount =
        (data.dayOfWeekCounts[6] ?? 0) + (data.dayOfWeekCounts[7] ?? 0);

    final total = weekdayCount + weekendCount;
    if (total == 0) return const SizedBox.shrink();

    final weekdayPercentage = (weekdayCount / total * 100).round();
    final weekendPercentage = (weekendCount / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildComparisonItem(
              context,
              icon: Icons.business_center,
              label: 'Weekdays',
              count: weekdayCount,
              percentage: weekdayPercentage,
              color: Colors.blue,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _buildComparisonItem(
              context,
              icon: Icons.beach_access,
              label: 'Weekends',
              count: weekendCount,
              percentage: weekendPercentage,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required int percentage,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$percentage%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getDayAbbreviation(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  bool _isWeekend(int dayOfWeek) {
    return dayOfWeek == 6 || dayOfWeek == 7; // Saturday or Sunday
  }

  /// Calculate a nice maximum Y value with padding
  double _calculateNiceMaxY(double maxValue) {
    if (maxValue == 0) return 5.0;

    // Add 20% padding
    final paddedMax = maxValue * 1.2;

    // Round to nice numbers based on magnitude
    if (paddedMax <= 1) {
      // For very small values, round to nearest 0.5
      return (paddedMax * 2).ceil() / 2;
    } else if (paddedMax <= 5) {
      // For small values, round to nearest 1
      return paddedMax.ceil().toDouble();
    } else if (paddedMax <= 10) {
      // Round to nearest 2
      return ((paddedMax / 2).ceil() * 2).toDouble();
    } else if (paddedMax <= 20) {
      // Round to nearest 5
      return ((paddedMax / 5).ceil() * 5).toDouble();
    } else {
      // For larger values, round to nearest 10
      return ((paddedMax / 10).ceil() * 10).toDouble();
    }
  }

  /// Calculate a nice interval for grid lines and labels
  double _calculateNiceInterval(double maxY) {
    if (maxY == 0) return 1.0;

    // Aim for about 5 intervals
    final rawInterval = maxY / 5;

    if (rawInterval <= 0.5) {
      return 0.5;
    } else if (rawInterval <= 1) {
      return 1.0;
    } else if (rawInterval <= 2) {
      return 2.0;
    } else if (rawInterval <= 5) {
      return 5.0;
    } else {
      // Round to nearest 5 or 10
      return ((rawInterval / 5).ceil() * 5).toDouble();
    }
  }
}
