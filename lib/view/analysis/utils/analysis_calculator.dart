import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import '../models/analysis_data.dart';
import 'calculators/event_aggregator.dart';
import 'calculators/averages_calculator.dart';
import 'calculators/streak_calculator.dart';
import 'calculators/comparison_calculator.dart';
import 'calculators/co_occurrence_calculator.dart';
import 'calculators/partner_count_converter.dart';
import 'calculators/person_cache.dart';

/// Orchestrates comprehensive analysis statistics from a list of events.
///
/// Delegates the heavy lifting to focused sub-calculators:
/// - [PersonCache] — single upfront DB fetch for all person lookups
/// - [EventAggregator] — single pass, raw count accumulation + period-scoped stats
/// - [AveragesCalculator] — per-week, per-month, per-event averages
/// - [StreakCalculator] — current and longest streaks
/// - [ComparisonCalculator] — week-over-week, month-over-month comparisons
/// - [CoOccurrenceCalculator] — category and activity co-occurrence pairs
/// - [PartnerCountConverter] — `Set<String>` → int count conversions
class AnalysisCalculator {
  /// Computes all analysis data from the given events.
  static Future<AnalysisData> calculate(
    List<SexualEvent> events,
    SexualEventsProvider provider, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final providerState = provider.state;
    if (events.isEmpty) {
      return _emptyAnalysisData(events, providerState, startDate, endDate);
    }

    // Sort events by date
    final sortedEvents = List<SexualEvent>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    // --- 0. Build person cache (single DB query) ---
    final personCache = await PersonCache.build(provider);

    // --- 1. Single pass: accumulate raw counts + period-scoped stats ---
    final agg = EventAggregator.aggregate(
      sortedEvents,
      personCache,
      providerState.sexualActivityCategories,
      providerState.sexualActivities,
      startDate: startDate,
    );

    // --- 2. Streaks ---
    final streaks = StreakCalculator.calculate(sortedEvents);

    // --- 3. Averages ---
    final now = DateTime.now();
    final thisYearStart = startDate ?? DateTime(now.year, now.month - 11, 1);

    final averages = AveragesCalculator.calculate(
      sortedEvents: sortedEvents,
      totalActivities: agg.totalActivities,
      eventsThisYear: agg.eventsThisYear,
      dayOfWeekCounts: agg.dayOfWeekCounts,
      dayOfWeekCountsByType: agg.dayOfWeekCountsByType,
      eventPartnerCounts: agg.eventPartnerCounts,
      eventPropertyCounts: agg.eventPropertyCounts,
      eventActivityCounts: agg.eventActivityCounts,
      thisYearStart: thisYearStart,
    );

    // --- 4. Period comparisons ---
    final thisWeekVsLastWeek = ComparisonCalculator.calculateWeekComparison(
      sortedEvents,
      now,
    );
    final thisMonthVsLastMonth = ComparisonCalculator.calculateMonthComparison(
      sortedEvents,
      now,
    );
    final daysSinceLastRiskyActivity =
        ComparisonCalculator.calculateDaysSinceLastRisky(
          sortedEvents,
          providerState,
        );

    // --- 5. Co-occurrence pairs ---
    final coOccurrence = CoOccurrenceCalculator.calculate(
      sortedEvents,
      activityCategories: agg.activityCategories,
      sexualActivities: agg.sexualActivities,
    );

    // --- 6. Convert partner count sets → int maps ---
    final sexualActivityPartnerCountsMap =
        PartnerCountConverter.convertPartnerCounts(
          agg.sexualActivityPartnerCounts,
        );
    final categoryPartnerCountsThisYearMap =
        PartnerCountConverter.convertPartnerCounts(
          agg.categoryPartnerCountsThisYear,
        );
    final sexualActivityPartnerCountsThisYearMap =
        PartnerCountConverter.convertPartnerCounts(
          agg.sexualActivityPartnerCountsThisYear,
        );
    final categoryActivityPartnerCountsThisYearMap =
        PartnerCountConverter.convertNestedPartnerCounts(
          agg.categoryActivityPartnerCountsThisYear,
        );

    // --- 7. Known partners ---
    final knownPartners = agg.personCounts.keys
        .where((id) => id != 'anonymous')
        .length;

    // --- 8. Days since last activity ---
    final lastEventDate = sortedEvents.last.date;
    final daysSinceLastActivity = now.difference(lastEventDate).inDays;

    // --- 9. Assemble final result ---
    return AnalysisData(
      totalEvents: events.length,
      totalActivities: agg.totalActivities,
      uniquePartners: agg.personCounts.length,
      riskyActivityCount: agg.riskyActivityCount,
      safeActivityCount: agg.safeActivityCount,
      eventsThisMonth: agg.eventsThisMonth,
      eventsThisYear: agg.eventsThisYear,
      uniquePartnersThisMonth: agg.uniquePartnersThisMonth,
      uniquePartnersThisYear: agg.uniquePartnersThisYear,
      knownPartners: knownPartners,
      anonymousPartnerInstances: agg.anonymousPartnerInstances,
      busiestDay: agg.busiestDay,
      busiestDayEventCount: agg.busiestDayEventCount,
      busiestEvent: agg.busiestEvent,
      busiestEventActivityCount: agg.busiestEventActivityCount,
      soloEventsThisYear: agg.soloEventsThisYear,
      coupleEventsThisYear: agg.coupleEventsThisYear,
      groupEventsThisYear: agg.groupEventsThisYear,
      soloEventsTotal: agg.soloEventsTotal,
      nonSoloEventsTotal: agg.nonSoloEventsTotal,
      soloActivityCounts: agg.soloActivityCounts,
      soloSexualActivityCounts: agg.soloSexualActivityCounts,
      soloActivityCountsThisYear: agg.soloActivityCountsThisYear,
      soloSexualActivityCountsThisYear: agg.soloSexualActivityCountsThisYear,
      activityCountsByType: agg.activityCountsByType,
      sexualActivityCountsByType: agg.sexualActivityCountsByType,
      monthlyCountsByType: agg.monthlyCountsByType,
      dayOfWeekCountsByType: agg.dayOfWeekCountsByType,
      averageDayOfWeekCountsByType: averages.averageDayOfWeekCountsByType,
      eventCountsByType: agg.eventCountsByType,
      eventsByType: agg.eventsByType,
      activityCounts: agg.activityCounts,
      activityCountsThisYear: agg.activityCountsThisYear,
      activityCategories: agg.activityCategories,
      longestStreak: streaks.longestStreak,
      currentStreak: streaks.currentStreak,
      personCounts: agg.personCounts,
      personEventCounts: agg.personEventCounts,
      personEvents: agg.personEvents,
      personPropertyCounts: agg.personPropertyCounts,
      sexualActivityCountsTotal: agg.sexualActivityCountsTotal,
      sexualActivities: agg.sexualActivities,
      sexualActivityPartnerCounts: sexualActivityPartnerCountsMap,
      categoryPartnerCountsThisYear: categoryPartnerCountsThisYearMap,
      sexualActivityPartnerCountsThisYear:
          sexualActivityPartnerCountsThisYearMap,
      categoryActivityPartnerCountsThisYear:
          categoryActivityPartnerCountsThisYearMap,
      dailyCounts: agg.dailyCounts,
      dayOfWeekCounts: agg.dayOfWeekCounts,
      monthlyCounts: agg.monthlyCounts,
      daysSinceLastRiskyActivity: daysSinceLastRiskyActivity,
      daysSinceLastActivity: daysSinceLastActivity,
      thisWeekVsLastWeek: thisWeekVsLastWeek,
      thisMonthVsLastMonth: thisMonthVsLastMonth,
      averageEventsPerWeek: averages.averageEventsPerWeek,
      averageEventsPerMonth: averages.averageEventsPerMonth,
      averageActivitiesPerWeek: averages.averageActivitiesPerWeek,
      averageActivitiesPerMonth: averages.averageActivitiesPerMonth,
      averagePartnersPerEvent: averages.averagePartnersPerEvent,
      averageActivitiesPerEvent: averages.averageActivitiesPerEvent,
      averageSexualActivitiesPerEvent: averages.averageSexualActivitiesPerEvent,
      averageEventsPerDayOfWeek: averages.averageEventsPerDayOfWeek,
      topActivityPairs: coOccurrence.topActivityPairs,
      topCategoryPairs: coOccurrence.topCategoryPairs,
      startDate: startDate,
      endDate: endDate,
      events: events,
    );
  }

