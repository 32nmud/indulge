import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'person_cache.dart';
import 'calculator_utils/event_aggregator.dart';
import 'calculator_utils/averages_calculator.dart';
import 'calculator_utils/co_occurrence_calculator.dart';
import '../models/activity_breakdown_data.dart';
import '../models/analysis_event_type.dart';

/// Calculator specifically for the Activity Breakdown page.
///
/// Computes statistics like activity counts, averages, co-occurrence pairs,
/// and breakdown by event type (solo, couple, group).
class ActivityBreakdownCalculator {
  /// Computes activity breakdown statistics from the given events.
  static Future<ActivityBreakdownData> calculate({
    required List<SexualEvent> events,
    required SexualEventsProvider provider,
    required EventState stateSnapshot,
    AnalysisEventType? filterType,
    DateTime? startDate,
    DateTime? endDate,
    List<Person>? preFetchedPersons,
  }) async {
    if (events.isEmpty) {
      return ActivityBreakdownData.empty();
    }

    // Sort events by date
    final sortedEvents = List<SexualEvent>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Build person cache
    final personCache = await PersonCache.build(
      provider,
      preFetched: preFetchedPersons ?? stateSnapshot.selectedEventParticipants,
    );

    // Aggregate events
    final agg = EventAggregator.aggregate(
      sortedEvents,
      personCache,
      stateSnapshot.sexualActivityCategories,
      stateSnapshot.sexualActivities,
      startDate: startDate,
    );

    // Calculate averages
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
      eventActionablePropertyCounts: agg.eventActionablePropertyCounts,
      eventGearPropertyCounts: agg.eventGearPropertyCounts,
      eventActivityCounts: agg.eventActivityCounts,
      thisYearStart: thisYearStart,
    );

    // Calculate co-occurrence pairs
    final coOccurrence = CoOccurrenceCalculator.calculate(
      sortedEvents,
      activityCategories: agg.activityCategories,
      sexualActivities: agg.sexualActivities,
    );

    // Build person map for UI
    final personMap = <String, Person>{};
    if (preFetchedPersons != null) {
      for (final p in preFetchedPersons) {
        personMap[p.id] = p;
      }
    }

    return ActivityBreakdownData(
      allCategoriesMap: stateSnapshot.sexualActivityCategories ?? {},
      totalActivities: agg.totalActivities,
      activityCounts: agg.activityCounts,
      activityCountsThisYear: agg.activityCountsThisYear,
      activityCountsByType: agg.activityCountsByType,
      sexualActivityCountsByType: agg.sexualActivityCountsByType,
      activityCategories: agg.activityCategories,
      monthlyCountsByType: agg.monthlyCountsByType,
      dayOfWeekCountsByType: agg.dayOfWeekCountsByType,
      averageDayOfWeekCountsByType: averages.averageDayOfWeekCountsByType,
      eventCountsByType: agg.eventCountsByType,
      eventsByType: agg.eventsByType,
      soloEventsThisYear: agg.soloEventsThisYear,
      coupleEventsThisYear: agg.coupleEventsThisYear,
      groupEventsThisYear: agg.groupEventsThisYear,
      soloActivityCountsThisYear: agg.soloActivityCountsThisYear,
      soloSexualActivityCountsThisYear: agg.soloSexualActivityCountsThisYear,
      averageEventsPerWeek: averages.averageEventsPerWeek,
      averageEventsPerMonth: averages.averageEventsPerMonth,
      averageActivitiesPerWeek: averages.averageActivitiesPerWeek,
      averageActivitiesPerMonth: averages.averageActivitiesPerMonth,
      averagePartnersPerEvent: averages.averagePartnersPerEvent,
      averageActivitiesPerEvent: averages.averageActivitiesPerEvent,
      averageSexualActivitiesPerEvent: averages.averageSexualActivitiesPerEvent,
      averageActionableActivitiesPerEvent:
          averages.averageActionableActivitiesPerEvent,
      averageGearPerEvent: averages.averageGearPerEvent,
      averageEventsPerDayOfWeek: averages.averageEventsPerDayOfWeek,
      topActivityPairs: coOccurrence.topActivityPairs,
      topCategoryPairs: coOccurrence.topCategoryPairs,
      sexualActivityCountsTotal: agg.sexualActivityCountsTotal,
      sexualActivities: agg.sexualActivities,
      personPropertyCounts: agg.personPropertyCounts,
      personMap: personMap,
      eventsThisYear: agg.eventsThisYear,
      monthlyCounts: agg.monthlyCounts,
      startDate: startDate,
      endDate: endDate,
      events: events,
      // Role breakdown data
      partnerRoleActivityCounts: agg.partnerRoleActivityCounts,
      userRoleActivityCounts: agg.userRoleActivityCounts,
      partnerRoleCounts: agg.partnerRoleCounts,
      userRoleCounts: agg.userRoleCounts,
    );
  }
}
