import 'package:indulge/data/models.dart';

/// Holds all computed analysis statistics
class AnalysisData {
  // Basic counts
  final int totalEvents;
  final int totalActivities;
  final int uniquePartners;
  final int riskyActivityCount;
  final int safeActivityCount;

  // Activity breakdown
  final Map<String, int> activityCounts;
  final Map<String, SexualActivityType> activityTypes;

  // Partner breakdown
  final Map<String, int> personCounts; // Total activities with each partner
  final Map<String, int> personEventCounts; // Total events with each partner
  final Map<String, List<SexualEvent>> personEvents; // Events for each partner
  final Map<String, Map<String, int>>
  personPropertyCounts; // Property counts per partner

  // Property breakdown
  final Map<String, int> propertyCountsTotal;
  final Map<String, SexualActivityTypeProperty> properties;

  // Time-based data
  final Map<String, int> dailyCounts; // yyyy-MM-dd -> count
  final Map<int, int> dayOfWeekCounts; // 1-7 (Monday-Sunday) -> count
  final Map<String, int> monthlyCounts; // yyyy-MM -> count

  // Streak data
  final int currentStreak;
  final int longestStreak;
  final int daysSinceLastRiskyActivity;
  final int daysSinceLastActivity;

  // Period comparisons
  final PeriodComparison thisWeekVsLastWeek;
  final PeriodComparison thisMonthVsLastMonth;

  // Averages (event-focused)
  final double averageEventsPerWeek;
  final double averageEventsPerMonth;
  final double averageActivitiesPerWeek;
  final double averageActivitiesPerMonth;
  final double averagePartnersPerEvent;
  final double averageActivitiesPerEvent;
  final double averagePropertiesPerEvent;

  // Time patterns
  final Map<int, double> averageEventsPerDayOfWeek; // 1-7 -> average events

  // Date range
  final DateTime? startDate;
  final DateTime? endDate;

  // Raw events for reference
  final List<SexualEvent> events;

  const AnalysisData({
    required this.totalEvents,
    required this.totalActivities,
    required this.uniquePartners,
    required this.riskyActivityCount,
    required this.safeActivityCount,
    required this.activityCounts,
    required this.activityTypes,
    required this.personCounts,
    required this.personEventCounts,
    required this.personEvents,
    required this.personPropertyCounts,
    required this.propertyCountsTotal,
    required this.properties,
    required this.dailyCounts,
    required this.dayOfWeekCounts,
    required this.monthlyCounts,
    required this.currentStreak,
    required this.longestStreak,
    required this.daysSinceLastRiskyActivity,
    required this.daysSinceLastActivity,
    required this.thisWeekVsLastWeek,
    required this.thisMonthVsLastMonth,
    required this.averageEventsPerWeek,
    required this.averageEventsPerMonth,
    required this.averageActivitiesPerWeek,
    required this.averageActivitiesPerMonth,
    required this.averagePartnersPerEvent,
    required this.averageActivitiesPerEvent,
    required this.averagePropertiesPerEvent,
    required this.averageEventsPerDayOfWeek,
    this.startDate,
    this.endDate,
    required this.events,
  });
}

/// Comparison between two time periods
class PeriodComparison {
  final int currentPeriodCount;
  final int previousPeriodCount;
  final double percentageChange;
  final bool isIncrease;

  const PeriodComparison({
    required this.currentPeriodCount,
    required this.previousPeriodCount,
    required this.percentageChange,
    required this.isIncrease,
  });

  static PeriodComparison calculate(int current, int previous) {
    if (previous == 0) {
      return PeriodComparison(
        currentPeriodCount: current,
        previousPeriodCount: previous,
        percentageChange: current > 0 ? 100.0 : 0.0,
        isIncrease: current > previous,
      );
    }

    final change = ((current - previous) / previous) * 100;
    return PeriodComparison(
      currentPeriodCount: current,
      previousPeriodCount: previous,
      percentageChange: change.abs(),
      isIncrease: current > previous,
    );
  }
}
