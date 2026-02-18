import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/overview_data.dart';
import '../../utils/analysis_colors.dart';
import 'package:provider/provider.dart';
import 'package:indulge/services/preferences_service.dart';
import '../../models/analysis_event_type.dart';

class MonthlyActivityChart extends StatefulWidget {
  final OverviewData data;

  const MonthlyActivityChart({super.key, required this.data});

  @override
  State<MonthlyActivityChart> createState() => _MonthlyActivityChartState();
}

class _MonthlyActivityChartState extends State<MonthlyActivityChart>
    with AutomaticKeepAliveClientMixin {
  AnalysisEventType? _selectedType; // null for Total
  bool _showPattern = false;

  // The show-pattern preference is persisted and exposed via PreferencesService.
  // `true` -> Pattern view, `false` -> History view.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShowPatternPreference();

      // Load persisted activity filter (Total/Solo/Couple/Group) and subscribe
      // to changes from PreferencesService so the widget stays in sync.
      try {
        final svc = Provider.of<PreferencesService>(context, listen: false);
        final persisted = svc.getActivityFilter();
        if (mounted) {
          setState(() {
            _selectedType = persisted;
          });
        } else {
          _selectedType = persisted;
        }

        svc.activityFilterNotifier.addListener(() {
          final newVal = svc.getActivityFilter();
          if (mounted) {
            setState(() {
              _selectedType = newVal;
            });
          } else {
            _selectedType = newVal;
          }
        });
      } catch (_) {
        // Best-effort: ignore failures (e.g. provider not available)
      }
    });
  }

  /// Read the persisted preference via PreferencesService and listen for updates.
  void _loadShowPatternPreference() {
    try {
      final svc = Provider.of<PreferencesService>(context, listen: false);
      final val = svc.getMonthlyShowPattern();
      if (mounted) {
        setState(() {
          _showPattern = val;
        });
      } else {
        _showPattern = val;
      }

      // Keep in sync with future preference changes.
      svc.monthlyShowPatternNotifier.addListener(() {
        final newVal = svc.getMonthlyShowPattern();
        if (mounted) {
          setState(() {
            _showPattern = newVal;
          });
        } else {
          _showPattern = newVal;
        }
      });
    } catch (e) {
      // Best-effort: ignore failures and keep default.
    }
  }

  /// Persist the preference via PreferencesService (best-effort).
  Future<void> _setShowPattern(bool value) async {
    if (mounted) {
      setState(() {
        _showPattern = value;
      });
    }
    try {
      final svc = Provider.of<PreferencesService>(context, listen: false);
      await svc.setMonthlyShowPattern(value);
    } catch (e) {
      // silently ignore preference save failures
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.data.monthlyCounts.isEmpty) {
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
                        'Monthly Activity',
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
                    // Persist the user's choice and update local state.
                    final newVal = newSelection.first;
                    _setShowPattern(newVal);
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Total', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Solo', AnalysisEventType.solo),
                  const SizedBox(width: 8),
                  _buildFilterChip('Couple', AnalysisEventType.couple),
                  const SizedBox(width: 8),
                  _buildFilterChip('Group', AnalysisEventType.group),
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

  Widget _buildFilterChip(String label, AnalysisEventType? type) {
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
    return _showPattern
        ? _buildPatternChart(context)
        : _buildHistoryChart(context);
  }

  Widget _buildPatternChart(BuildContext context) {
    Color barColor;
    if (_selectedType == null) {
      barColor = AnalysisColors.total;
    } else {
      barColor = AnalysisColors.getColor(_selectedType!);
    }

    // Use precomputed averages from AnalysisData (scoped to the selected window).
    // Fall back to zeros if the maps are missing.
    final averages = <int, double>{};
    double maxValue = 0.0;

    if (_selectedType == null) {
      // Total averages (AnalysisData provides a map 1..7 -> double)
      for (int i = 1; i <= 7; i++) {
        final v = widget.data.averageEventsPerDayOfWeek[i] ?? 0.0;
        averages[i] = v;
        if (v > maxValue) maxValue = v;
      }
    } else {
      // Per-type averages: AnalysisData.averageDayOfWeekCountsByType holds
      // a map per AnalysisEventType -> (1..7 -> double)
      final map =
          widget.data.averageDayOfWeekCountsByType[_selectedType!] ?? {};
      for (int i = 1; i <= 7; i++) {
        final v = map[i] ?? 0.0;
        averages[i] = v;
        if (v > maxValue) maxValue = v;
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
              final value = rod.toY;
              return BarTooltipItem(
                '$dayName\n${value.toStringAsFixed(1)}',
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
          final value = averages[dayOfWeek] ?? 0.0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: barColor,
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
    // Determine which data map to use
    Map<String, int> counts;
    Color barColor;

    if (_selectedType == null) {
      counts = widget.data.monthlyCounts;
      barColor = AnalysisColors.total;
    } else {
      counts = widget.data.monthlyCountsByType[_selectedType!] ?? {};
      barColor = AnalysisColors.getColor(_selectedType!);
    }

    // For "All Time" view, show last 12 months to keep chart readable
    // For other views, show all months in the selected time window
    final now = DateTime.now();
    final twelveMonthsAgo = DateTime(now.year, now.month - 11, 1);

    // If startDate is null (All Time), limit to last 12 months
    // Otherwise show all data from the selected window
    final shouldLimitTo12Months = widget.data.startDate == null;

    final filteredMonths =
        widget
            .data
            .monthlyCounts
            .keys // Always use total keys for X-axis stability
            .where((key) {
              if (!shouldLimitTo12Months) {
                return true; // Show all months for specific time windows
              }
              final monthDate = DateTime.parse('$key-01');
              return monthDate.isAfter(
                twelveMonthsAgo.subtract(const Duration(days: 1)),
              );
            })
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
    double maxValue = 0.0;
    if (sortedMonths.isNotEmpty) {
      for (final key in sortedMonths) {
        double value = (counts[key] ?? 0).toDouble();
        if (value > maxValue) maxValue = value;
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
                final value = rod.toY;
                final label =
                    '${value.toInt()} activit${value.toInt() != 1 ? 'ies' : 'y'}';

                return BarTooltipItem(
                  '${DateFormat('MMMM yyyy').format(date)}\n$label',
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
          double value = (counts[monthKey] ?? 0).toDouble();

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: barColor,
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
