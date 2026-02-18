import 'package:indulge/data/models.dart';
import 'analysis_event_type.dart';
import 'co_occurance_pair.dart';

class ActivityBreakdownData {
  final int totalActivities;
  final Map<String, int> activityCounts;
  final Map<String, int> activityCountsThisYear;
  final Map<AnalysisEventType, Map<String, int>> activityCountsByType;
  final Map<AnalysisEventType, Map<String, int>> sexualActivityCountsByType;
  final Map<String, SexualActivityCategory> activityCategories;
  final Map<AnalysisEventType, Map<String, int>> monthlyCountsByType;
  final Map<AnalysisEventType, Map<int, int>> dayOfWeekCountsByType;
  final Map<AnalysisEventType, Map<int, double>> averageDayOfWeekCountsByType;
  final Map<AnalysisEventType, int> eventCountsByType;
  final Map<AnalysisEventType, List<SexualEvent>> eventsByType;
  final int soloEventsThisYear;
  final int coupleEventsThisYear;
  final int groupEventsThisYear;
  final Map<String, int> soloActivityCountsThisYear;
  final Map<String, int> soloSexualActivityCountsThisYear;
  final double averageEventsPerWeek;
  final double averageEventsPerMonth;
  final double averageActivitiesPerWeek;
  final double averageActivitiesPerMonth;
  final double averagePartnersPerEvent;
  final double averageActivitiesPerEvent;
  final double averageSexualActivitiesPerEvent;
  final Map<int, double> averageEventsPerDayOfWeek;
  final List<CoOccurrencePair> topActivityPairs;
  final List<CoOccurrencePair> topCategoryPairs;
  final Map<String, int> sexualActivityCountsTotal;
  final Map<String, SexualActivity> sexualActivities;
  final Map<String, Map<String, int>> personPropertyCounts;
  final int eventsThisYear;
  final Map<String, int> monthlyCounts;
  final Map<String, Person> personMap;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<SexualEvent> events;

  const ActivityBreakdownData({
    required this.totalActivities,
    required this.activityCounts,
    required this.activityCountsThisYear,
    required this.activityCountsByType,
    required this.sexualActivityCountsByType,
    required this.activityCategories,
    required this.monthlyCountsByType,
    required this.dayOfWeekCountsByType,
    required this.averageDayOfWeekCountsByType,
    required this.eventCountsByType,
    required this.eventsByType,
    required this.soloEventsThisYear,
    required this.coupleEventsThisYear,
    required this.groupEventsThisYear,
    required this.soloActivityCountsThisYear,
    required this.soloSexualActivityCountsThisYear,
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
    required this.sexualActivityCountsTotal,
    required this.sexualActivities,
    required this.personPropertyCounts,
    required this.personMap,
    required this.eventsThisYear,
    required this.monthlyCounts,
    this.startDate,
    this.endDate,
    required this.events,
  });

  factory ActivityBreakdownData.empty() {
    return const ActivityBreakdownData(
      totalActivities: 0,
      activityCounts: {},
      activityCountsThisYear: {},
      activityCountsByType: {},
      sexualActivityCountsByType: {},
      activityCategories: {},
      monthlyCountsByType: {},
      dayOfWeekCountsByType: {},
      averageDayOfWeekCountsByType: {},
      eventCountsByType: {},
      eventsByType: {},
      soloEventsThisYear: 0,
      coupleEventsThisYear: 0,
      groupEventsThisYear: 0,
      soloActivityCountsThisYear: {},
      soloSexualActivityCountsThisYear: {},
      averageEventsPerWeek: 0.0,
      averageEventsPerMonth: 0.0,
      averageActivitiesPerWeek: 0.0,
      averageActivitiesPerMonth: 0.0,
      averagePartnersPerEvent: 0.0,
      averageActivitiesPerEvent: 0.0,
      averageSexualActivitiesPerEvent: 0.0,
      averageEventsPerDayOfWeek: {},
      topActivityPairs: [],
      topCategoryPairs: [],
      sexualActivityCountsTotal: {},
      sexualActivities: {},
      personPropertyCounts: {},
      monthlyCounts: {},
      personMap: {},
      eventsThisYear: 0,
      events: [],
    );
  }
}
