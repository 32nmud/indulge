import 'package:indulge/data/models.dart';

/// Holds all computed analysis statistics
class AnalysisData {
  // Basic counts
  final int totalEvents;
  final int totalActivities;
  final int uniquePartners;
  final int riskyActivityCount;
  final int safeActivityCount;

  // Time period specific counts
  final int eventsThisMonth;
  final int eventsThisYear; // Last 12 months
  final int uniquePartnersThisMonth;
  final int uniquePartnersThisYear; // Last 12 months

  // Event type breakdown (last 12 months)
  final int soloEventsThisYear;
  final int coupleEventsThisYear;
  final int groupEventsThisYear;

  // Partner ratio
  final int knownPartners;
  final int anonymousPartnerInstances;

  // Busiest stats
  final DateTime? busiestDay;
  final int busiestDayEventCount;
  final SexualEvent? busiestEvent;
  final int busiestEventActivityCount;

  // Activity breakdown
  final Map<String, int> activityCounts; // All time
  final Map<String, int> activityCountsThisYear; // Last 12 months
  final Map<String, SexualActivityType> activityTypes;

  // Streak data
  final int currentStreak;
  final int longestStreak;

  // Partner breakdown
  final Map<String, int> personCounts; // Total activities with each partner
  final Map<String, int> personEventCounts; // Total events with each partner
  final Map<String, List<SexualEvent>> personEvents; // Events for each partner
  final Map<String, Map<String, int>>
  personPropertyCounts; // Property counts per partner

  // Property breakdown
  final Map<String, int> propertyCountsTotal;
  final Map<String, SexualActivityTypeProperty> properties;

  // Property-partner counts (how many unique partners used each property)
  final Map<String, int> propertyPartnerCounts;

  // Last 12 months activity/property partner counts
  final Map<String, int>
  activityPartnerCountsThisYear; // activity -> unique partner count
  final Map<String, int>
  propertyPartnerCountsThisYear; // property -> unique partner count
  final Map<String, Map<String, int>>
  activityPropertyPartnerCountsThisYear; // activity -> property -> unique partner count

  // Time-based data
  final Map<String, int> dailyCounts; // yyyy-MM-dd -> count
  final Map<int, int> dayOfWeekCounts; // 1-7 (Monday-Sunday) -> count
  final Map<String, int> monthlyCounts; // yyyy-MM -> count

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
    required this.eventsThisMonth,
    required this.eventsThisYear,
    required this.uniquePartnersThisMonth,
    required this.uniquePartnersThisYear,
    required this.soloEventsThisYear,
    required this.coupleEventsThisYear,
    required this.groupEventsThisYear,
    required this.knownPartners,
    required this.anonymousPartnerInstances,
    required this.busiestDay,
    required this.busiestDayEventCount,
    required this.busiestEvent,
    required this.busiestEventActivityCount,
    required this.activityCounts,
    required this.activityCountsThisYear,
    required this.activityTypes,
    required this.longestStreak,
    required this.currentStreak,
    required this.personCounts,
    required this.personEventCounts,
    required this.personEvents,
    required this.personPropertyCounts,
    required this.propertyCountsTotal,
    required this.properties,
    required this.propertyPartnerCounts,
    required this.activityPartnerCountsThisYear,
    required this.propertyPartnerCountsThisYear,
    required this.activityPropertyPartnerCountsThisYear,
    required this.dailyCounts,
    required this.dayOfWeekCounts,
    required this.monthlyCounts,
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
