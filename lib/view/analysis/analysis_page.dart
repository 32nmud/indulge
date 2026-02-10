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
import 'widgets/cumulative_activities_chart.dart';
import 'widgets/cumulative_properties_chart.dart';

enum TimeWindow { last12Months, allTime, specificYear }

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger('AnalysisPage');
  TimeWindow _timeWindow = TimeWindow.last12Months;
  int? _selectedYear;
  List<int> _availableYears = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;
  AnalysisData? _currentData;
  bool _isLoading = false;

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
    _pageController.dispose();
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
    );

    _logger.info('Calculated data - ${analysisData.totalEvents} total events');

    return analysisData;
  }

  void _refresh() {
    _loadDataAsync();
  }

  Future<void> _loadDataAsync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _loadData();
      if (mounted) {
        setState(() {
          _currentData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analysis data: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: _refresh),
          ),
        );
      }
    }
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
        });
        Navigator.pop(context);
        _refresh();
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
        });
        Navigator.pop(context);
        _refresh();
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

    // Load data on first build or when refresh is triggered
    if (_currentData == null && !_isLoading) {
      _loadDataAsync();
    }

    return Stack(
      children: [
        _currentData == null
            ? const Center(child: CircularProgressIndicator())
            : _currentData!.totalEvents == 0
            ? _buildEmptyState()
            : Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _currentPage == 4
                        ? const SizedBox.shrink()
                        : _buildTimeWindowSelector(),
                  ),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [
                            Colors.white,
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.85, 0.95, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await _loadDataAsync();
                        },
                        child: PageView(
                          controller: _pageController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          children: [
                            _buildOverviewPage(_currentData!),
                            _buildTimeSeriesPage(_currentData!),
                            _buildActivityBreakdownPage(_currentData!),
                            _buildPartnerBreakdownPage(_currentData!),
                            _buildPeriodComparisonPage(_currentData!),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildPageIndicator(),
                ],
              ),
        if (_isLoading && _currentData != null)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildTimeWindowSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Period:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTimeWindowChip(
                    TimeWindow.last12Months,
                    'Last 12 Months',
                    null,
                  ),
                  const SizedBox(width: 8),
                  _buildTimeWindowChip(TimeWindow.allTime, 'All Time', null),
                  if (_availableYears.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ..._availableYears.reversed.map((year) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildTimeWindowChip(
                          TimeWindow.specificYear,
                          year.toString(),
                          year,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeWindowChip(TimeWindow window, String label, int? year) {
    final isSelected =
        _timeWindow == window &&
        (year == null ? _selectedYear == null : _selectedYear == year);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _timeWindow = window;
            _selectedYear = year;
          });
          _refresh();
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildOverviewPage(AnalysisData data) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildPageTitle(
          'Overview',
          Icons.dashboard,
          'Key stats, streaks, and summary',
        ),
        OverviewStatsSection(data: data),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimeSeriesPage(AnalysisData data) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildPageTitle(
          'Time Series',
          Icons.show_chart,
          'Charts and patterns over time',
        ),
        MonthlyActivityChart(data: data),
        CumulativeActivitiesChart(data: data),
        CumulativePropertiesChart(data: data),
        TimePatternsSection(data: data),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActivityBreakdownPage(AnalysisData data) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildPageTitle(
          'Activity Breakdown',
          Icons.list_alt,
          'Types, properties, and averages',
        ),
        EventAveragesSection(data: data),
        ActivityTypeDistribution(data: data),
        PropertiesByActivitySection(data: data),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPartnerBreakdownPage(AnalysisData data) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildPageTitle(
          'Partner Breakdown',
          Icons.people,
          'Top partners and diversity stats',
        ),
        TopPartnersSection(data: data),
        PropertyPartnerSection(data: data),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPeriodComparisonPage(AnalysisData data) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildPageTitle(
          'Period Comparison',
          Icons.compare_arrows,
          'Compare any two date ranges',
        ),
        PeriodComparisonSection(data: data),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPageTitle(String title, IconData icon, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 24 : 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
