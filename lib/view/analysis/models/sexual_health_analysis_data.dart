import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

/// Maps category IDs to SexualActivityCategory objects.
typedef SexualActivityCategoryMap = Map<String, SexualActivityCategory>;

/// Maps activity IDs to SexualActivity objects.
typedef SexualActivityMap = Map<String, SexualActivity>;

/// Holds analysis statistics for a period between two STI tests.
///
/// This data is used to answer:
/// 1. If I tested positive for an STI on my most recent test, who should I contact?
/// 2. How risky have I been since my last test?
/// 3. How many partners have I had since my last test?
///
/// CDC recommends testing every 3 months for sexually active individuals.
class SexualHealthAnalysisData {
  /// List of all test dates available (most recent first).
  final List<DateTime> testDates;

  /// Index of the currently selected test date (0 = most recent).
  final int selectedTestIndex;

  /// Whether we're viewing the most recent test period.
  bool get isMostRecent => selectedTestIndex == 0;

  /// The start date for this period (the test date we're viewing).
  final DateTime periodStartDate;

  /// The end date for this period (the next test date, or now if viewing most recent).
  final DateTime periodEndDate;

  /// The most recent clinical event with test results.
  final ClinicalEvent? mostRecentClinicalEvent;

  /// List of positive test results from the most recent test.
  /// Empty if no tests were positive.
  final List<ClinicalTestResult> positiveTests;

  /// Sexual events that occurred in this period.
  final List<SexualEvent> eventsInPeriod;

  /// Count of unique partners in this period.
  final int uniquePartnersInPeriod;

  /// Count of total events in this period.
  final int eventCountInPeriod;

  /// Count of activities with STI risk in this period.
  /// Based on the stiRisk flag in SexualActivity.
  final int stiRiskCountInPeriod;

  /// Count of activities with general health/safety risk in this period.
  /// Based on the healthRisk flag in SexualActivity.
  final int healthRiskCountInPeriod;

  /// Count of total risky activities in this period (STI + health risk combined).
  /// Based on either stiRisk or healthRisk flag in SexualActivity.
  final int riskyActivityCountInPeriod;

  /// Count of safe activities in this period.
  final int safeActivityCountInPeriod;

  /// Total activities in this period.
  final int totalActivitiesInPeriod;

  /// Breakdown of category counts in this period.
  /// Maps category ID -> count of activities in that category.
  final Map<String, int> categoryCountsInPeriod;

  /// Breakdown of risky activities per category in this period.
  /// Maps category ID -> map of activity ID -> count (only risky activities).
  final Map<String, Map<String, int>> riskyActivityCountsByCategory;

  /// Breakdown of all activities per category in this period.
  /// Maps category ID -> map of activity ID -> count.
  final Map<String, Map<String, int>> categoryActivityCountsInPeriod;

  /// Map of category IDs to SexualActivityCategory objects for display.
  final SexualActivityCategoryMap activityCategories;

  /// Map of activity IDs to SexualActivity objects for display.
  final SexualActivityMap sexualActivities;

  /// Breakdown of activities in this period by category.
  final Map<String, int> activityCountsInPeriod;

  /// Breakdown of sexual activities in this period.
  final Map<String, int> sexualActivityCountsInPeriod;

  /// Partner counts: person ID -> event count in this period.
  final Map<String, int> partnerEventCountsInPeriod;

  /// Days in this period.
  final int daysInPeriod;

  /// Risk score (0-100) based on activities in this period.
  /// Higher score = higher risk.
  final int riskScore;

  /// Whether there is enough data to compute statistics.
  /// False if no test dates are available.
  final bool hasValidData;

  /// List of partners to notify if user tested positive.
  /// Includes partners from events in this period.
  final List<PartnerNotificationInfo> partnersToNotify;

  /// Map of person ID to Person objects for partners in this period.
  /// Used to display partner list with names/avatars.
  final Map<String, Person> partnerMap;

  /// Recommended date for next STI test (3 months from last test per CDC guidelines).
  /// Only set when viewing the most recent test period.
  final DateTime? nextRecommendedTestDate;

