import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'person_cache.dart';
import 'calculator_utils/event_aggregator.dart';
import 'calculator_utils/comparison_calculator.dart';
import '../models/period_comparison_data.dart';

/// Calculator specifically for the Period Comparison page.
///
/// Computes statistics like week-over-week comparison, month-over-month
/// comparison, and days since last risky activity.
class PeriodComparisonCalculator {
  /// Computes period comparison statistics from the given events.
  static Future<PeriodComparisonData> calculate({
    required List<SexualEvent> events,
    required SexualEventsProvider provider,
    required EventState stateSnapshot,
    DateTime? startDate,
    DateTime? endDate,
    List<Person>? preFetchedPersons,
  }) async {
    if (events.isEmpty) {
      return PeriodComparisonData.empty();
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

    // Calculate period comparisons
    final now = DateTime.now();

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
          stateSnapshot,
        );

    // Build person map for UI
    final personMap = <String, Person>{};
    if (preFetchedPersons != null) {
      for (final p in preFetchedPersons) {
        personMap[p.id] = p;
      }
    }

    return PeriodComparisonData(
      allCategoriesMap: stateSnapshot.sexualActivityCategories ?? {},
      sexualActivities: agg.sexualActivities,
      thisWeekVsLastWeek: thisWeekVsLastWeek,
      thisMonthVsLastMonth: thisMonthVsLastMonth,
      daysSinceLastRiskyActivity: daysSinceLastRiskyActivity,
      eventsThisMonth: agg.eventsThisMonth,
      eventsThisYear: agg.eventsThisYear,
      uniquePartnersThisMonth: agg.uniquePartnersThisMonth,
      uniquePartnersThisYear: agg.uniquePartnersThisYear,
      dailyCounts: agg.dailyCounts,
      monthlyCounts: agg.monthlyCounts,
      dayOfWeekCounts: agg.dayOfWeekCounts,
      personCounts: agg.personCounts,
      eventsByType: agg.eventsByType,
      personMap: personMap,
      startDate: startDate,
      endDate: endDate,
      events: events,
    );
  }
}
