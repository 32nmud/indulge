import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/analysis_data.dart';

class CumulativeActivitiesChart extends StatefulWidget {
  final AnalysisData data;

  const CumulativeActivitiesChart({super.key, required this.data});

  @override
  State<CumulativeActivitiesChart> createState() =>
      _CumulativeActivitiesChartState();
}

class _CumulativeActivitiesChartState extends State<CumulativeActivitiesChart> {
  Set<String> _selectedActivities = {};
  static const int _maxLines = 5;
  bool _isCumulative = false;

  @override
  void initState() {
    super.initState();
    _initializeSelectedActivities();
  }

  void _initializeSelectedActivities() {
    // Get top 5 activities by count
    final sortedActivities = widget.data.activityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _selectedActivities = sortedActivities
        .take(_maxLines)
        .map((e) => e.key)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.events.isEmpty) {
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
              _isCumulative
                  ? 'Cumulative Categories Over Time'
                  : 'Category Trends Over Time',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _isCumulative
                  ? 'Track how each category accumulates over the period'
                  : 'View category counts for each time period',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildModeToggle(),
            const SizedBox(height: 16),
            _buildActivitySelector(),
            if (_selectedActivities.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLegend(),
            ],
            const SizedBox(height: 24),
            SizedBox(height: 300, child: _buildChart(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySelector() {
    final sortedActivities = widget.data.activityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sortedActivities.take(10).map((entry) {
        final activityId = entry.key;
        final activityCategory = widget.data.activityCategories[activityId];
        final displayName = activityCategory?.name ?? 'Unknown';
        final isSelected = _selectedActivities.contains(activityId);

        return FilterChip(
          label: Text(displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                if (_selectedActivities.length < _maxLines) {
                  _selectedActivities.add(activityId);
                }
              } else {
                _selectedActivities.remove(activityId);
              }
            });
          },
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      children: [
        Text(
          'View Mode:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              label: Text('Actual'),
              icon: Icon(Icons.show_chart, size: 16),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text('Cumulative'),
              icon: Icon(Icons.trending_up, size: 16),
            ),
          ],
          selected: {_isCumulative},
          onSelectionChanged: (Set<bool> newSelection) {
            setState(() {
              _isCumulative = newSelection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _selectedActivities.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final activityId = entry.value;
        final activityCategory = widget.data.activityCategories[activityId];
        final displayName = activityCategory?.name ?? 'Unknown';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              displayName,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildChart(BuildContext context) {
    if (_selectedActivities.isEmpty) {
      return Center(
        child: Text(
          'Select up to $_maxLines activities to display',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      );
    }

    final chartData = _isCumulative
        ? _calculateCumulativeData()
        : _calculateActualData();
    if (chartData.isEmpty) {
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

    final allDates =
        chartData.values.expand((data) => data.keys).toSet().toList()..sort();

    if (allDates.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final maxValue = chartData.values
        .expand((data) => data.values)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    // Calculate a clean maxY and interval for the y-axis
    final maxY = maxValue * 1.1;
    double interval;
    if (maxY <= 5) {
      interval = 1;
    } else if (maxY <= 10) {
      interval = 2;
    } else if (maxY <= 20) {
      interval = 5;
    } else if (maxY <= 50) {
      interval = 10;
    } else if (maxY <= 100) {
      interval = 20;
    } else {
      interval = (maxY / 5).ceilToDouble();
      // Round interval to nearest 5, 10, 50, 100, etc.
      final magnitude = (interval / 10).floor() * 10;
      if (magnitude > 0) {
        interval = ((interval / magnitude).ceil() * magnitude).toDouble();
      }
    }

    // Color palette for different activities
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
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
                reservedSize: 40,
                interval: allDates.length > 6
                    ? (allDates.length / 6).ceil().toDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= allDates.length) {
                    return const Text('');
                  }

                  final date = allDates[index];
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
                interval: interval,
                reservedSize: 40,
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
          maxX: (allDates.length - 1).toDouble(),
          minY: 0,
          maxY: ((maxY / interval).ceil() * interval).toDouble(),
          lineBarsData: _selectedActivities.toList().asMap().entries.map((
            entry,
          ) {
            final index = entry.key;
            final activityId = entry.value;
            final activityData = chartData[activityId] ?? {};

            final spots = allDates.asMap().entries.map((dateEntry) {
              final dateIndex = dateEntry.key;
              final date = dateEntry.value;
              final count = activityData[date] ?? 0;
              return FlSpot(dateIndex.toDouble(), count.toDouble());
            }).toList();

            return LineChartBarData(
              spots: spots,
              isCurved: !_isCumulative,
              color: colors[index % colors.length],
              barWidth: _isCumulative ? 3 : 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: !_isCumulative || allDates.length <= 12,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: _isCumulative ? 3 : 4,
                    color: colors[entry.key % colors.length],
                    strokeWidth: _isCumulative ? 0 : 1.5,
                    strokeColor: _isCumulative
                        ? Colors.transparent
                        : Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            );
          }).toList(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final activityId = _selectedActivities
                      .toList()[spot.barIndex];
                  final activityCategory =
                      widget.data.activityCategories[activityId];
                  final displayName = activityCategory?.name ?? 'Unknown';
                  final date = allDates[spot.x.toInt()];
                  final count = spot.y.toInt();

                  return LineTooltipItem(
                    '$displayName\n${DateFormat('MMM d, yyyy').format(date)}\n$count ${_isCumulative ? 'total' : 'in period'}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Map<DateTime, int>> _calculateCumulativeData() {
    // First, get the actual monthly counts
    final monthlyData = _calculateActualData();

    // Convert to cumulative
    final result = <String, Map<DateTime, int>>{};

    for (final activityId in _selectedActivities) {
      result[activityId] = {};
      final activityMonthly = monthlyData[activityId] ?? {};

      if (activityMonthly.isEmpty) continue;

      final allDates = activityMonthly.keys.toList()..sort();
      var cumulativeTotal = 0;

      for (final date in allDates) {
        cumulativeTotal += activityMonthly[date] ?? 0;
        result[activityId]![date] = cumulativeTotal;
      }
    }

    // Find the global date range across all activities
    final allDatesAcrossActivities =
        result.values.expand((data) => data.keys).toSet().toList()..sort();

    if (allDatesAcrossActivities.isEmpty) return result;

    final globalFirstDate = allDatesAcrossActivities.first;
    final globalLastDate = allDatesAcrossActivities.last;

    // Fill each activity's cumulative data across the full date range
    for (final activityId in _selectedActivities) {
      final activityData = result[activityId];
      if (activityData == null || activityData.isEmpty) continue;

      final activityDates = activityData.keys.toList()..sort();
      final activityFirstDate = activityDates.first;
      final activityLastDate = activityDates.last;

      var currentDate = DateTime(
        globalFirstDate.year,
        globalFirstDate.month,
        1,
      );
      final filledData = <DateTime, int>{};
      var lastCumulativeValue = 0;

      while (currentDate.isBefore(globalLastDate) ||
          currentDate.isAtSameMomentAs(globalLastDate)) {
        if (currentDate.isBefore(activityFirstDate)) {
          // Before this activity's data starts, value is 0
          filledData[currentDate] = 0;
        } else if (activityData.containsKey(currentDate)) {
          // Activity has data for this date
          lastCumulativeValue = activityData[currentDate]!;
          filledData[currentDate] = lastCumulativeValue;
        } else {
          // After activity's data starts but missing this month: carry forward
          filledData[currentDate] = lastCumulativeValue;
        }
        currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      }

      result[activityId] = filledData;
    }

    return result;
  }

  Map<String, Map<DateTime, int>> _calculateActualData() {
    final result = <String, Map<DateTime, int>>{};

    // Initialize maps for each selected activity
    for (final activityId in _selectedActivities) {
      result[activityId] = {};
    }

    // Count activities per month
    for (final event in widget.data.events) {
      final monthDate = DateTime(event.date.year, event.date.month, 1);

      for (final activity in event.activities) {
        final activityId = activity.category.reference;
        if (_selectedActivities.contains(activityId)) {
          result[activityId]![monthDate] =
              (result[activityId]![monthDate] ?? 0) + 1;
        }
      }
    }

    // Fill in gaps with zeros
    for (final activityId in _selectedActivities) {
      final activityData = result[activityId]!;
      if (activityData.isEmpty) continue;

      final allDates = activityData.keys.toList()..sort();
      final firstDate = allDates.first;
      final lastDate = allDates.last;

      var currentDate = DateTime(firstDate.year, firstDate.month, 1);

      final filledData = <DateTime, int>{};
      while (currentDate.isBefore(lastDate) ||
          currentDate.isAtSameMomentAs(lastDate)) {
        filledData[currentDate] = activityData[currentDate] ?? 0;
        currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      }

      result[activityId] = filledData;
    }

    return result;
  }
}
