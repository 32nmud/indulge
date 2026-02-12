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
class AveragesCalculator {
  /// Calculates per-week, per-month, per-event, and per-day-of-week averages.
  ///
  /// [sortedEvents] must be sorted by date ascending.
  /// [totalActivities] is the total number of activity instances across all events.
  /// [eventsThisYear] is the number of events within the selected time window.
  /// [dayOfWeekCounts] maps weekday (1=Mon..7=Sun) → total event count.
  /// [dayOfWeekCountsByType] maps event type → weekday → count.
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
    // Calculate calendar-span weeks for averaging.
    // This answers: "Over the period I've been tracking, what is my weekly average?"
    double totalWeeksSpan = 1.0;
    if (sortedEvents.isNotEmpty) {
      final firstDate = sortedEvents.first.date;
      final lastDate = sortedEvents.last.date;
      final daysDiff = lastDate.difference(firstDate).inDays + 1;
      totalWeeksSpan = (daysDiff / 7.0).clamp(1.0, double.infinity);
    }

    // Average day-of-week counts by type
    final averageDayOfWeekCountsByType =
        <AnalysisEventType, Map<int, double>>{};

    for (final type in AnalysisEventType.values) {
      averageDayOfWeekCountsByType[type] = {};
      for (int day = 1; day <= 7; day++) {
        int count;
        if (type == AnalysisEventType.total) {
          count = dayOfWeekCounts[day] ?? 0;
        } else {
          count = dayOfWeekCountsByType[type]?[day] ?? 0;
        }
        averageDayOfWeekCountsByType[type]![day] = count / totalWeeksSpan;
      }
    }

    // Calculate weekly/monthly counts scoped to this year
    final weeklyCountsThisYear = <String, int>{};
    final monthlyCountsThisYear = <String, int>{};

    for (final event in sortedEvents) {
      if (event.date.isAfter(thisYearStart.subtract(const Duration(days: 1)))) {
        final wKey = getWeekKey(event.date);
        weeklyCountsThisYear[wKey] = (weeklyCountsThisYear[wKey] ?? 0) + 1;

        final mKey = monthKey(event.date);
        monthlyCountsThisYear[mKey] = (monthlyCountsThisYear[mKey] ?? 0) + 1;
      }
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

    // Average events per day of week (based on this year)
    final averageEventsPerDayOfWeekMap = <int, double>{};
    for (int day = 1; day <= 7; day++) {
      final count = dayOfWeekCounts[day] ?? 0;
      averageEventsPerDayOfWeekMap[day] = count / distinctWeeksThisYear;
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
