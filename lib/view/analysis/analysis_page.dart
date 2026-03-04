import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/data/models.dart';
import 'package:logging/logging.dart';
import 'models/overview_data.dart';
import 'utils/overview_calculator.dart';
import 'utils/activity_breakdown_calculator.dart';
import 'utils/partner_breakdown_calculator.dart';
import 'utils/period_comparison_calculator.dart';
import 'widgets/overview/overview_page.dart';
import 'widgets/activity_breakdown/activity_breakdown_page.dart';
import 'widgets/partner_breakdown/partner_breakdown_page.dart';
import 'widgets/period_comparison/period_comparison_page.dart';
import 'widgets/period_comparison/period_comparison_section.dart';
import 'widgets/sexual_health/sexual_health_page.dart';
import 'models/sexual_health_analysis_data.dart';
import 'models/period_comparison_data.dart';
import 'models/partner_breakdown_data.dart';
import 'utils/sexual_health_calculator.dart';
import 'package:indulge/services/preferences_service.dart';
import 'models/activity_breakdown_data.dart';
import 'models/analysis_event_type.dart';

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

  // ── Page order configuration ──────────────────────────────────────
  // Each entry is a page index (0–4): 0=Overview, 1=Activity, 2=Partner,
  // 3=Period Comparison, 4=Sexual Health.
  static const List<int> _defaultPageOrder = [0, 1, 2, 3, 4];
  List<int> _pageOrder = List.of(_defaultPageOrder);

  static const List<String> _pageLabels = [
    'Overview',
    'Activity',
    'Partners',
    'Comparison',
    'Health',
  ];
  static const List<IconData> _pageIcons = [
    Icons.dashboard,
    Icons.list_alt,
    Icons.people,
    Icons.compare_arrows,
    Icons.medical_services,
  ];

  // Cached EventStateStore so we don't access context in dispose().
  late EventStateStore _store;

  // Page-specific data
  OverviewData? _overviewData;
  ActivityBreakdownData? _activityBreakdownData;
  PartnerBreakdownData? _partnerBreakdownData;
  PeriodComparisonData? _periodComparisonData;
  SexualHealthAnalysisData? _sexualHealthData;

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
    // Cache the centralized EventStateStore and register the listener immediately.
    // We avoid reading context in dispose() by keeping this cached reference.
    _store = context.read<EventStateStore>();
    _store.addListener(_onStoreChange);

    // Defer loading preferences until the first frame, but keep listener registered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPreferences();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pageController.dispose();
    // Remove listener using the cached store reference. Avoid calling
    // context.read(...) here because the element may already be deactivated.
    _store.removeListener(_onStoreChange);
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

      // Load page order
      final savedOrder = prefs.getAnalysisPageOrder();
      // Validate: must be a permutation of [0..4]
      final isValid =
          savedOrder.length == _defaultPageOrder.length &&
          _defaultPageOrder.every((i) => savedOrder.contains(i));

      setState(() {
        // Apply loaded values if present
        _periodPreset = preset;
        _activityBreakdownFilterType = activityFilter;
        if (isValid) _pageOrder = savedOrder;

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

  void _onStoreChange() {
    final store = context.read<EventStateStore>();
    // Only recalculate if analysis is marked as dirty (events were saved/deleted)
    // Date changes don't trigger recalculation since they don't affect historical data
    // Note: don't clear dirty flag here - let _loadData do it after loading
    if (store.needsDataRefresh) {
      _isDirty = true;
      // Debounce: if multiple notifications arrive in quick succession
      // (e.g. bulk edits), only trigger one recalculation after they settle.
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDuration, _refresh);
    } else {
      // Not dirty - skip recalculation
      _isDirty = false;
    }
  }

  Future<void> _loadPageData({
    required SexualEventsProvider provider,
    required EventStateStore store,
    required DateTime? startDate,
    required DateTime? endDate,
    required List<SexualEvent> events,
    required List<Person> allPersons,
  }) async {
    // Skip recalculation if data hasn't changed and we already have results.
    if (!_isDirty && _overviewData != null) {
      _logger.info('Skipping recalculation — data is not dirty');
      return;
    }

    _logger.info('Loaded ${events.length} events');

    // Get all events for available years calculation - prefer the provided store snapshot
    final allEvents = store.state.currentEvents ?? events;
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

    // Get last STI test date from clinical events
    final clinicalProvider = context.read<ClinicalEventsProvider>();
    await clinicalProvider.ready;
    final lastStiTestDate = await clinicalProvider.getLastClinicalEventDate();

    // Calculate page-specific data in parallel
    final results = await Future.wait([
      OverviewCalculator.calculate(
        events: events,
        provider: provider,
        stateSnapshot: store.state,
        startDate: startDate,
        endDate: endDate,
        preFetchedPersons: allPersons,
        lastStiTestDate: lastStiTestDate,
      ),
      ActivityBreakdownCalculator.calculate(
        events: events,
        provider: provider,
        stateSnapshot: store.state,
        startDate: startDate,
        endDate: endDate,
        preFetchedPersons: allPersons,
      ),
      PartnerBreakdownCalculator.calculate(
        events: events,
        provider: provider,
        stateSnapshot: store.state,
        startDate: startDate,
        endDate: endDate,
        preFetchedPersons: allPersons,
      ),
      PeriodComparisonCalculator.calculate(
        events: events,
        provider: provider,
        stateSnapshot: store.state,
        startDate: startDate,
        endDate: endDate,
        preFetchedPersons: allPersons,
      ),
    ]);

    _overviewData = results[0] as OverviewData;
    _activityBreakdownData = results[1] as ActivityBreakdownData;
    _partnerBreakdownData = results[2] as PartnerBreakdownData;
    _periodComparisonData = results[3] as PeriodComparisonData;

    _logger.info(
      'Calculated data - ${_overviewData!.totalEvents} total events',
    );

    // Calculation succeeded — data is no longer dirty.
    _isDirty = false;
    store.clearDataDirty();
  }

  void _refresh() {
    _isDirty = true;
    _loadDataAsync(
      selectedTestIndex: _sexualHealthData?.selectedTestIndex ?? 0,
    );
  }

  Future<void> _loadDataAsync({int selectedTestIndex = 0}) async {
    // Set loading state first to prevent race conditions from build() calling this multiple times
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final store = context.read<EventStateStore>();
    final provider = context.read<SexualEventsProvider>();
    final clinicalProvider = context.read<ClinicalEventsProvider>();

    await provider.ready;
    await clinicalProvider.ready;

    final allEvents = await provider.getAllEvents();
    final allPersons = store.state.allPersons ?? await provider.getAllPersons();

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
        break;
      case TimeWindow.allTime:
        events = allEvents;
        startDate = null;
        endDate = null;
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
        } else {
          events = allEvents;
        }
    }

    // Update available years
    if (allEvents.isNotEmpty) {
      final years = allEvents.map((e) => e.date.year).toSet().toList()..sort();
      if (_availableYears.length != years.length ||
          !_availableYears.every((y) => years.contains(y))) {
        if (mounted) {
          setState(() {
            _availableYears = years;
          });
        }
      }
    }

    try {
      // Load page-specific data
      await _loadPageData(
        provider: provider,
        store: store,
        startDate: startDate,
        endDate: endDate,
        events: events,
        allPersons: allPersons,
      );

      // Also load sexual health data
      final sexualHealthData = await SexualHealthCalculator.calculate(
        allEvents: allEvents,
        clinicalProvider: clinicalProvider,
        stateSnapshot: store.state,
        activityCategories: store.state.sexualActivityCategories ?? {},
        selectedTestIndex: selectedTestIndex,
      );

      if (mounted) {
        setState(() {
          _sexualHealthData = sexualHealthData;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    if (_overviewData == null && !_isLoading) {
      _loadDataAsync();
    }

    final hasData =
        (_overviewData?.totalEvents ?? 0) > 0 ||
        (_sexualHealthData?.hasValidData ?? false);

    return SafeArea(
      child: Stack(
        children: [
          _overviewData == null && _sexualHealthData == null
              ? const Center(child: CircularProgressIndicator())
              : !hasData
              ? _buildEmptyState()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 4, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Analysis',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          _buildReorderButton(),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _currentPage >= 3
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
                            children: _pageOrder.map((pageIndex) {
                              switch (pageIndex) {
                                case 0:
                                  return _buildOverviewPage(_overviewData!);
                                case 1:
                                  return _buildActivityBreakdownPage(
                                    _activityBreakdownData!,
                                  );
                                case 2:
                                  return _buildPartnerBreakdownPage(
                                    _partnerBreakdownData!,
                                  );
                                case 3:
                                  return _buildPeriodComparisonPage(
                                    _periodComparisonData!,
                                  );
                                case 4:
                                  return _buildSexualHealthPage();
                                default:
                                  return const SizedBox.shrink();
                              }
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    _buildPageIndicator(),
                  ],
                ),
          if (_isLoading && _overviewData != null)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // ── Page reorder dialog ─────────────────────────────────────────────────

  Future<void> _showPageReorderDialog() async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => _PageReorderDialog(
        pageOrder: List.of(_pageOrder),
        pageLabels: _pageLabels,
        pageIcons: _pageIcons,
      ),
    );
    if (result != null) {
      setState(() {
        _pageOrder = result;
        // Jump to first page so the controller doesn't point to a stale page.
        _currentPage = 0;
        _pageController.jumpToPage(0);
      });
      try {
        final prefs = Provider.of<PreferencesService>(context, listen: false);
        await prefs.setAnalysisPageOrder(result);
      } catch (e) {
        _logger.warning('Failed to persist page order: $e');
      }
    }
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

  Widget _buildOverviewPage(OverviewData data) {
    return OverviewPage(
      data: data,
      showCurrentMonthStats: _timeWindow == TimeWindow.last12Months,
    );
  }

  Widget _buildActivityBreakdownPage(ActivityBreakdownData data) {
    return ActivityBreakdownPage(
      data: data,
      selectedType: _activityBreakdownFilterType,
      onTypeChanged: (type) async {
        setState(() {
          _activityBreakdownFilterType = type;
        });
        try {
          final prefs = Provider.of<PreferencesService>(context, listen: false);
          await prefs.setActivityFilter(type);
        } catch (e) {
          _logger.warning('Failed to persist activity filter: $e');
        }
      },
    );
  }

  Widget _buildPartnerBreakdownPage(PartnerBreakdownData data) {
    return PartnerBreakdownPage(data: data);
  }

  Widget _buildPeriodComparisonPage(PeriodComparisonData data) {
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
          await prefs.setCustomSecond(range?.end);
        } catch (e) {
          _logger.warning('Failed to persist custom second period: $e');
        }
      },
    );
  }

  Widget _buildSexualHealthPage() {
    if (_sexualHealthData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SexualHealthPage(
      data: _sexualHealthData!,
      onTestIndexChanged: (index) {
        _loadSinceLastTestData(testIndex: index);
      },
    );
  }

  Future<void> _loadSinceLastTestData({int testIndex = 0}) async {
    if (!mounted) return;

    final store = context.read<EventStateStore>();
    final clinicalProvider = context.read<ClinicalEventsProvider>();
    final sexualProvider = context.read<SexualEventsProvider>();
    await clinicalProvider.ready;
    await sexualProvider.ready;
    final allEvents = await sexualProvider.getAllEvents();
    final sexualHealthData = await SexualHealthCalculator.calculate(
      allEvents: allEvents,
      clinicalProvider: clinicalProvider,
      stateSnapshot: store.state,
      activityCategories: store.state.sexualActivityCategories ?? {},
      selectedTestIndex: testIndex,
    );

    if (mounted) {
      setState(() {
        _sexualHealthData = sexualHealthData;
      });
    }
  }

  Widget _buildPageIndicator() {
    final pageCount = _pageOrder.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          final isActive = _currentPage == index;
          final pageId = _pageOrder[index];
          final label = _pageLabels[pageId];
          final icon = _pageIcons[pageId];
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              clipBehavior: Clip.hardEdge,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 28,
              width: isActive ? 96 : 28,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showLabel = constraints.maxWidth > 80;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 13,
                        color: isActive
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      if (showLabel) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReorderButton() {
    return IconButton(
      icon: const Icon(Icons.reorder, size: 20),
      tooltip: 'Reorder pages',
      visualDensity: VisualDensity.compact,
      onPressed: _showPageReorderDialog,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

// ── Page reorder dialog ───────────────────────────────────────────────────────

class _PageReorderDialog extends StatefulWidget {
  final List<int> pageOrder;
  final List<String> pageLabels;
  final List<IconData> pageIcons;

  const _PageReorderDialog({
    required this.pageOrder,
    required this.pageLabels,
    required this.pageIcons,
  });

  @override
  State<_PageReorderDialog> createState() => _PageReorderDialogState();
}

class _PageReorderDialogState extends State<_PageReorderDialog> {
  late List<int> _order;

  @override
  void initState() {
    super.initState();
    _order = List.of(widget.pageOrder);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.reorder, size: 20),
          SizedBox(width: 8),
          Text('Reorder Pages'),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          itemCount: _order.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _order.removeAt(oldIndex);
              _order.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final pageId = _order[index];
            final label = widget.pageLabels[pageId];
            final icon = widget.pageIcons[pageId];
            return ListTile(
              key: ValueKey(pageId),
              leading: Icon(icon, color: scheme.primary),
              title: Text(label),
              trailing: const Icon(Icons.drag_handle),
              dense: true,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _order = List.of(
                List.generate(widget.pageLabels.length, (i) => i),
              );
            });
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_order),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
