import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/data/models.dart';
import 'package:logging/logging.dart';
import 'models/analysis_data.dart';
import 'utils/analysis_calculator.dart';
import 'widgets/overview_stats_section.dart';
import 'widgets/monthly_activity_chart.dart';
import 'widgets/activity_type_distribution.dart';
import 'widgets/top_partners_section.dart';
import 'widgets/properties_by_activity_section.dart';
import 'widgets/time_patterns_section.dart';
import 'widgets/period_comparison_section.dart';
import 'widgets/event_averages_section.dart';
import 'widgets/property_partner_section.dart';

enum TimeWindow { last12Months, allTime, specificYear }

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger('AnalysisPage');
  int _refreshKey = 0;
  TimeWindow _timeWindow = TimeWindow.last12Months;
  int? _selectedYear;
  List<int> _availableYears = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Listen to provider changes to reload when data changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SexualEventsProvider>().addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    context.read<SexualEventsProvider>().removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    _refresh();
  }

  Future<AnalysisData> _loadData() async {
    final provider = context.read<SexualEventsProvider>();

    // Wait for provider to be ready
    await provider.ready;

    final allEvents = await provider.getAllEvents();
    _logger.info('Loaded ${allEvents.length} events');

    // Calculate available years from data
    if (allEvents.isNotEmpty) {
      final years = allEvents.map((e) => e.date.year).toSet().toList()..sort();
      // Only update if the years list has actually changed
      if (_availableYears.length != years.length ||
          !_availableYears.every((year) => years.contains(year))) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _availableYears = years;
            });
          }
        });
      }
    }

    // Filter events based on selected time window
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;
    List<SexualEvent> events;

    switch (_timeWindow) {
      case TimeWindow.last12Months:
        startDate = DateTime(now.year, now.month - 11, 1);
        events = allEvents.where((event) {
          return event.date.isAfter(
            startDate!.subtract(const Duration(days: 1)),
          );
        }).toList();
        _logger.info('Filtering to last 12 months (from $startDate)');
        break;
      case TimeWindow.allTime:
        events = allEvents;
        startDate = null;
        endDate = null;
        _logger.info('Using all-time data');
        break;
      case TimeWindow.specificYear:
        if (_selectedYear != null) {
          startDate = DateTime(_selectedYear!, 1, 1);
          endDate = DateTime(_selectedYear!, 12, 31, 23, 59, 59);
          events = allEvents.where((event) {
            return event.date.isAfter(
                  startDate!.subtract(const Duration(days: 1)),
                ) &&
                event.date.isBefore(endDate!.add(const Duration(days: 1)));
          }).toList();
          _logger.info('Filtering to year $_selectedYear');
        } else {
          events = allEvents;
        }
        break;
    }

    // Calculate all statistics
    final analysisData = await AnalysisCalculator.calculate(
      events,
      provider,
      startDate: startDate,
      endDate: endDate,
      timeWindowLabel: _getTimeWindowLabel(),
    );

    _logger.info('Calculated data - ${analysisData.totalEvents} total events');

    return analysisData;
  }

  void _refresh() {
    setState(() {
      _refreshKey++;
    });
  }

  void _showTimeWindowSelector() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select Time Window',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildTimeWindowOption(
                TimeWindow.last12Months,
                'Last 12 Months',
                'Rolling 12-month window',
                Icons.trending_up,
              ),
              _buildTimeWindowOption(
                TimeWindow.allTime,
                'All Time',
                'Complete history',
                Icons.all_inclusive,
              ),
              const Divider(height: 1),
              if (_availableYears.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    'Specific Years',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ..._availableYears.reversed.map((year) {
                return _buildYearOption(year);
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeWindowOption(
    TimeWindow window,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _timeWindow == window && _selectedYear == null;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
          : null,
      selected: isSelected,
      onTap: () {
        setState(() {
          _timeWindow = window;
          _selectedYear = null;
          _refreshKey++;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildYearOption(int year) {
    final isSelected =
        _timeWindow == TimeWindow.specificYear && _selectedYear == year;
    return ListTile(
      leading: Icon(
        Icons.calendar_today,
        color: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        year.toString(),
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      subtitle: Text('January - December $year'),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
          : null,
      selected: isSelected,
      onTap: () {
        setState(() {
          _timeWindow = TimeWindow.specificYear;
          _selectedYear = year;
          _refreshKey++;
        });
        Navigator.pop(context);
      },
    );
  }

  String _getTimeWindowLabel() {
    switch (_timeWindow) {
      case TimeWindow.last12Months:
        return 'Last 12 Months';
      case TimeWindow.allTime:
        return 'All Time';
      case TimeWindow.specificYear:
        return _selectedYear?.toString() ?? 'Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Stack(
      children: [
        FutureBuilder<AnalysisData>(
          key: ValueKey(_refreshKey),
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load analysis data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No data available'));
            }

            final analysisData = snapshot.data!;

            return RefreshIndicator(
              onRefresh: () async {
                _refresh();
                // Wait a frame for the refresh to trigger
                await Future.delayed(const Duration(milliseconds: 100));
              },
              child: ListView(
                children: [
                  // Time window indicator (always show for clarity)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Viewing ${_getTimeWindowLabel()} data',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Empty state
                  if (analysisData.totalEvents == 0)
                    _buildEmptyState()
                  else ...[
                    // Overview Stats Cards
                    OverviewStatsSection(data: analysisData),

                    // Monthly Activity Chart
                    MonthlyActivityChart(data: analysisData),

                    // Time Patterns
                    TimePatternsSection(data: analysisData),

                    // Period Comparisons (only for Last 12 Months)
                    PeriodComparisonSection(data: analysisData),

                    // Event Averages
                    EventAveragesSection(data: analysisData),

                    // Activity Type Distribution
                    ActivityTypeDistribution(data: analysisData),

                    // Properties by Activity Type
                    PropertiesByActivitySection(data: analysisData),

                    // Top Partners
                    TopPartnersSection(data: analysisData),

                    // Partner Diversity by Activity
                    PropertyPartnerSection(data: analysisData),

                    // Bottom padding
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            );
          },
        ),
        // Floating Action Button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'analysis_time_window_fab',
            onPressed: _showTimeWindowSelector,
            icon: const Icon(Icons.calendar_month),
            label: Text(_getTimeWindowLabel()),
            tooltip: 'Select time window',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging events to see your analysis.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
