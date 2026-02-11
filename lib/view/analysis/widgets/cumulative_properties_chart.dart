import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/dialogs/category_filter_dialog.dart';
import '../models/analysis_data.dart';

class CumulativePropertiesChart extends StatefulWidget {
  final AnalysisData data;

  const CumulativePropertiesChart({super.key, required this.data});

  @override
  State<CumulativePropertiesChart> createState() =>
      _CumulativePropertiesChartState();
}

class _CumulativePropertiesChartState extends State<CumulativePropertiesChart>
    with AutomaticKeepAliveClientMixin {
  String? _selectedActivity;
  Set<String> _selectedProperties = {};
  static const int _maxLines = 5;
  bool _isCumulative = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  void _initializeSelection() {
    // Do not auto-select any activity
  }

  void _updateTopProperties() {
    _selectedProperties = {};
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.data.events.isEmpty || widget.data.activityCounts.isEmpty) {
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
                  ? 'Cumulative Activities Over Time'
                  : 'Activity Trends Over Time',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _isCumulative
                  ? 'Track activity usage for each category over time'
                  : 'View activity counts for each time period',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildModeToggle(),
            const SizedBox(height: 16),
            _buildActivitySelector(),
            if (_selectedActivity != null) ...[
              const SizedBox(height: 12),
              _buildPropertySelector(),
            ],
            if (_selectedProperties.isNotEmpty) ...[
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
    final activityName = _selectedActivity != null
        ? widget.data.activityCategories[_selectedActivity]?.name ?? 'Unknown'
        : 'None';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity Category',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                activityName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _showActivityFilter,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Change'),
        ),
      ],
    );
  }

  Future<void> _showActivityFilter() async {
    final categories = widget.data.activityCounts.keys
        .map((id) => widget.data.activityCategories[id])
        .whereType<SexualActivityCategory>()
        .toList();

    // Sort by count
    categories.sort((a, b) {
      final countA = widget.data.activityCounts[a.id] ?? 0;
      final countB = widget.data.activityCounts[b.id] ?? 0;
      return countB.compareTo(countA);
    });

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => CategoryFilterDialog(
        categories: categories,
        selectedIds: _selectedActivity != null ? {_selectedActivity!} : {},
        singleSelect: true,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedActivity = result.isNotEmpty ? result.first : null;
        _updateTopProperties();
      });
    }
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
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _selectedProperties.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final propertyId = entry.value;
        final activity = widget.data.sexualActivities[propertyId];
        final displayName = activity?.name ?? 'Unknown';

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

  Widget _buildPropertySelector() {
    // Get all properties used with selected activity
    final propertyCountsForActivity = <String, int>{};

    for (final event in widget.data.events) {
      for (final activity in event.activities) {
        if (activity.category.reference == _selectedActivity) {
          for (final participant in activity.participants) {
            for (final activityCount in participant.activityCounts) {
              final activityId = activityCount.activityReference.reference;
              if (activityId.isNotEmpty) {
                propertyCountsForActivity[activityId] =
                    (propertyCountsForActivity[activityId] ?? 0) +
                    activityCount.count;
              }
            }
          }
        }
      }
    }

    if (propertyCountsForActivity.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No properties found for this activity',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Specific Activities',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${_selectedProperties.length} selected (max $_maxLines)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _showPropertyFilter(
            propertyCountsForActivity,
            widget.data.sexualActivities,
          ),
          icon: const Icon(Icons.filter_list, size: 16),
          label: const Text('Filter'),
        ),
      ],
    );
  }

  Future<void> _showPropertyFilter(
    Map<String, int> counts,
    Map<String, SexualActivity> activities,
  ) async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _PropertyFilterDialog(
        counts: counts,
        activities: activities,
        selectedIds: _selectedProperties,
        maxSelection: _maxLines,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedProperties = result;
      });
    }
  }

  Widget _buildChart(BuildContext context) {
    if (_selectedActivity == null || _selectedProperties.isEmpty) {
      return Center(
        child: Text(
          _selectedActivity == null
              ? 'Select a category to begin'
              : 'Select up to $_maxLines properties to display',
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

    // Color palette for different properties
    final colors = [
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
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
          lineBarsData: _selectedProperties.toList().asMap().entries.map((
            entry,
          ) {
            final index = entry.key;
            final propertyId = entry.value;
            final propertyData = chartData[propertyId] ?? {};

            final spots = allDates.asMap().entries.map((dateEntry) {
              final dateIndex = dateEntry.key;
              final date = dateEntry.value;
              final count = propertyData[date] ?? 0;
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
                  final propertyId = _selectedProperties
                      .toList()[spot.barIndex];
                  final activity = widget.data.sexualActivities[propertyId];
                  final displayName = activity?.name ?? 'Unknown';
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
    if (_selectedActivity == null) return {};

    // First, get the actual monthly counts
    final monthlyData = _calculateActualData();

    // Convert to cumulative
    final result = <String, Map<DateTime, int>>{};

    for (final propertyId in _selectedProperties) {
      result[propertyId] = {};
      final propertyMonthly = monthlyData[propertyId] ?? {};

      if (propertyMonthly.isEmpty) continue;

      final allDates = propertyMonthly.keys.toList()..sort();
      var cumulativeTotal = 0;

      for (final date in allDates) {
        cumulativeTotal += propertyMonthly[date] ?? 0;
        result[propertyId]![date] = cumulativeTotal;
      }
    }

    // Find the global date range across all properties
    final allDatesAcrossProperties =
        result.values.expand((data) => data.keys).toSet().toList()..sort();

    if (allDatesAcrossProperties.isEmpty) return result;

    final globalFirstDate = allDatesAcrossProperties.first;
    final globalLastDate = allDatesAcrossProperties.last;

    // Fill each property's cumulative data across the full date range
    for (final propertyId in _selectedProperties) {
      final propertyData = result[propertyId];
      if (propertyData == null || propertyData.isEmpty) continue;

      final propertyDates = propertyData.keys.toList()..sort();
      final propertyFirstDate = propertyDates.first;

      var currentDate = DateTime(
        globalFirstDate.year,
        globalFirstDate.month,
        1,
      );
      final filledData = <DateTime, int>{};
      var lastCumulativeValue = 0;

      while (currentDate.isBefore(globalLastDate) ||
          currentDate.isAtSameMomentAs(globalLastDate)) {
        if (currentDate.isBefore(propertyFirstDate)) {
          // Before this property's data starts, value is 0
          filledData[currentDate] = 0;
        } else if (propertyData.containsKey(currentDate)) {
          // Property has data for this date
          lastCumulativeValue = propertyData[currentDate]!;
          filledData[currentDate] = lastCumulativeValue;
        } else {
          // After property's data starts but missing this month: carry forward
          filledData[currentDate] = lastCumulativeValue;
        }
        currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      }

      result[propertyId] = filledData;
    }

    return result;
  }

  Map<String, Map<DateTime, int>> _calculateActualData() {
    if (_selectedActivity == null) return {};

    final result = <String, Map<DateTime, int>>{};

    // Initialize maps for each selected property
    for (final propertyId in _selectedProperties) {
      result[propertyId] = {};
    }

    // Count properties per month
    for (final event in widget.data.events) {
      final monthDate = DateTime(event.date.year, event.date.month, 1);

      for (final activity in event.activities) {
        if (activity.category.reference == _selectedActivity) {
          for (final participant in activity.participants) {
            for (final activityCount in participant.activityCounts) {
              final activityId = activityCount.activityReference.reference;
              if (_selectedProperties.contains(activityId)) {
                result[activityId]![monthDate] =
                    (result[activityId]![monthDate] ?? 0) + activityCount.count;
              }
            }
          }
        }
      }
    }

    // Fill in gaps with zeros
    for (final propertyId in _selectedProperties) {
      final propertyData = result[propertyId]!;
      if (propertyData.isEmpty) continue;

      final allDates = propertyData.keys.toList()..sort();
      final firstDate = allDates.first;
      final lastDate = allDates.last;

      var currentDate = DateTime(firstDate.year, firstDate.month, 1);

      final filledData = <DateTime, int>{};
      while (currentDate.isBefore(lastDate) ||
          currentDate.isAtSameMomentAs(lastDate)) {
        filledData[currentDate] = propertyData[currentDate] ?? 0;
        currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      }

      result[propertyId] = filledData;
    }

    return result;
  }
}

class _PropertyFilterDialog extends StatefulWidget {
  final Map<String, int> counts;
  final Map<String, SexualActivity> activities;
  final Set<String> selectedIds;
  final int maxSelection;

  const _PropertyFilterDialog({
    required this.counts,
    required this.activities,
    required this.selectedIds,
    required this.maxSelection,
  });

  @override
  State<_PropertyFilterDialog> createState() => _PropertyFilterDialogState();
}

class _PropertyFilterDialogState extends State<_PropertyFilterDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final sortedProperties = widget.counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AlertDialog(
      title: Text('Select Activities (max ${widget.maxSelection})'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: sortedProperties.map((entry) {
            final propertyId = entry.key;
            final count = entry.value;
            final activity = widget.activities[propertyId];
            final isSelected = _selectedIds.contains(propertyId);
            final displayName = activity?.name ?? 'Unknown';

            return CheckboxListTile(
              title: Text(displayName),
              subtitle: Text('$count times'),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (_selectedIds.length < widget.maxSelection) {
                      _selectedIds.add(propertyId);
                    }
                  } else {
                    _selectedIds.remove(propertyId);
                  }
                });
              },
              enabled: isSelected || _selectedIds.length < widget.maxSelection,
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedIds.clear();
            });
          },
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