  const SexualHealthAnalysisData({
    required this.testDates,
    this.selectedTestIndex = 0,
    required this.periodStartDate,
    required this.periodEndDate,
    this.mostRecentClinicalEvent,
    this.positiveTests = const [],
    this.eventsInPeriod = const [],
    this.uniquePartnersInPeriod = 0,
    this.eventCountInPeriod = 0,
    this.stiRiskCountInPeriod = 0,
    this.healthRiskCountInPeriod = 0,
    this.riskyActivityCountInPeriod = 0,
    this.safeActivityCountInPeriod = 0,
    this.totalActivitiesInPeriod = 0,
    this.activityCountsInPeriod = const {},
    this.sexualActivityCountsInPeriod = const {},
    this.partnerEventCountsInPeriod = const {},
    this.categoryCountsInPeriod = const {},
    this.riskyActivityCountsByCategory = const {},
    this.categoryActivityCountsInPeriod = const {},

    /// Map of category IDs to SexualActivityCategory objects.
    this.activityCategories = const {},

    /// Map of activity IDs to SexualActivity objects.
    this.sexualActivities = const {},
    this.daysInPeriod = 0,
    this.riskScore = 0,
    this.hasValidData = false,
    this.partnersToNotify = const [],
    this.partnerMap = const {},
    this.nextRecommendedTestDate,
  });

  /// Creates empty data when no tests are available.
  factory SexualHealthAnalysisData.empty() {
    return SexualHealthAnalysisData(
      testDates: [],
      periodStartDate: DateTime.now(),
      periodEndDate: DateTime.now(),
    );
  }

  /// Returns true if the user tested positive on their most recent test.
  bool get testedPositive => positiveTests.isNotEmpty;

  /// Returns a human-readable risk level based on the risk score.
  String get riskLevel {
    if (riskScore < 20) return 'Low';
    if (riskScore < 50) return 'Moderate';
    if (riskScore < 75) return 'High';
    return 'Very High';
  }

  /// Returns a description of the risk level.
  String get riskDescription {
    if (!hasValidData) {
      return 'No test data available';
    }
    if (testDates.isEmpty) {
      return 'No STI tests recorded';
    }
    if (eventCountInPeriod == 0) {
      return 'No sexual activity in this period';
    }
    return 'Based on $eventCountInPeriod events with $uniquePartnersInPeriod '
        'partner${uniquePartnersInPeriod == 1 ? '' : 's'} between ${_formatDate(periodStartDate)} and ${_formatDate(periodEndDate)}';
  }

  /// Returns days until next recommended test (negative if overdue).
  int get daysUntilNextTest {
    if (nextRecommendedTestDate == null) return 0;
    return nextRecommendedTestDate!.difference(DateTime.now()).inDays;
  }

  /// Returns true if the user is overdue for testing.
  bool get isOverdueForTesting {
    return daysUntilNextTest < 0;
  }

  /// Returns the display label for the current test period.
  String get periodLabel {
    if (testDates.isEmpty) return 'No tests';
    if (selectedTestIndex == 0) return 'Most Recent Test';
    if (selectedTestIndex == 1) return '2nd Most Recent';
    return '${selectedTestIndex + 1}th Most Recent';
  }

  /// Date range for this period.
  DateTimeRange get periodRange =>
      DateTimeRange(start: periodStartDate, end: periodEndDate);

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Information about a partner that should be notified if the user tested positive.
class PartnerNotificationInfo {
  /// The partner's ID (or 'anonymous' for anonymous partners).
  final String partnerId;

  /// The partner's name if known, null for anonymous.
  final String? partnerName;

  /// Whether this is an anonymous partner.
  final bool isAnonymous;

  /// Number of events with this partner in this period.
  final int eventCount;

  /// Date of the most recent event with this partner in this period.
  final DateTime? lastEventDate;

  /// Activity types engaged in with this partner.
  final List<String> activityTypes;

  const PartnerNotificationInfo({
    required this.partnerId,
    this.partnerName,
    required this.isAnonymous,
    required this.eventCount,
    this.lastEventDate,
    this.activityTypes = const [],
  });

  /// Returns a display name for the partner.
  String get displayName {
    if (isAnonymous) {
      return 'Anonymous Partner';
    }
    return partnerName ?? 'Unknown Partner';
  }
}
