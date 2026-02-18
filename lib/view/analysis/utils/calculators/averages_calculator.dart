import 'package:indulge/data/models.dart';
import '../../models/analysis_data.dart';
import 'analysis_date_utils.dart';

/// Result of average computations.
class AveragesResult {
  final double averageEventsPerWeek;
  final double averageEventsPerMonth;
  final double averageActivitiesPerWeek;
  final double averageActivitiesPerMonth;
  final double averagePartnersPerEvent;
  final double averageActivitiesPerEvent;
  final double averageSexualActivitiesPerEvent;
  final Map<int, double> averageEventsPerDayOfWeek;
  final Map<AnalysisEventType, Map<int, double>> averageDayOfWeekCountsByType;

  const AveragesResult({
    required this.averageEventsPerWeek,
    required this.averageEventsPerMonth,
    required this.averageActivitiesPerWeek,
    required this.averageActivitiesPerMonth,
    required this.averagePartnersPerEvent,
    required this.averageActivitiesPerEvent,
    required this.averageSexualActivitiesPerEvent,
    required this.averageEventsPerDayOfWeek,
    required this.averageDayOfWeekCountsByType,
  });
}

/// Computes various averages from the raw aggregated event data.
///
/// NOTE: [sortedEvents] must be sorted by date ascending.
class AveragesCalculator {
  /// Calculates per-week, per-month, per-event, and per-day-of-week averages.
  ///
  /// [sortedEvents] must be sorted by date ascending.
  /// [totalActivities] is the total number of activity instances across all events.
  /// [eventsThisYear] is the number of events within the selected time window.
  /// [dayOfWeekCounts] maps weekday (1=Mon..7=Sun) → total event count (all-time).
  /// [dayOfWeekCountsByType] maps event type → weekday → count (all-time).
  /// [eventPartnerCounts] is the set of partner counts per event.
  /// [eventPropertyCounts] is the set of sexual activity instance counts per event.
  /// [eventActivityCounts] is the set of activity category counts per event.
  /// [thisYearStart] is the start of the selected time window.
  static AveragesResult calculate({
    required List<SexualEvent> sortedEvents,
    required int totalActivities,
    required int eventsThisYear,
    required Map<int, int> dayOfWeekCounts,
    required Map<AnalysisEventType, Map<int, int>> dayOfWeekCountsByType,
    required Set<int> eventPartnerCounts,
    required Set<int> eventPropertyCounts,
    required Set<int> eventActivityCounts,
    required DateTime thisYearStart,
  }) {
    // --- Determine windowStart/windowEnd BEFORE iterating events ---
    // windowStart defaults to the requested start (thisYearStart). If the first
    // available event is after that, we prefer starting at the first event date
    // so denominators reflect the period for which the user actually has data.
    DateTime windowStart = thisYearStart;
    DateTime windowEnd = thisYearStart; // will be adjusted below

    if (sortedEvents.isNotEmpty) {
      final firstEventDate = sortedEvents.first.date;
      final lastEventDate = sortedEvents.last.date;

      if (firstEventDate.isAfter(windowStart)) {
        windowStart = firstEventDate;
      }

      // windowEnd should be the latest event that lies within the requested
      // window (thisYearStart..∞). Iterate to find the last event >= thisYearStart.
      DateTime lastInWindow = windowStart;
      for (final ev in sortedEvents) {
        if (!ev.date.isBefore(thisYearStart)) {
          if (ev.date.isAfter(lastInWindow)) lastInWindow = ev.date;
        }
      }

      // If there were no events at/after thisYearStart, fall back to last event
      // that is before thisYearStart (so window still covers something).
      if (lastInWindow.isBefore(windowStart)) {
        // pick last available event overall
        windowEnd = lastEventDate;
      } else {
        windowEnd = lastInWindow;
      }

      // Safety: clamp windowEnd so it is not before windowStart
      if (windowEnd.isBefore(windowStart)) windowEnd = windowStart;
    }

    // --- Compute day-of-week counts scoped to the selected (possibly-shrunken) window ---
    final dayOfWeekCountsThisWindow = <int, int>{
      for (var i = 1; i <= 7; i++) i: 0,
    };
    final dayOfWeekCountsByTypeThisWindow = <AnalysisEventType, Map<int, int>>{
      for (var t in AnalysisEventType.values)
        t: {for (var i = 1; i <= 7; i++) i: 0},
    };

    for (final event in sortedEvents) {
      // include event if within [windowStart .. windowEnd]
      if (event.date.isBefore(windowStart) || event.date.isAfter(windowEnd)) {
        continue;
      }

      final dow = event.date.weekday;
      dayOfWeekCountsThisWindow[dow] =
          (dayOfWeekCountsThisWindow[dow] ?? 0) + 1;

      // Determine event type (approximation: we don't have PersonCache here).
      // Approximation is: if any participant id != 'me' then it's non-solo.
      final eventPartners = <String>{};
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          final pid = participant.participant.reference;
          if (pid != 'me') eventPartners.add(pid);
        }
      }

