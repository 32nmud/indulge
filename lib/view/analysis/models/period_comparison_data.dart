import 'period_comparison.dart';
import 'analysis_event_type.dart';
import 'package:indulge/data/models.dart';

class PeriodComparisonData {
  final PeriodComparison thisWeekVsLastWeek;
  final PeriodComparison thisMonthVsLastMonth;
  final int daysSinceLastRiskyActivity;
  final int eventsThisMonth;
  final int eventsThisYear;
  final int uniquePartnersThisMonth;
  final int uniquePartnersThisYear;
  final Map<String, int> dailyCounts;
  final Map<String, int> monthlyCounts;
  final Map<int, int> dayOfWeekCounts;
  final Map<String, int> personCounts;
  final Map<AnalysisEventType, List<SexualEvent>> eventsByType;
  final Map<String, Person> personMap;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<SexualEvent> events;

  const PeriodComparisonData({
    required this.thisWeekVsLastWeek,
    required this.thisMonthVsLastMonth,
    required this.daysSinceLastRiskyActivity,
    required this.eventsThisMonth,
    required this.eventsThisYear,
    required this.uniquePartnersThisMonth,
    required this.uniquePartnersThisYear,
    required this.dailyCounts,
    required this.monthlyCounts,
    required this.dayOfWeekCounts,
    required this.personCounts,
    required this.eventsByType,
    required this.personMap,
    this.startDate,
    this.endDate,
    required this.events,
  });

  factory PeriodComparisonData.empty() {
    return const PeriodComparisonData(
      thisWeekVsLastWeek: PeriodComparison(
        currentPeriodCount: 0,
        previousPeriodCount: 0,
        percentageChange: 0,
        isIncrease: false,
      ),
      thisMonthVsLastMonth: PeriodComparison(
        currentPeriodCount: 0,
        previousPeriodCount: 0,
        percentageChange: 0,
        isIncrease: false,
      ),
      daysSinceLastRiskyActivity: -1,
      eventsThisMonth: 0,
      eventsThisYear: 0,
      uniquePartnersThisMonth: 0,
      uniquePartnersThisYear: 0,
      dailyCounts: {},
      monthlyCounts: {},
      dayOfWeekCounts: {},
      personCounts: {},
      eventsByType: {},
      personMap: {},
      events: [],
    );
  }
}
