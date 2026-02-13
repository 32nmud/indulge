import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/data/models.dart';
import 'package:logging/logging.dart';
import 'models/analysis_data.dart';
import 'utils/analysis_calculator.dart';
import 'widgets/overview/overview_page.dart';
import 'widgets/activity_breakdown/activity_breakdown_page.dart';
import 'widgets/partner_breakdown/partner_breakdown_page.dart';
import 'widgets/period_comparison/period_comparison_page.dart';
import 'widgets/period_comparison/period_comparison_section.dart';
import 'package:indulge/services/preferences_service.dart';

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

  // ── Persisted filter state (survives recalculations) ──────────────
  AnalysisEventType? _activityBreakdownFilterType;
  PeriodPreset _periodPreset = PeriodPreset.lastMonthVsThisMonth;
  DateTimeRange? _customFirstPeriod;
  DateTimeRange? _customSecondPeriod;

  /// Debounce timer to coalesce rapid-fire provider notifications.
  Timer? _debounceTimer;

  /// Tracks whether the underlying data has changed since the last
  /// successful calculation, so we can skip redundant recalculations.
  bool _isDirty = true;

  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Listen to provider changes to reload when data changes and load persisted prefs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Attach provider change listener
      context.read<SexualEventsProvider>().addListener(_onProviderChange);
      // Load persisted UI preferences (if any)
      _loadPreferences();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pageController.dispose();
    context.read<SexualEventsProvider>().removeListener(_onProviderChange);
    super.dispose();
  }

  /// Loads persisted UI preferences (period preset, custom ranges, activity filter)
  /// from the PreferencesService and applies them to the page state.
  Future<void> _loadPreferences() async {
    try {
      final prefs = Provider.of<PreferencesService>(context, listen: false);

      // Read persisted values (synchronous getters backed by the initialized service)
      final preset = prefs.getPeriodPreset();
      final activityFilter = prefs.getActivityFilter();
      final customFirst = prefs.getCustomFirst();
      final customSecond = prefs.getCustomSecond();
      final timeWindowIndex = prefs.getAnalysisTimeWindowIndex();
      final specificYear = prefs.getAnalysisSpecificYear();

      setState(() {
        // Apply loaded values if present
        _periodPreset = preset;
        _activityBreakdownFilterType = activityFilter;

        // Apply persisted analysis time window if present
        if (timeWindowIndex != null) {
          switch (timeWindowIndex) {
            case 0:
              _timeWindow = TimeWindow.last12Months;
              _selectedYear = null;
              break;
            case 1:
              _timeWindow = TimeWindow.allTime;
              _selectedYear = null;
              break;
            case 2:
              _timeWindow = TimeWindow.specificYear;
              _selectedYear = specificYear;
              break;
            default:
              _timeWindow = TimeWindow.last12Months;
          }
        }

        // If we have both endpoints for a first custom range, use them to seed the UI.
        // Note: the PreferencesService currently stores single DateTimes for custom
        // endpoints; if you later extend the service to store full ranges, update
        // this logic to reconstruct both DateTimeRange values accordingly.
        if (customFirst != null && customSecond != null) {
          _customFirstPeriod = DateTimeRange(
            start: customFirst,
            end: customSecond,
          );
        }
      });
    } catch (e) {
      _logger.warning('Failed to load preferences: $e');
    }
  }

  void _onProviderChange() {
    // Mark data as stale so the next load actually recalculates.
    _isDirty = true;

    // Debounce: if multiple notifications arrive in quick succession
    // (e.g. bulk edits), only trigger one recalculation after they settle.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _refresh);
  }

  Future<AnalysisData> _loadData({bool force = false}) async {
    // Skip recalculation if data hasn't changed and we already have results.
    if (!force && !_isDirty && _currentData != null) {
      _logger.info('Skipping recalculation — data is not dirty');
      return _currentData!;
    }

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

    // Calculation succeeded — data is no longer dirty.
    _isDirty = false;

    return analysisData;
  }

  void _refresh() {
    _isDirty = true;
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Load data on first build or when refresh is triggered
    if (_currentData == null && !_isLoading) {
      _loadDataAsync();
    }

    return SafeArea(
      child: Stack(
        children: [
          _currentData == null
              ? const Center(child: CircularProgressIndicator())
              : _currentData!.totalEvents == 0
              ? _buildEmptyState()
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Analysis',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _currentPage == 3
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
      ),
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
      onSelected: (selected) async {
        if (selected) {
          setState(() {
            _timeWindow = window;
            _selectedYear = year;
          });

          // Persist selection to PreferencesService (best-effort, do not block UI)
          try {
            final prefs = Provider.of<PreferencesService>(
              context,
              listen: false,
            );

            // Map TimeWindow to a stable integer index:
            // 0 -> last12Months, 1 -> allTime, 2 -> specificYear
            int index;
            switch (window) {
              case TimeWindow.last12Months:
                index = 0;
                break;
              case TimeWindow.allTime:
                index = 1;
                break;
              case TimeWindow.specificYear:
                index = 2;
                break;
            }

            await prefs.setAnalysisTimeWindowIndex(index);

            // Persist specific year if provided; if selecting a non-specific window,
            // clear any previously-stored specific year.
            if (year != null) {
              await prefs.setAnalysisSpecificYear(year);
            } else if (window != TimeWindow.specificYear) {
              await prefs.setAnalysisSpecificYear(null);
            }
          } catch (e) {
            _logger.warning(
              'Failed to persist analysis time window preference: $e',
            );
          }

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
    return OverviewPage(
      data: data,
      showCurrentMonthStats: _timeWindow == TimeWindow.last12Months,
    );
  }

  Widget _buildActivityBreakdownPage(AnalysisData data) {
    return ActivityBreakdownPage(
      data: data,
      selectedType: _activityBreakdownFilterType,
      onTypeChanged: (type) async {
        setState(() {
          _activityBreakdownFilterType = type;
        });
        // Persist selection to SharedPreferences via PreferencesService
        try {
          final prefs = Provider.of<PreferencesService>(context, listen: false);
          await prefs.setActivityFilter(type);
        } catch (e) {
          _logger.warning('Failed to persist activity filter: $e');
        }
      },
    );
  }

  Widget _buildPartnerBreakdownPage(AnalysisData data) {
    return PartnerBreakdownPage(data: data);
  }

  Widget _buildPeriodComparisonPage(AnalysisData data) {
    return PeriodComparisonPage(
      data: data,
      selectedPreset: _periodPreset,
      customFirstPeriod: _customFirstPeriod,
      customSecondPeriod: _customSecondPeriod,
      onPresetChanged: (preset) async {
        setState(() {
          _periodPreset = preset;
        });
        try {
          final prefs = Provider.of<PreferencesService>(context, listen: false);
          await prefs.setPeriodPreset(preset);
        } catch (e) {
          _logger.warning('Failed to persist period preset: $e');
        }
      },
      onCustomFirstPeriodChanged: (range) async {
        setState(() {
          _customFirstPeriod = range;
        });
        try {
          final prefs = Provider.of<PreferencesService>(context, listen: false);
          // Persist start/end components of the selected range (if any).
          await prefs.setCustomFirst(range?.start);
          await prefs.setCustomSecond(range?.end);
        } catch (e) {
          _logger.warning('Failed to persist custom first period: $e');
        }
      },
      onCustomSecondPeriodChanged: (range) async {
        setState(() {
          _customSecondPeriod = range;
        });
        try {
          final prefs = Provider.of<PreferencesService>(context, listen: false);
          // Persist any updates to the second custom period endpoint
          await prefs.setCustomSecond(range?.end);
        } catch (e) {
          _logger.warning('Failed to persist custom second period: $e');
        }
      },
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
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
