import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:indulge/services/preferences_service.dart';
import 'package:indulge/data/models.dart';
import '../../models/analysis_event_type.dart';
import '../../models/activity_breakdown_data.dart';

class ActivityTrendsChart extends StatefulWidget {
  final ActivityBreakdownData data;
  final AnalysisEventType? filterType;
  final bool showTypeFilter;

  const ActivityTrendsChart({
    super.key,
    required this.data,
    this.filterType,
    this.showTypeFilter = true,
  });

  @override
  State<ActivityTrendsChart> createState() => _ActivityTrendsChartState();
}

class _ActivityTrendsChartState extends State<ActivityTrendsChart>
    with AutomaticKeepAliveClientMixin {
  AnalysisEventType? _selectedType;
  final Set<String> _selectedPropertyIds = {};
  // The show-pattern preference is persisted and exposed via PreferencesService.
  // `true` -> Pattern view, `false` -> History view.
  bool _showPattern = false;
  List<String> _topProperties = [];
  List<String> _visibleProperties = [];
  final List<Color> _colors = [
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    _calculateTopProperties();
    // Load persisted preferences and subscribe for changes after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShowPatternPreference();
      _loadSelectedPropertiesPreference();
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant ActivityTrendsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _calculateTopProperties();
    }
  }

  /// Read the persisted preference via PreferencesService and listen for updates.
  void _loadShowPatternPreference() {
    try {
      final svc = Provider.of<PreferencesService>(context, listen: false);
      final val = svc.getActivityShowPattern();
      if (mounted) {
        setState(() {
          _showPattern = val;
        });
      } else {
        _showPattern = val;
      }

      // Keep in sync with future preference changes.
      svc.activityShowPatternNotifier.addListener(() {
        final newVal = svc.getActivityShowPattern();
        if (mounted) {
          setState(() {
            _showPattern = newVal;
          });
        } else {
          _showPattern = newVal;
        }
      });
    } catch (_) {
      // Best-effort: ignore failures and keep default.
    }
  }

  /// -------------------------
  /// Selected-properties persistence (via PreferencesService)
  /// -------------------------
  /// Loads the set of selected activity/property IDs from the PreferencesService
  /// and seeds the local `_selectedPropertyIds` and `_visibleProperties`.
  void _loadSelectedPropertiesPreference() {
    try {
      final svc = Provider.of<PreferencesService>(context, listen: false);
      final ids = svc.getActivitySelectedIds().toSet();

      if (mounted) {
        setState(() {
          _selectedPropertyIds
            ..clear()
            ..addAll(ids);

          // Ensure visible properties include selected ones
          final Set<String> visibleSet = {
            ..._topProperties,
            ..._selectedPropertyIds,
          };
          _visibleProperties = visibleSet.toList();
        });
      } else {
        _selectedPropertyIds
          ..clear()
          ..addAll(ids);
        _visibleProperties = {
          ..._topProperties,
          ..._selectedPropertyIds,
        }.toList();
      }

      // Listen for future preference changes and keep the UI in sync.
      svc.activitySelectedIdsNotifier.addListener(() {
        final newIds = svc.getActivitySelectedIds().toSet();
        if (mounted) {
          setState(() {
            _selectedPropertyIds
              ..clear()
              ..addAll(newIds);
            _visibleProperties = {
              ..._topProperties,
              ..._selectedPropertyIds,
            }.toList();
          });
        } else {
          _selectedPropertyIds
            ..clear()
            ..addAll(newIds);
          _visibleProperties = {
            ..._topProperties,
            ..._selectedPropertyIds,
          }.toList();
        }
      });
    } catch (_) {
      // Best-effort: ignore load failures.
    }
  }

  /// Persists the currently selected property IDs via PreferencesService.
  Future<void> _persistSelectedProperties() async {
    try {
      final svc = Provider.of<PreferencesService>(context, listen: false);
      await svc.setActivitySelectedIds(_selectedPropertyIds.toList());
    } catch (_) {
      // Best-effort: ignore save failures.
    }
  }

  /// Persist the preference via PreferencesService (best-effort).
  Future<void> _persistShowPattern(bool value) async {
    try {
      final svc = Provider.of<PreferencesService>(context, listen: false);
      await svc.setActivityShowPattern(value);
    } catch (_) {
      // Ignore persistence failures.
    }
  }

  void _calculateTopProperties() {
    // Use the pre-calculated totals from AnalysisData
    // We can filter this if we want to respect the current time window,
    // but using the global "Top 5" is usually what users want to see.
    // If we want strict time-window compliance, we should recalculate from events.

    // Let's recalculate from current events to respect the time window filter
    final counts = <String, int>{};
    for (final event in widget.data.events) {
      final seenInEvent = <String>{};
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          for (final count in participant.activityCounts) {
            // Use categoryReference + activityName as the activity identifier
            final catRef = count.categoryReference.reference;
            final actName = count.activityName;
            final id = '$catRef:$actName';
            if (seenInEvent.add(id)) {
              counts[id] = (counts[id] ?? 0) + 1;
            }
          }
        }
      }
    }

    // Sort by count descending
    final sortedIds = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    // Take top 5
    setState(() {
      _topProperties = sortedIds.take(5).toList();

      // Ensure currently selected items stay visible
      final Set<String> visibleSet = {
        ..._topProperties,
        ..._selectedPropertyIds,
      };
      _visibleProperties = visibleSet.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_topProperties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Trends',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _showPattern
                            ? 'Average events which contain the selected categories per day of week'
                            : 'Total events which contain the selected categories per month',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('History', style: TextStyle(fontSize: 10)),
                      icon: Icon(Icons.calendar_month, size: 14),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Pattern', style: TextStyle(fontSize: 10)),
                      icon: Icon(Icons.view_week, size: 14),
                    ),
                  ],
                  selected: {_showPattern},
                  onSelectionChanged: (Set<bool> newSelection) {
                    final newVal = newSelection.first;
                    setState(() {
                      _showPattern = newVal;
                    });
                    // Persist preference via PreferencesService (best-effort)
                    _persistShowPattern(newVal);
                  },
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.showTypeFilter) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildEventTypeFilterChip('Total', null),
                    const SizedBox(width: 8),
                    _buildEventTypeFilterChip('Solo', AnalysisEventType.solo),
                    const SizedBox(width: 8),
                    _buildEventTypeFilterChip(
                      'Couple',
                      AnalysisEventType.couple,
                    ),
                    const SizedBox(width: 8),
                    _buildEventTypeFilterChip('Group', AnalysisEventType.group),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedPropertyIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        avatar: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear'),
                        onPressed: () async {
                          setState(() {
                            _selectedPropertyIds.clear();
                            // Reset visible properties to just top properties
                            _visibleProperties = _topProperties.toList();
                          });
                          // Persist clearing of selection (best-effort)
                          await _persistSelectedProperties();
                        },
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.only(right: 8),
                      ),
                    ),
                  ..._visibleProperties.asMap().entries.map((entry) {
                    final index = entry.key;
                    final id = entry.value;
                    final property = widget.data.sexualActivities[id];
                    final name = property?.name ?? 'Unknown';
                    final char = property?.displayCharacter;
                    final label = char != null && char.isNotEmpty && char != '❔'
                        ? '$char $name'
                        : name;
                    final color = _colors[index % _colors.length];
                    final isSelected = _selectedPropertyIds.contains(id);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) async {
                          setState(() {
                            if (selected) {
                              _selectedPropertyIds.add(id);
                            } else {
                              _selectedPropertyIds.remove(id);
                            }
                          });
                          // Persist updated selection (best-effort)
                          await _persistSelectedProperties();
                        },
                        showCheckmark: false,
                        selectedColor: color.withOpacity(0.2),
                        side: isSelected ? BorderSide(color: color) : null,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? color : null,
                        ),
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      onPressed: _showActivityPicker,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.only(right: 8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(height: 250, child: _buildChart(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeFilterChip(String label, AnalysisEventType? type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
          });
        }
      },
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    if (_selectedPropertyIds.isEmpty) {
      return const Center(child: Text('Select at least one activity'));
    }

    return _showPattern
        ? _buildPatternChart(context)
        : _buildHistoryChart(context);
  }

  Widget _buildPatternChart(BuildContext context) {
    // Count days of week for each selected property
    final dayCounts = <int, Map<String, int>>{};
    for (int i = 1; i <= 7; i++) {
      dayCounts[i] = {};
      for (final id in _selectedPropertyIds) {
        dayCounts[i]![id] = 0;
      }
    }

    final typeToUse = widget.showTypeFilter ? _selectedType : widget.filterType;
    // Numerators come from the filtered events (total / per-type). We sort the
    // filtered list for stable rendering of the chart numerators.
    final filteredEvents = typeToUse == null
        ? widget.data.events
        : (widget.data.eventsByType[typeToUse] ?? []);
    final filteredSortedEvents = List<SexualEvent>.from(filteredEvents)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final event in filteredSortedEvents) {
      // Check which selected activities this event has
      final eventActivities = <String>{};
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          for (final count in participant.activityCounts) {
            // Use categoryReference + activityName as the activity identifier
            final catRef = count.categoryReference.reference;
            final actName = count.activityName;
            final id = '$catRef:$actName';
            if (_selectedPropertyIds.contains(id)) {
              eventActivities.add(id);
            }
          }
        }
      }

      if (eventActivities.isNotEmpty) {
        final day = event.date.weekday;
        for (final id in eventActivities) {
          dayCounts[day]![id] = (dayCounts[day]![id] ?? 0) + 1;
        }
      }
    }

    // Compute effective window and weekday-occurrence denominators using the same
    // logic as the central AveragesCalculator so per-weekday denominators match.
    final now = DateTime.now();
    final thisYearStart =
        widget.data.startDate ?? DateTime(now.year, now.month - 11, 1);

    DateTime windowStart = thisYearStart;
    DateTime windowEnd = thisYearStart;
    // Use the sortedEvents list for deterministic first/last lookups and iteration.
    if (filteredSortedEvents.isNotEmpty) {
      final firstEventDate = filteredSortedEvents.first.date;
      final lastEventDate = filteredSortedEvents.last.date;

      // If the requested start is before the first event, use the first event date.
      if (firstEventDate.isAfter(windowStart)) windowStart = firstEventDate;

      // Find the last event that lies within the requested window.
      DateTime lastInWindow = windowStart;
      for (final ev in filteredSortedEvents) {
        if (!ev.date.isBefore(thisYearStart)) {
          if (ev.date.isAfter(lastInWindow)) lastInWindow = ev.date;
        }
      }

      // If there were no events at/after thisYearStart, fall back to last event.
      if (lastInWindow.isBefore(windowStart)) {
        windowEnd = lastEventDate;
      } else {
        windowEnd = lastInWindow;
      }

      // Safety: clamp windowEnd so it is not before windowStart
      if (windowEnd.isBefore(windowStart)) windowEnd = windowStart;
    }

    // Count calendar occurrences of each weekday inside the effective window.
    final weekdayOccurrences = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
    if (!windowEnd.isBefore(windowStart)) {
      DateTime cursor = DateTime(
        windowStart.year,
        windowStart.month,
        windowStart.day,
      );
      final endDate = DateTime(windowEnd.year, windowEnd.month, windowEnd.day);
      while (!cursor.isAfter(endDate)) {
        weekdayOccurrences[cursor.weekday] =
            (weekdayOccurrences[cursor.weekday] ?? 0) + 1;
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    // Calculate max overlapping height using weekday-specific denominators.
    double maxValue = 0.0;
    for (int i = 1; i <= 7; i++) {
      final occ = (weekdayOccurrences[i] ?? 0);
      final denom = (occ < 1 ? 1 : occ).toDouble();
      for (final count in dayCounts[i]!.values) {
        final average = count / denom;
        if (average > maxValue) maxValue = average;
      }
    }

    final maxY = _calculateNiceMaxY(maxValue);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dayName = _getDayName(group.x.toInt() + 1);
              // rodIndex is always 0 because we have 1 rod per group in stacked

              // Customize tooltip to show breakdown
              final dayProperties = dayCounts[group.x.toInt() + 1]!;
              final sortedProps = dayProperties.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              final tooltipText = StringBuffer('$dayName\n');

              final occForDay = (weekdayOccurrences[group.x.toInt() + 1] ?? 0);
              final denomForDay = occForDay > 0 ? occForDay.toDouble() : 1.0;
              for (final entry in sortedProps) {
                if (entry.value > 0) {
                  final property = widget.data.sexualActivities[entry.key];
                  final name = property?.name ?? '';
                  final char = property?.displayCharacter;
                  final label = char != null && char.isNotEmpty && char != '❔'
                      ? '$char $name'
                      : name;
                  final val = entry.value / denomForDay;
                  tooltipText.writeln('$label: ${val.toStringAsFixed(1)}');
                }
              }

              return BarTooltipItem(
                tooltipText.toString().trim(),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                return Text(
                  value.toStringAsFixed(1),
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
          horizontalInterval: _calculateNiceInterval(maxY),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1,
            );
          },
        ),
        barGroups: List.generate(7, (index) {
          final dayOfWeek = index + 1;
          final properties = dayCounts[dayOfWeek]!;

          // Build overlapping bars
          final stackItems = <BarChartRodStackItem>[];
          final barValues = <MapEntry<Color, double>>[];

          // Collect values
          for (int i = 0; i < _topProperties.length; i++) {
            final id = _topProperties[i];
            if (!_selectedPropertyIds.contains(id)) continue;

            final rawCount = properties[id] ?? 0;
            final occForDay = (weekdayOccurrences[dayOfWeek] ?? 0);
            final denomForDay = occForDay > 0 ? occForDay.toDouble() : 1.0;
            final count = rawCount / denomForDay;
            if (count > 0) {
              final color = _colors[i % _colors.length];
              barValues.add(MapEntry(color, count));
            }
          }

          // Sort by value descending (largest first so it's behind)
          barValues.sort((a, b) => b.value.compareTo(a.value));

          double maxYInGroup = 0;
          for (final item in barValues) {
            stackItems.add(BarChartRodStackItem(0, item.value, item.key));
            if (item.value > maxYInGroup) maxYInGroup = item.value;
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: maxYInGroup,
                rodStackItems: stackItems,
                color: Colors.transparent,
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

  Widget _buildHistoryChart(BuildContext context) {
    // Filter events for selected properties and group by month
    final monthlyCounts = <String, Map<String, int>>{};
    final now = DateTime.now();
    // Use the same time window as other charts
    final twelveMonthsAgo = DateTime(now.year, now.month - 11, 1);
    final shouldLimitTo12Months = widget.data.startDate == null;

    // Pre-fill months to ensure continuity on X-axis (using global monthly counts keys as reference)
    final allMonths = widget.data.monthlyCounts.keys.where((key) {
      if (!shouldLimitTo12Months) return true;
      final monthDate = DateTime.parse('$key-01');
      return monthDate.isAfter(
        twelveMonthsAgo.subtract(const Duration(days: 1)),
      );
    }).toList()..sort();

    for (final month in allMonths) {
      monthlyCounts[month] = {};
      for (final id in _selectedPropertyIds) {
        monthlyCounts[month]![id] = 0;
      }
    }

    final typeToUse = widget.showTypeFilter ? _selectedType : widget.filterType;
    final events = typeToUse == null
        ? widget.data.events
        : (widget.data.eventsByType[typeToUse] ?? []);

    for (final event in events) {
      final monthKey = DateFormat('yyyy-MM').format(event.date);
      if (!monthlyCounts.containsKey(monthKey)) continue;

      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          for (final count in participant.activityCounts) {
            // Use categoryReference + activityName as the activity identifier
            final catRef = count.categoryReference.reference;
            final actName = count.activityName;
            final id = '$catRef:$actName';
            if (_selectedPropertyIds.contains(id)) {
              monthlyCounts[monthKey]![id] =
                  (monthlyCounts[monthKey]![id] ?? 0) + count.count;
            }
          }
        }
      }
    }

    final sortedMonths = allMonths;

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

    // Calculate max value (max of overlaps)
    double maxValue = 0.0;
    for (final key in sortedMonths) {
      for (final count in monthlyCounts[key]!.values) {
        if (count > maxValue) maxValue = count.toDouble();
      }
    }

    // Smart scaling
    double maxY = (maxValue / 5).ceil() * 5.0;
    if (maxY == 0) maxY = 5.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (group.x.toInt() >= 0 &&
                  group.x.toInt() < sortedMonths.length) {
                final monthKey = sortedMonths[group.x.toInt()];
                final date = DateTime.parse('$monthKey-01');

                final dayProperties = monthlyCounts[monthKey]!;
                final sortedProps = dayProperties.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                final tooltipText = StringBuffer(
                  '${DateFormat('MMMM yyyy').format(date)}\n',
                );

                for (final entry in sortedProps) {
                  if (entry.value > 0) {
                    final property = widget.data.sexualActivities[entry.key];
                    final name = property?.name ?? '';
                    final char = property?.displayCharacter;
                    final label = char != null && char.isNotEmpty && char != '❔'
                        ? '$char $name'
                        : name;
                    tooltipText.writeln('$label: ${entry.value}');
                  }
                }

                return BarTooltipItem(
                  tooltipText.toString().trim(),
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
          final categories = monthlyCounts[monthKey]!;

          // Build overlapping bars
          final stackItems = <BarChartRodStackItem>[];
          final barValues = <MapEntry<Color, double>>[];

          // Process in order of top properties
          for (int i = 0; i < _topProperties.length; i++) {
            final id = _topProperties[i];
            if (!_selectedPropertyIds.contains(id)) continue;

            final count = (categories[id] ?? 0).toDouble();
            if (count > 0) {
              final color = _colors[i % _colors.length];
              barValues.add(MapEntry(color, count));
            }
          }

          // Sort by value descending (largest first so it's behind)
          barValues.sort((a, b) => b.value.compareTo(a.value));

          double maxYInGroup = 0;
          for (final item in barValues) {
            stackItems.add(BarChartRodStackItem(0, item.value, item.key));
            if (item.value > maxYInGroup) maxYInGroup = item.value;
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: maxYInGroup,
                rodStackItems: stackItems,
                color: Colors.transparent,
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

  String _getDayName(int dayOfWeek) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[(dayOfWeek - 1) % 7];
  }

  String _getDayAbbreviation(int dayOfWeek) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(dayOfWeek - 1) % 7];
  }

  double _calculateNiceMaxY(double maxValue) {
    if (maxValue == 0) return 5.0;
    final paddedMax = maxValue * 1.2;
    if (paddedMax <= 1) return (paddedMax * 2).ceil() / 2;
    if (paddedMax <= 5) return paddedMax.ceil().toDouble();
    if (paddedMax <= 10) return ((paddedMax / 2).ceil() * 2).toDouble();
    if (paddedMax <= 20) return ((paddedMax / 5).ceil() * 5).toDouble();
    return ((paddedMax / 10).ceil() * 10).toDouble();
  }

  double _calculateNiceInterval(double maxY) {
    if (maxY == 0) return 1.0;
    final rawInterval = maxY / 5;
    if (rawInterval <= 0.5) return 0.5;
    if (rawInterval <= 1) return 1.0;
    if (rawInterval <= 2) return 2.0;
    if (rawInterval <= 5) return 5.0;
    return ((rawInterval / 5).ceil() * 5).toDouble();
  }

  Future<void> _showActivityPicker() async {
    // Build a map of categoryId -> Set<compositeKey> using the count's own
    // categoryReference so activities are grouped under their actual owning
    // category (which may be a subcategory).
    final categoryActivities = <String, Set<String>>{};

    for (final event in widget.data.events) {
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          for (final count in participant.activityCounts) {
            final catRef = count.categoryReference.reference;
            final actName = count.activityName;
            final actId = '$catRef:$actName';
            categoryActivities.putIfAbsent(catRef, () => {}).add(actId);
          }
        }
      }
    }

    await showDialog(
      context: context,
      builder: (context) => _ActivityPickerDialog(
        data: widget.data,
        categoryActivities: categoryActivities,
        selectedIds: _selectedPropertyIds,
        onSelectionChanged: (newSelection) {
          setState(() {
            _selectedPropertyIds.clear();
            _selectedPropertyIds.addAll(newSelection);
            final visibleSet = {..._topProperties, ..._selectedPropertyIds};
            _visibleProperties = visibleSet.toList();
          });
        },
      ),
    );
  }
}

