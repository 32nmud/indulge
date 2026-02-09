import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'models/analysis_data.dart';
import 'utils/analysis_calculator.dart';
import 'widgets/overview_stats_section.dart';
import 'widgets/monthly_activity_chart.dart';
import 'widgets/activity_type_distribution.dart';
import 'widgets/top_partners_section.dart';
import 'widgets/properties_by_activity_section.dart';

import 'widgets/time_patterns_section.dart';
import 'widgets/streak_section.dart';
import 'widgets/period_comparison_section.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger('AnalysisPage');
  DateTimeRange? _selectedDateRange;
  int _refreshKey = 0;

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

    // Filter by date range if selected
    final events = _selectedDateRange != null
        ? allEvents.where((event) {
            return event.date.isAfter(
                  _selectedDateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                event.date.isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1)),
                );
          }).toList()
        : allEvents;

    _logger.info('${events.length} events after filtering');

    // Calculate all statistics
    final analysisData = AnalysisCalculator.calculate(
      events,
      provider.state,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );

    _logger.info('Calculated data - ${analysisData.totalEvents} total events');

    return analysisData;
  }

  void _refresh() {
    setState(() {
      _refreshKey++;
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(2020);
    final lastDate = DateTime(now.year, now.month, now.day);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Theme.of(context).primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _refreshKey++;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: [
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearDateRange,
              tooltip: 'Clear date filter',
            ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select date range',
          ),
        ],
      ),
      body: FutureBuilder<AnalysisData>(
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                // Date range indicator
                if (_selectedDateRange != null) _buildDateRangeIndicator(),

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

                  // Period Comparisons & Averages
                  PeriodComparisonSection(data: analysisData),

                  // Activity Type Distribution
                  ActivityTypeDistribution(data: analysisData),

                  // Properties by Activity Type
                  PropertiesByActivitySection(data: analysisData),

                  // Streaks & Milestones
                  StreakSection(data: analysisData),

                  // Top Partners
                  TopPartnersSection(data: analysisData),

                  // Bottom padding
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeIndicator() {
    final startFormatted = DateFormat(
      'MMM d, yyyy',
    ).format(_selectedDateRange!.start);
    final endFormatted = DateFormat(
      'MMM d, yyyy',
    ).format(_selectedDateRange!.end);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing data from $startFormatted to $endFormatted',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: _clearDateRange,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDateRange != null
                  ? 'No events found in the selected date range.\nTry adjusting your filters.'
                  : 'Start logging events to see your analysis.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
            if (_selectedDateRange != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _clearDateRange,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
