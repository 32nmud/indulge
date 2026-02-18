import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import '../models/overview_data.dart';
import 'person_cache.dart';
import 'calculator_utils/event_aggregator.dart';
import 'calculator_utils/streak_calculator.dart';
import 'calculator_utils/averages_calculator.dart';

/// Calculator specifically for the Overview page.
///
/// Computes statistics like total events, unique partners, streaks,
/// busiest day/event, monthly counts, and location data.
class OverviewCalculator {
  /// Computes overview statistics from the given events.
  static Future<OverviewData> calculate({
    required List<SexualEvent> events,
    required SexualEventsProvider provider,
    required EventState stateSnapshot,
    DateTime? startDate,
    DateTime? endDate,
    List<Person>? preFetchedPersons,
    DateTime? lastStiTestDate,
  }) async {
    if (events.isEmpty) {
      return OverviewData.empty(lastStiTestDate: lastStiTestDate);
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

    // Calculate streaks
    final streaks = StreakCalculator.calculate(sortedEvents);

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
      eventActivityCounts: agg.eventActivityCounts,
      thisYearStart: thisYearStart,
    );

    // Calculate known partners
    final knownPartners = agg.personCounts.keys
        .where((id) => id != 'anonymous')
        .length;

    // Days since last activity
    final lastEventDate = sortedEvents.last.date;
    final daysSinceLastActivity = now.difference(lastEventDate).inDays;

    // Build location list from events
    final locations = <Location>[];
    for (final event in sortedEvents) {
      final loc = event.location;
      if (loc != null) {
        locations.add(loc);
      }
    }

    // Build person map for UI
    final personMap = <String, Person>{};
    if (preFetchedPersons != null) {
      for (final p in preFetchedPersons) {
        personMap[p.id] = p;
      }
    }

    return OverviewData(
      totalEvents: events.length,
      totalActivities: agg.totalActivities,
      uniquePartners: agg.personCounts.length,
      eventsThisMonth: agg.eventsThisMonth,
      eventsThisYear: agg.eventsThisYear,
      uniquePartnersThisMonth: agg.uniquePartnersThisMonth,
      uniquePartnersThisYear: agg.uniquePartnersThisYear,
      knownPartners: knownPartners,
      anonymousPartnerInstances: agg.anonymousPartnerInstances,
      currentStreak: streaks.currentStreak,
      longestStreak: streaks.longestStreak,
      lastStiTestDate: lastStiTestDate,
      daysSinceLastActivity: daysSinceLastActivity,
      busiestDay: agg.busiestDay,
      busiestDayEventCount: agg.busiestDayEventCount,
      busiestEvent: agg.busiestEvent,
      busiestEventActivityCount: agg.busiestEventActivityCount,
      monthlyCounts: agg.monthlyCounts,
      dailyCounts: agg.dailyCounts,
      locations: locations,
      personMap: personMap,
      startDate: startDate,
      endDate: endDate,
      events: events,
      averageEventsPerDayOfWeek: averages.averageEventsPerDayOfWeek,
      averageDayOfWeekCountsByType: averages.averageDayOfWeekCountsByType,
      eventCountsByType: agg.eventCountsByType,
      monthlyCountsByType: agg.monthlyCountsByType,
    );
  }
}
