import 'package:indulge/data/models.dart';

enum AnalysisEventType { total, solo, couple, group }

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

  // Solo Analysis
  @Deprecated('Use breakdown logic instead')
  final int soloEventsTotal;
  @Deprecated('Use breakdown logic instead')
  final int nonSoloEventsTotal;
  @Deprecated('Use activityCountsByType[AnalysisEventType.solo] instead')
  final Map<String, int> soloActivityCounts;
  @Deprecated('Use sexualActivityCountsByType[AnalysisEventType.solo] instead')
  final Map<String, int> soloSexualActivityCounts;
  @Deprecated('Use breakdown logic instead')
  final Map<String, int> soloActivityCountsThisYear;
  @Deprecated('Use breakdown logic instead')
  final Map<String, int> soloSexualActivityCountsThisYear;

  // Breakdown by event type
  final Map<AnalysisEventType, Map<String, int>> activityCountsByType;
  final Map<AnalysisEventType, Map<String, int>> sexualActivityCountsByType;
  final Map<AnalysisEventType, Map<String, int>> monthlyCountsByType;
  final Map<AnalysisEventType, Map<int, int>> dayOfWeekCountsByType;
  final Map<AnalysisEventType, Map<int, double>> averageDayOfWeekCountsByType;
  final Map<AnalysisEventType, int> eventCountsByType;
  final Map<AnalysisEventType, List<SexualEvent>> eventsByType;

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
  final Map<String, SexualActivityCategory> activityCategories;

  // Streak data
  final int currentStreak;
  final int longestStreak;

  // Partner breakdown
  final Map<String, int> personCounts; // Total activities with each partner
  final Map<String, int> personEventCounts; // Total events with each partner
  final Map<String, List<SexualEvent>> personEvents; // Events for each partner
  // Optional map of person id -> Person objects for quick lookup (may be empty)
  final Map<String, Person> personMap;
  final Map<String, Map<String, int>>
  personPropertyCounts; // Property counts per partner

  // Sexual activity breakdown
  final Map<String, int> sexualActivityCountsTotal;
  final Map<String, SexualActivity> sexualActivities;

  // Sexual activity-partner counts (how many unique partners used each activity)
  final Map<String, int> sexualActivityPartnerCounts;

  // Last 12 months category/activity partner counts
  final Map<String, int>
  categoryPartnerCountsThisYear; // category -> unique partner count
  final Map<String, int>
  sexualActivityPartnerCountsThisYear; // sexual activity -> unique partner count
  final Map<String, Map<String, int>>
  categoryActivityPartnerCountsThisYear; // category -> sexual activity -> unique partner count

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
  final double averageSexualActivitiesPerEvent;

  // Time patterns
  final Map<int, double> averageEventsPerDayOfWeek; // 1-7 -> average events

  // Co-occurrence
  final List<CoOccurrencePair> topActivityPairs;
  final List<CoOccurrencePair> topCategoryPairs;

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
    required this.soloEventsTotal,
    required this.nonSoloEventsTotal,
    required this.soloActivityCounts,
    required this.soloSexualActivityCounts,
    required this.soloActivityCountsThisYear,
    required this.soloSexualActivityCountsThisYear,
    this.activityCountsByType = const {},
    this.sexualActivityCountsByType = const {},
    this.monthlyCountsByType = const {},
    this.dayOfWeekCountsByType = const {},
    this.averageDayOfWeekCountsByType = const {},
    this.eventCountsByType = const {},
    this.eventsByType = const {},
    required this.knownPartners,
    required this.anonymousPartnerInstances,
    required this.busiestDay,
    required this.busiestDayEventCount,
    required this.busiestEvent,
    required this.busiestEventActivityCount,
    required this.activityCounts,
    required this.activityCountsThisYear,
    required this.activityCategories,
    required this.longestStreak,
    required this.currentStreak,
    required this.personCounts,
    required this.personEventCounts,
    required this.personEvents,
    this.personMap = const {},
    required this.personPropertyCounts,
    required this.sexualActivityCountsTotal,
    required this.sexualActivities,
    required this.sexualActivityPartnerCounts,
    required this.categoryPartnerCountsThisYear,
    required this.sexualActivityPartnerCountsThisYear,
    required this.categoryActivityPartnerCountsThisYear,
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
    required this.averageSexualActivitiesPerEvent,
    required this.averageEventsPerDayOfWeek,
    required this.topActivityPairs,
    required this.topCategoryPairs,
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

class CoOccurrencePair {
  final String id1;
  final String id2;
  final String name1;
  final String name2;
  final int count;

  const CoOccurrencePair({
    required this.id1,
    required this.id2,
    required this.name1,
    required this.name2,
    required this.count,
  });
}