  static AnalysisData _emptyAnalysisData(
    List<SexualEvent> events,
    EventState providerState,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return AnalysisData(
      totalEvents: 0,
      topActivityPairs: const [],
      topCategoryPairs: const [],
      totalActivities: 0,
      uniquePartners: 0,
      riskyActivityCount: 0,
      safeActivityCount: 0,
      eventsThisMonth: 0,
      eventsThisYear: 0,
      uniquePartnersThisMonth: 0,
      uniquePartnersThisYear: 0,
      knownPartners: 0,
      anonymousPartnerInstances: 0,
      busiestDay: null,
      busiestDayEventCount: 0,
      busiestEvent: null,
      busiestEventActivityCount: 0,
      soloEventsThisYear: 0,
      coupleEventsThisYear: 0,
      groupEventsThisYear: 0,
      soloEventsTotal: 0,
      nonSoloEventsTotal: 0,
      soloActivityCounts: {},
      soloSexualActivityCounts: {},
      soloActivityCountsThisYear: {},
      soloSexualActivityCountsThisYear: {},
      activityCountsByType: {},
      sexualActivityCountsByType: {},
      monthlyCountsByType: {},
      dayOfWeekCountsByType: {},
      averageDayOfWeekCountsByType: {},
      eventCountsByType: {},
      eventsByType: {},
      activityCounts: {},
      activityCountsThisYear: {},
      activityCategories: {},
      longestStreak: 0,
      currentStreak: 0,
      personCounts: {},
      personEventCounts: {},
      personEvents: {},
      personPropertyCounts: {},
      sexualActivityCountsTotal: {},
      sexualActivities: {},
      sexualActivityPartnerCounts: {},
      categoryPartnerCountsThisYear: {},
      sexualActivityPartnerCountsThisYear: {},
      categoryActivityPartnerCountsThisYear: {},
      dailyCounts: {},
      dayOfWeekCounts: {},
      monthlyCounts: {},
      daysSinceLastRiskyActivity: -1,
      daysSinceLastActivity: 0,
      thisWeekVsLastWeek: const PeriodComparison(
        currentPeriodCount: 0,
        previousPeriodCount: 0,
        percentageChange: 0,
        isIncrease: false,
      ),
      thisMonthVsLastMonth: const PeriodComparison(
        currentPeriodCount: 0,
        previousPeriodCount: 0,
        percentageChange: 0,
        isIncrease: false,
      ),
      averageEventsPerWeek: 0.0,
      averageEventsPerMonth: 0.0,
      averageActivitiesPerWeek: 0.0,
      averageActivitiesPerMonth: 0.0,
      averagePartnersPerEvent: 0.0,
      averageActivitiesPerEvent: 0.0,
      averageSexualActivitiesPerEvent: 0.0,
      averageEventsPerDayOfWeek: {},
      startDate: startDate,
      endDate: endDate,
      events: events,
    );
  }
}
