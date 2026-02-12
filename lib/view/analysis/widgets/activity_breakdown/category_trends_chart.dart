import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:indulge/services/preferences_service.dart';
import '../../models/analysis_data.dart';
import '../../utils/analysis_colors.dart';

class CategoryTrendsChart extends StatefulWidget {
  final AnalysisData data;
  final AnalysisEventType? filterType;
  final bool showTypeFilter;

  const CategoryTrendsChart({
    super.key,
    required this.data,
    this.filterType,
    this.showTypeFilter = true,
  });

  @override
  State<CategoryTrendsChart> createState() => _CategoryTrendsChartState();
}

class _CategoryTrendsChartState extends State<CategoryTrendsChart>
    with AutomaticKeepAliveClientMixin {
  AnalysisEventType? _selectedType;
  final Set<String> _selectedCategoryIds = {};
  bool _showPattern = false;
  List<String> _topCategories = [];
  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _calculateTopCategories();

    // Load persisted preferences (show-pattern and selected categories).
    // Use post-frame callback to ensure the widget is fully mounted before any
    // operations that might depend on inherited widgets / providers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShowPatternPreference();
      _loadPersistedSelectedCategories();
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant CategoryTrendsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _calculateTopCategories();
    }
  }

  void _calculateTopCategories() {
    // Count category occurrences across all events
    final counts = <String, int>{};
    for (final event in widget.data.events) {
      final seenInEvent = <String>{};
      for (final activity in event.activities) {
        final id = activity.category.reference;
        if (seenInEvent.add(id)) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
    }

    // Sort by count descending
    final sortedIds = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    // Take top 5
    setState(() {
      _topCategories = sortedIds.take(5).toList();
    });
  }

  /// Load the persisted "show pattern" preference for this chart via PreferencesService.
  /// Also subscribe to the service notifier so the chart updates if the preference
  /// changes elsewhere in the app.
  Future<void> _loadShowPatternPreference() async {
    try {
      final svc = Provider.of<PreferencesService>(context, listen: false);
      final val = svc.getCategoryShowPattern();
      if (mounted) {
        setState(() {
          _showPattern = val;
        });
      } else {
        _showPattern = val;
      }

      // Keep in sync with future preference changes.
      svc.categoryShowPatternNotifier.addListener(() {
        final newVal = svc.getCategoryShowPattern();
        if (mounted) {
          setState(() {
            _showPattern = newVal;
          });
        } else {
          _showPattern = newVal;
        }
      });
    } catch (e) {
      // Best-effort: ignore failures and keep the default value.
    }
  }

  /// Load persisted selected category IDs via `PreferencesService`.
  /// Subscribes to the service notifier so the selection stays in sync.
  Future<void> _loadPersistedSelectedCategories() async {
    try {
      final svc = Provider.of<PreferencesService>(context, listen: false);
      final ids = svc.getCategorySelectedIds().toSet();

      if (mounted) {
        setState(() {
          _selectedCategoryIds
            ..clear()
            ..addAll(ids);
        });
      } else {
        _selectedCategoryIds
          ..clear()
          ..addAll(ids);
      }

      // Keep in sync with future preference changes.
      svc.categorySelectedIdsNotifier.addListener(() {
        final newIds = svc.getCategorySelectedIds().toSet();
        if (mounted) {
          setState(() {
            _selectedCategoryIds
              ..clear()
              ..addAll(newIds);
          });
        } else {
          _selectedCategoryIds
            ..clear()
            ..addAll(newIds);
        }
      });
    } catch (_) {
      // Ignore failures and keep the current in-memory selection.
    }
  }

  /// Persist the currently-selected category IDs via `PreferencesService`.
  Future<void> _persistSelectedCategories() async {
    try {
      final svc = Provider.of<PreferencesService>(context, listen: false);
      await svc.setCategorySelectedIds(_selectedCategoryIds.toList());
    } catch (_) {
      // Ignore persistence failures.
    }
  }

  /// Persist the "show pattern" preference via PreferencesService.
  Future<void> _persistShowPattern(bool value) async {
    try {
      final svc = Provider.of<PreferencesService>(context, listen: false);
      await svc.setCategoryShowPattern(value);
    } catch (e) {
      // Ignore persistence failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_topCategories.isEmpty) {
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
                        'Category Trends',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _showPattern
                            ? 'Average events per day of week'
                            : 'Total events per month',
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
                    final val = newSelection.first;
                    setState(() {
                      _showPattern = val;
                    });
                    // Persist preference (best-effort)
                    _persistShowPattern(val);
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
                  if (_selectedCategoryIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        avatar: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear'),
                        onPressed: () {
                          setState(() {
                            _selectedCategoryIds.clear();
                          });
                          // Persist the cleared selection (best-effort).
                          _persistSelectedCategories();
                        },
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.only(right: 8),
                      ),
                    ),
                  ..._topCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final id = entry.value;
                    final category = widget.data.activityCategories[id];
                    final name = category?.name ?? 'Unknown';
                    final char = category?.displayCharacter;
                    final label = char != null && char.isNotEmpty
                        ? '$char $name'
                        : name;
                    final color = _colors[index % _colors.length];
                    final isSelected = _selectedCategoryIds.contains(id);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategoryIds.add(id);
                            } else {
                              _selectedCategoryIds.remove(id);
                            }
                          });
                          // Persist changes to the selected categories immediately.
                          _persistSelectedCategories();
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
    if (_selectedCategoryIds.isEmpty) {
      return const Center(child: Text('Select at least one category'));
    }

    return _showPattern
        ? _buildPatternChart(context)
        : _buildHistoryChart(context);
  }

  Widget _buildPatternChart(BuildContext context) {
    // Count days of week for each selected category
    final dayCounts = <int, Map<String, int>>{};
    for (int i = 1; i <= 7; i++) {
      dayCounts[i] = {};
      for (final id in _selectedCategoryIds) {
        dayCounts[i]![id] = 0;
      }
    }

    final typeToUse = widget.showTypeFilter ? _selectedType : widget.filterType;
    final events = typeToUse == null
        ? widget.data.events
        : (widget.data.eventsByType[typeToUse] ?? []);

    for (final event in events) {
      // Check which selected categories this event has
      final eventCategories = <String>{};
      for (final activity in event.activities) {
        final id = activity.category.reference;
        if (_selectedCategoryIds.contains(id)) {
          eventCategories.add(id);
        }
      }

      if (eventCategories.isNotEmpty) {
        final day = event.date.weekday;
        for (final id in eventCategories) {
          dayCounts[day]![id] = (dayCounts[day]![id] ?? 0) + 1;
        }
      }
    }

    // Calculate total weeks span for averaging
    double totalWeeksSpan = 1.0;
    if (widget.data.events.isNotEmpty) {
      final firstDate = widget.data.events.first.date;
      final lastDate = widget.data.events.last.date;
      final daysDiff = lastDate.difference(firstDate).inDays + 1;
      totalWeeksSpan = (daysDiff / 7.0).clamp(1.0, double.infinity);
    }

    // Calculate max overlapping height
    double maxValue = 0.0;
    for (int i = 1; i <= 7; i++) {
      for (final count in dayCounts[i]!.values) {
        final average = count / totalWeeksSpan;
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
              final total = rod.toY;

              // Customize tooltip to show breakdown
              final dayCategories = dayCounts[group.x.toInt() + 1]!;
              final sortedCats = dayCategories.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              final tooltipText = StringBuffer('$dayName\n');

              for (final entry in sortedCats) {
                if (entry.value > 0) {
                  final category = widget.data.activityCategories[entry.key];
                  final name = category?.name ?? '';
                  final char = category?.displayCharacter;
                  final label = char != null && char.isNotEmpty
                      ? '$char $name'
                      : name;
                  final val = entry.value / totalWeeksSpan;
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
          final categories = dayCounts[dayOfWeek]!;

          // Build overlapping bars
          final stackItems = <BarChartRodStackItem>[];
          final barValues = <MapEntry<Color, double>>[];

          // Collect values
          for (int i = 0; i < _topCategories.length; i++) {
            final id = _topCategories[i];
            if (!_selectedCategoryIds.contains(id)) continue;

            final rawCount = categories[id] ?? 0;
            final count = rawCount / totalWeeksSpan;
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
                color: Colors.transparent, // Color comes from stack items
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
    // Filter events for selected categories and group by month
    final monthlyCounts = <String, Map<String, int>>{};
    final now = DateTime.now();
    // Use the same time window as other charts
    final twelveMonthsAgo = DateTime(now.year, now.month - 11, 1);
    final shouldLimitTo12Months = widget.data.startDate == null;

    // Pre-fill months
    final allMonths = widget.data.monthlyCounts.keys.where((key) {
      if (!shouldLimitTo12Months) return true;
      final monthDate = DateTime.parse('$key-01');
      return monthDate.isAfter(
        twelveMonthsAgo.subtract(const Duration(days: 1)),
      );
    }).toList()..sort();

    for (final month in allMonths) {
      monthlyCounts[month] = {};
      for (final id in _selectedCategoryIds) {
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
        final id = activity.category.reference;
        if (_selectedCategoryIds.contains(id)) {
          monthlyCounts[monthKey]![id] =
              (monthlyCounts[monthKey]![id] ?? 0) + 1;
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
                final total = rod.toY;

                final dayCategories = monthlyCounts[monthKey]!;
                final sortedCats = dayCategories.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                final tooltipText = StringBuffer(
                  '${DateFormat('MMMM yyyy').format(date)}\n',
                );

                for (final entry in sortedCats) {
                  if (entry.value > 0) {
                    final category = widget.data.activityCategories[entry.key];
                    final name = category?.name ?? '';
                    final char = category?.displayCharacter;
                    final label = char != null && char.isNotEmpty
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

          // Process in order of top categories
          for (int i = 0; i < _topCategories.length; i++) {
            final id = _topCategories[i];
            if (!_selectedCategoryIds.contains(id)) continue;

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
}