// ── Activity Picker Dialog ─────────────────────────────────────────────────

class _ActivityPickerDialog extends StatefulWidget {
  final ActivityBreakdownData data;

  /// catId -> set of composite keys ("catId:activityName") seen in events.
  final Map<String, Set<String>> categoryActivities;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  const _ActivityPickerDialog({
    required this.data,
    required this.categoryActivities,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<_ActivityPickerDialog> createState() => _ActivityPickerDialogState();
}

class _ActivityPickerDialogState extends State<_ActivityPickerDialog> {
  late Set<String> _tempSelectedIds;

  // ── Hierarchy helpers ──────────────────────────────────────────────────

  Set<String> get _subcategoryIds {
    final ids = <String>{};
    for (final cat in widget.data.allCategoriesMap.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) ids.add(ref.reference);
      }
    }
    return ids;
  }

  List<SexualActivityCategory> _topLevel(Set<String> subcatIds) {
    // Only include top-level categories that have activity data (directly or
    // via subcategories).
    return widget.data.allCategoriesMap.values.where((c) {
      if (subcatIds.contains(c.id)) return false;
      if (widget.categoryActivities.containsKey(c.id)) return true;
      // Check if any subcategory has data.
      for (final ref in c.subCategories) {
        if (widget.categoryActivities.containsKey(ref.reference)) {
          return true;
        }
      }
      return false;
    }).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<SexualActivityCategory> _subsOf(SexualActivityCategory parent) {
    return parent.subCategories
        .where((r) => r.reference.isNotEmpty)
        .map((r) => widget.data.allCategoriesMap[r.reference])
        .whereType<SexualActivityCategory>()
        .where((s) => widget.categoryActivities.containsKey(s.id))
        .toList();
  }

  /// Activities in [cat] sorted by their user-defined sortOrder.
  List<MapEntry<String, String>> _sortedActivitiesFor(
    SexualActivityCategory cat,
  ) {
    final actIds = widget.categoryActivities[cat.id] ?? {};
    // Build a sortable list: each entry is (compositeKey, activityName)
    final entries = actIds.map((id) {
      final activity = widget.data.sexualActivities[id];
      return MapEntry(id, activity?.name ?? '');
    }).toList();

    // Sort by sortOrder from the category's own activities list if available,
    // falling back to alphabetical by name.
    final catActivities = cat.activities;
    final orderMap = <String, int>{};
    for (int i = 0; i < catActivities.length; i++) {
      orderMap[catActivities[i].name] = catActivities[i].sortOrder;
    }

    entries.sort((a, b) {
      final orderA = orderMap[a.value] ?? 9999;
      final orderB = orderMap[b.value] ?? 9999;
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.value.compareTo(b.value);
    });

    return entries;
  }

  // ── Selection helpers ──────────────────────────────────────────────────

  Set<String> _allKeysFor(SexualActivityCategory cat) {
    final keys = <String>{};
    for (final id in widget.categoryActivities[cat.id] ?? {}) {
      keys.add(id);
    }
    for (final sub in _subsOf(cat)) {
      for (final id in widget.categoryActivities[sub.id] ?? {}) {
        keys.add(id);
      }
    }
    return keys;
  }

  bool _allSelectedFor(SexualActivityCategory cat) {
    final keys = _allKeysFor(cat);
    return keys.isNotEmpty && keys.every((k) => _tempSelectedIds.contains(k));
  }

  bool _anySelectedFor(SexualActivityCategory cat) =>
      _allKeysFor(cat).any((k) => _tempSelectedIds.contains(k));

  Set<String> _subKeys(SexualActivityCategory sub) =>
      (widget.categoryActivities[sub.id] ?? {}).toSet();

  bool _allSubSelected(SexualActivityCategory sub) {
    final keys = _subKeys(sub);
    return keys.isNotEmpty && keys.every((k) => _tempSelectedIds.contains(k));
  }

  bool _anySubSelected(SexualActivityCategory sub) =>
      _subKeys(sub).any((k) => _tempSelectedIds.contains(k));

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final subcatIds = _subcategoryIds;
    final topLevel = _topLevel(subcatIds);

    return AlertDialog(
      title: const Text('Select Activities'),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: topLevel.length,
          itemBuilder: (context, i) => _buildParentSection(topLevel[i]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => setState(() => _tempSelectedIds.clear()),
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSelectionChanged(_tempSelectedIds);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildParentSection(SexualActivityCategory cat) {
    final subs = _subsOf(cat);
    final directActivities = _sortedActivitiesFor(cat);
    final allSel = _allSelectedFor(cat);
    final anySel = _anySelectedFor(cat);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent header row
        InkWell(
          onTap: () {
            final all = _allKeysFor(cat);
            setState(() {
              if (allSel) {
                _tempSelectedIds.removeAll(all);
              } else {
                _tempSelectedIds.addAll(all);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: allSel ? true : (anySel ? null : false),
                    tristate: true,
                    visualDensity: VisualDensity.compact,
                    onChanged: (_) {
                      final all = _allKeysFor(cat);
                      setState(() {
                        if (allSel) {
                          _tempSelectedIds.removeAll(all);
                        } else {
                          _tempSelectedIds.addAll(all);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  cat.displayCharacter ?? '❔',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (subs.isNotEmpty)
                  Icon(
                    Icons.account_tree_outlined,
                    size: 14,
                    color: scheme.outline,
                  ),
              ],
            ),
          ),
        ),

        // Direct activities (indented)
        if (directActivities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: directActivities
                  .map((e) => _buildActivityTile(e.key))
                  .toList(),
            ),
          ),

        // Subcategory sections (indented)
        ...subs.map((sub) => _buildSubSection(sub)),

        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSubSection(SexualActivityCategory sub) {
    final activities = _sortedActivitiesFor(sub);
    final allSel = _allSubSelected(sub);
    final anySel = _anySubSelected(sub);
    final subKeys = _subKeys(sub);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-category header
          InkWell(
            onTap: () {
              setState(() {
                if (allSel) {
                  _tempSelectedIds.removeAll(subKeys);
                } else {
                  _tempSelectedIds.addAll(subKeys);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: allSel ? true : (anySel ? null : false),
                      tristate: true,
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) {
                        setState(() {
                          if (allSel) {
                            _tempSelectedIds.removeAll(subKeys);
                          } else {
                            _tempSelectedIds.addAll(subKeys);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    sub.displayCharacter ?? '❔',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sub.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Activities under this sub
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: activities
                  .map((e) => _buildActivityTile(e.key))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(String actId) {
    final activity = widget.data.sexualActivities[actId];
    final actName = activity?.name ?? 'Unknown';
    final actChar = activity?.displayCharacter ?? '';
    final isSelected = _tempSelectedIds.contains(actId);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => setState(() {
        if (isSelected) {
          _tempSelectedIds.remove(actId);
        } else {
          _tempSelectedIds.add(actId);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isSelected,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => setState(() {
                  if (isSelected) {
                    _tempSelectedIds.remove(actId);
                  } else {
                    _tempSelectedIds.add(actId);
                  }
                }),
              ),
            ),
            const SizedBox(width: 10),
            Text(actChar, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                actName,
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
              ),
            ),
            if (activity?.stiRisk ?? false)
              Tooltip(
                message: 'STI Risk',
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.purple.shade700,
                ),
              )
            else if (activity?.healthRisk ?? false)
              Tooltip(
                message: 'Health Risk',
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