      final type = eventPartners.isEmpty
          ? AnalysisEventType.solo
          : (eventPartners.length == 1
                ? AnalysisEventType.couple
                : AnalysisEventType.group);

      dayOfWeekCountsByTypeThisWindow[type]![dow] =
          (dayOfWeekCountsByTypeThisWindow[type]![dow] ?? 0) + 1;
    }

    // --- Count calendar occurrences of each weekday inside the window ---
    final weekdayOccurrences = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
    if (!windowEnd.isBefore(windowStart)) {
      DateTime cursor = DateTime(
        windowStart.year,
        windowStart.month,
        windowStart.day,
      );
      final endDate = DateTime(windowEnd.year, windowEnd.month, windowEnd.day);
      while (!cursor.isAfter(endDate)) {
        weekdayOccurrences[cursor.weekday] =
            (weekdayOccurrences[cursor.weekday] ?? 0) + 1;
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    // --- Compute per-type averages using weekday occurrence denominators ---
    final averageDayOfWeekCountsByType =
        <AnalysisEventType, Map<int, double>>{};
    for (final t in AnalysisEventType.values) {
      averageDayOfWeekCountsByType[t] = {};
      for (int d = 1; d <= 7; d++) {
        final count = dayOfWeekCountsByTypeThisWindow[t]?[d] ?? 0;
        // Safe null-aware conversion: default to 1 occurrence when map value is absent.
        final denomDouble = (weekdayOccurrences[d] ?? 1).toDouble();
        averageDayOfWeekCountsByType[t]![d] = count / denomDouble;
      }
    }

    // --- Weekly / monthly counts scoped to the requested window (thisYearStart) ---
    final weeklyCountsThisYear = <String, int>{};
    final monthlyCountsThisYear = <String, int>{};

    for (final event in sortedEvents) {
      if (!event.date.isAfter(
        thisYearStart.subtract(const Duration(days: 1)),
      )) {
        continue;
      }
      final wKey = getWeekKey(event.date);
      weeklyCountsThisYear[wKey] = (weeklyCountsThisYear[wKey] ?? 0) + 1;

      final mKey = monthKey(event.date);
      monthlyCountsThisYear[mKey] = (monthlyCountsThisYear[mKey] ?? 0) + 1;
    }

    final distinctWeeksThisYear = weeklyCountsThisYear.length.clamp(
      1,
      double.infinity,
    );
    final distinctMonthsThisYear = monthlyCountsThisYear.length.clamp(
      1,
      double.infinity,
    );

    final averageActivitiesPerWeek = totalActivities / distinctWeeksThisYear;
    final averageActivitiesPerMonth = totalActivities / distinctMonthsThisYear;

    final averageEventsPerWeek = eventsThisYear / distinctWeeksThisYear;
    final averageEventsPerMonth = eventsThisYear / distinctMonthsThisYear;

    final averagePartnersPerEvent = eventPartnerCounts.isNotEmpty
        ? eventPartnerCounts.reduce((a, b) => a + b) / eventPartnerCounts.length
        : 0.0;

    final averageActivitiesPerEvent = eventActivityCounts.isNotEmpty
        ? eventActivityCounts.reduce((a, b) => a + b) /
              eventActivityCounts.length
        : 0.0;

    final averageSexualActivitiesPerEvent = eventPropertyCounts.isNotEmpty
        ? eventPropertyCounts.reduce((a, b) => a + b) /
              eventPropertyCounts.length
        : 0.0;

    // --- Average events per weekday (total) using calendar weekday occurrences ---
    final averageEventsPerDayOfWeekMap = <int, double>{};
    for (int d = 1; d <= 7; d++) {
      final count = dayOfWeekCountsThisWindow[d] ?? 0;
      // Use null-aware lookup and convert to double; fallback to 1 to avoid divide-by-zero.
      final denomDouble = (weekdayOccurrences[d] ?? 1).toDouble();
      averageEventsPerDayOfWeekMap[d] = count / denomDouble;
    }

    return AveragesResult(
      averageEventsPerWeek: averageEventsPerWeek,
      averageEventsPerMonth: averageEventsPerMonth,
      averageActivitiesPerWeek: averageActivitiesPerWeek,
      averageActivitiesPerMonth: averageActivitiesPerMonth,
      averagePartnersPerEvent: averagePartnersPerEvent,
      averageActivitiesPerEvent: averageActivitiesPerEvent,
      averageSexualActivitiesPerEvent: averageSexualActivitiesPerEvent,
      averageEventsPerDayOfWeek: averageEventsPerDayOfWeekMap,
      averageDayOfWeekCountsByType: averageDayOfWeekCountsByType,
    );
  }
}
