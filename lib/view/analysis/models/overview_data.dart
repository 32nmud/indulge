import 'package:indulge/data/models.dart';
import 'analysis_event_type.dart';

/// Holds computed statistics for the Overview page.
class OverviewData {
  final int totalEvents;
  final int totalActivities;
  final int uniquePartners;
  final int eventsThisMonth;
  final int eventsThisYear;
  final int uniquePartnersThisMonth;
  final int uniquePartnersThisYear;
  final int knownPartners;
  final int anonymousPartnerInstances;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStiTestDate;
  final int daysSinceLastActivity;
  final DateTime? busiestDay;
  final int busiestDayEventCount;
  final SexualEvent? busiestEvent;
  final int busiestEventActivityCount;
  final Map<String, int> monthlyCounts;
  final Map<String, int> dailyCounts;
  final List<Location> locations;
  final Map<String, Person> personMap;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<SexualEvent> events;

  // Averages for overview
  final Map<int, double> averageEventsPerDayOfWeek;
  final Map<AnalysisEventType, Map<int, double>> averageDayOfWeekCountsByType;

  // Event type counts
  final Map<AnalysisEventType, int> eventCountsByType;
  final Map<AnalysisEventType, Map<String, int>> monthlyCountsByType;

  const OverviewData({
    required this.totalEvents,
    required this.totalActivities,
    required this.uniquePartners,
    required this.eventsThisMonth,
    required this.eventsThisYear,
    required this.uniquePartnersThisMonth,
    required this.uniquePartnersThisYear,
    required this.knownPartners,
    required this.anonymousPartnerInstances,
    required this.currentStreak,
    required this.longestStreak,
    this.lastStiTestDate,
    required this.daysSinceLastActivity,
    required this.busiestDay,
    required this.busiestDayEventCount,
    required this.busiestEvent,
    required this.busiestEventActivityCount,
    required this.monthlyCounts,
    required this.dailyCounts,
    required this.locations,
    required this.personMap,
    this.startDate,
    this.endDate,
    required this.events,
    this.averageEventsPerDayOfWeek = const {},
    this.averageDayOfWeekCountsByType = const {},
    this.eventCountsByType = const {},
    this.monthlyCountsByType = const {},
  });

  factory OverviewData.empty({DateTime? lastStiTestDate}) {
    return OverviewData(
      totalEvents: 0,
      totalActivities: 0,
      uniquePartners: 0,
      eventsThisMonth: 0,
      eventsThisYear: 0,
      uniquePartnersThisMonth: 0,
      uniquePartnersThisYear: 0,
      knownPartners: 0,
      anonymousPartnerInstances: 0,
      currentStreak: 0,
      longestStreak: 0,
      lastStiTestDate: lastStiTestDate,
      daysSinceLastActivity: 0,
      busiestDay: null,
      busiestDayEventCount: 0,
      busiestEvent: null,
      busiestEventActivityCount: 0,
      monthlyCounts: {},
      dailyCounts: {},
      locations: [],
      personMap: {},
      events: [],
      averageEventsPerDayOfWeek: {},
      averageDayOfWeekCountsByType: {},
      eventCountsByType: {},
      monthlyCountsByType: {},
    );
  }
}
