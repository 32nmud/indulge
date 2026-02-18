import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import '../models/sexual_health_analysis_data.dart';

/// Calculator for statistics between two STI test dates.
class SexualHealthCalculator {
  /// Computes statistics for a period between two tests.
  ///
  /// [selectedTestIndex] - which test to use as the start of the period
  /// (0 = most recent, 1 = second most recent, etc.)
  static Future<SexualHealthAnalysisData> calculate({
    required List<SexualEvent> allEvents,
    required ClinicalEventsProvider clinicalProvider,
    required EventState stateSnapshot,
    required Map<String, SexualActivity> sexualActivities,
    required Map<String, SexualActivityCategory> activityCategories,
    int selectedTestIndex = 0,
  }) async {
    // Get all test dates
    final testDates = await clinicalProvider.getRecentClinicalEventDates(10);

    if (testDates.isEmpty) {
      return SexualHealthAnalysisData.empty();
    }

    // Ensure selected index is valid
    if (selectedTestIndex >= testDates.length) {
      selectedTestIndex = 0;
    }

    // Determine period boundaries
    final periodStart = testDates[selectedTestIndex];
    final DateTime periodEnd;
    if (selectedTestIndex + 1 < testDates.length) {
      // Use the next test date as end
      periodEnd = testDates[selectedTestIndex + 1];
    } else {
      // Use now for the most recent test period
      periodEnd = DateTime.now();
    }

    // Get clinical event for this test date to check results
    ClinicalEvent? clinicalEvent;
    final positiveTests = <ClinicalTestResult>[];

    final eventsForDate = await clinicalProvider.getEventsForDate(periodStart);
    if (eventsForDate.isNotEmpty) {
      clinicalEvent = eventsForDate.first;
      for (final test in clinicalEvent.tests) {
        if (test.result == TestResult.positive) {
          positiveTests.add(test);
        }
      }
    }

    // Filter events in this period
    // For most recent (periodEnd = now): events after the test date
    // For historical: events between the two test dates
    final eventsInPeriod = allEvents.where((e) {
      if (selectedTestIndex == 0) {
        // Most recent: events after the test date (including same day)
        return !e.date.isBefore(periodStart);
      } else {
        // Historical: events between two test dates
        return e.date.isAfter(periodStart) &&
            (e.date.isBefore(periodEnd) || e.date.isAtSameMomentAs(periodEnd));
      }
    }).toList();

    // Calculate unique partners in period
    final uniquePartnersInPeriod = _getUniquePartners(
      eventsInPeriod,
      stateSnapshot,
    );

    // Calculate activity counts, category counts, and risky/safe
    final activityCounts = <String, int>{};
    final sexualActivityCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    final categoryActivityCounts = <String, Map<String, int>>{};
    final riskyActivityCountsByCategory = <String, Map<String, int>>{};
    int riskyCount = 0;
    int safeCount = 0;
    int totalActivities = 0;

    for (final event in eventsInPeriod) {
      for (final activity in event.activities) {
        totalActivities++;
        final categoryId = activity.category.reference;
        activityCounts[categoryId] = (activityCounts[categoryId] ?? 0) + 1;

        // Count by category
        categoryCounts[categoryId] = (categoryCounts[categoryId] ?? 0) + 1;

        // Track activity counts per category
        categoryActivityCounts.putIfAbsent(categoryId, () => {});
        for (final participant in activity.participants) {
          for (final actCount in participant.activityCounts) {
            final actId = actCount.activityReference.reference;
            categoryActivityCounts[categoryId]![actId] =
                (categoryActivityCounts[categoryId]![actId] ?? 0) +
                actCount.count;

            // Track risky activities by category
            final act = sexualActivities[actId];
            if (act != null && act.isRisky) {
              riskyActivityCountsByCategory.putIfAbsent(categoryId, () => {});
              riskyActivityCountsByCategory[categoryId]![actId] =
                  (riskyActivityCountsByCategory[categoryId]![actId] ?? 0) +
                  actCount.count;
            }
          }
        }

        final sexualActivity = sexualActivities[categoryId];
        if (sexualActivity != null) {
          sexualActivityCounts[sexualActivity.name] =
              (sexualActivityCounts[sexualActivity.name] ?? 0) + 1;
        }

        // Determine if this activity has any risky sexual activities
        bool hasRiskyInActivity = false;
        for (final participant in activity.participants) {
          for (final activityCount in participant.activityCounts) {
            final actId = activityCount.activityReference.reference;
            final act = sexualActivities[actId];
            if (act != null && act.isRisky) {
              hasRiskyInActivity = true;
              break;
            }
          }
          if (hasRiskyInActivity) break;
        }

        if (hasRiskyInActivity) {
          riskyCount++;
        } else {
          safeCount++;
        }
      }
    }

    // Calculate partner event counts - count events (not activities) per partner
    final partnerEventCounts = <String, int>{};

    for (final event in eventsInPeriod) {
      final eventPartnerIds = <String>{};
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          final partnerId = participant.participant.reference;
          if (partnerId.isNotEmpty && partnerId != 'me') {
            eventPartnerIds.add(partnerId);
          }
        }
      }
      // Count this event once per unique partner
      for (final partnerId in eventPartnerIds) {
        partnerEventCounts[partnerId] =
            (partnerEventCounts[partnerId] ?? 0) + 1;
      }
    }

    // Calculate days in period
    // For most recent, calculate from test date to now
    // For historical, calculate between the two test dates
    final int daysInPeriod;
    if (selectedTestIndex == 0) {
      daysInPeriod = DateTime.now().difference(periodStart).inDays;
    } else {
      daysInPeriod = periodEnd.difference(periodStart).inDays;
    }

    // Calculate risk score (0-100)
    final riskScore = _calculateRiskScore(
      eventCount: eventsInPeriod.length,
      uniquePartners: uniquePartnersInPeriod,
      riskyActivityCount: riskyCount,
      totalActivities: totalActivities,
      daysInPeriod: daysInPeriod,
    );

    // Build partner notification list if user tested positive
    final partnersToNotify = positiveTests.isNotEmpty
        ? _buildPartnerNotificationList(
            eventsInPeriod: eventsInPeriod,
            partnerEventCounts: partnerEventCounts,
            stateSnapshot: stateSnapshot,
            sexualActivities: sexualActivities,
          )
        : <PartnerNotificationInfo>[];

    // Build partner map for display
    final partnerMap = <String, Person>{};
    for (final person in stateSnapshot.allPersons ?? []) {
      if (partnerEventCounts.containsKey(person.id)) {
        partnerMap[person.id] = person;
      }
    }

    // Calculate next recommended test date (3 months per CDC guidelines)
    // Only for the most recent test period
    DateTime? nextRecommendedTestDate;
    if (selectedTestIndex == 0) {
      nextRecommendedTestDate = periodStart.add(const Duration(days: 90));
    }

    return SexualHealthAnalysisData(
      testDates: testDates,
      selectedTestIndex: selectedTestIndex,
      periodStartDate: periodStart,
      periodEndDate: periodEnd,
      mostRecentClinicalEvent: clinicalEvent,
      positiveTests: positiveTests,
      eventsInPeriod: eventsInPeriod,
      uniquePartnersInPeriod: uniquePartnersInPeriod,
      eventCountInPeriod: eventsInPeriod.length,
      riskyActivityCountInPeriod: riskyCount,
      safeActivityCountInPeriod: safeCount,
      totalActivitiesInPeriod: totalActivities,
      activityCountsInPeriod: activityCounts,
      sexualActivityCountsInPeriod: sexualActivityCounts,
      partnerEventCountsInPeriod: partnerEventCounts,
      categoryCountsInPeriod: categoryCounts,
      riskyActivityCountsByCategory: riskyActivityCountsByCategory,
      categoryActivityCountsInPeriod: categoryActivityCounts,
      daysInPeriod: daysInPeriod,
      riskScore: riskScore,
      hasValidData: true,
      partnersToNotify: partnersToNotify,
      partnerMap: partnerMap,
      nextRecommendedTestDate: nextRecommendedTestDate,
      activityCategories: activityCategories,
      sexualActivities: sexualActivities,
    );
  }

  static int _getUniquePartners(
    List<SexualEvent> events,
    EventState stateSnapshot,
  ) {
    final uniquePartnerIds = <String>{};
    for (final event in events) {
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          final partnerId = participant.participant.reference;
          if (partnerId.isNotEmpty && partnerId != 'me') {
            uniquePartnerIds.add(partnerId);
          }
        }
      }
    }
    uniquePartnerIds.remove('');
    return uniquePartnerIds.length;
  }

  static int _calculateRiskScore({
    required int eventCount,
    required int uniquePartners,
    required int riskyActivityCount,
    required int totalActivities,
    required int daysInPeriod,
  }) {
    if (eventCount == 0) return 0;

    double score = 0;

    // Factor 1: Number of events (0-30 points)
    score += (eventCount.clamp(0, 30) * 30 / 30);

    // Factor 2: Number of unique partners (0-30 points)
    score += (uniquePartners.clamp(0, 30) * 30 / 30);

    // Factor 3: Ratio of risky activities (0-25 points)
    if (totalActivities > 0) {
      final riskyRatio = riskyActivityCount / totalActivities;
      score += (riskyRatio * 25);
    }

    // Factor 4: Period length factor (0-15 points)
    // Longer period with activity = higher accumulated risk
    if (daysInPeriod <= 30) {
      score += 15;
    } else if (daysInPeriod <= 90) {
      score += 10;
    } else if (daysInPeriod <= 180) {
      score += 5;
    }

    return score.round().clamp(0, 100);
  }

  static List<PartnerNotificationInfo> _buildPartnerNotificationList({
    required List<SexualEvent> eventsInPeriod,
    required Map<String, int> partnerEventCounts,
    required EventState stateSnapshot,
    required Map<String, SexualActivity> sexualActivities,
  }) {
    final Map<String, PartnerNotificationInfo> partnerInfoMap = {};

    final persons = stateSnapshot.allPersons ?? [];
    final personMap = {for (var p in persons) p.id: p};

    for (final event in eventsInPeriod) {
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          final partnerId = participant.participant.reference;

          if (partnerId.isEmpty || partnerId == 'me') continue;

          final isAnonymous = partnerId == 'anonymous';
          final person = personMap[partnerId];
          final existing = partnerInfoMap[partnerId];

          final activityId = activity.category.reference;
          final sexualActivity = sexualActivities[activityId];
          final activityName = sexualActivity?.name ?? activityId;

          if (existing != null) {
            final updatedActivityTypes = List<String>.from(
              existing.activityTypes,
            );
            if (!updatedActivityTypes.contains(activityName)) {
              updatedActivityTypes.add(activityName);
            }
            partnerInfoMap[partnerId] = PartnerNotificationInfo(
              partnerId: partnerId,
              partnerName: isAnonymous
                  ? null
                  : (person?.name.nickname ?? person?.name.given),
              isAnonymous: isAnonymous,
              eventCount: existing.eventCount + 1,
              lastEventDate:
                  event.date.isAfter(existing.lastEventDate ?? DateTime(1970))
                  ? event.date
                  : existing.lastEventDate,
              activityTypes: updatedActivityTypes,
            );
          } else {
            partnerInfoMap[partnerId] = PartnerNotificationInfo(
              partnerId: partnerId,
              partnerName: isAnonymous
                  ? null
                  : (person?.name.nickname ?? person?.name.given),
              isAnonymous: isAnonymous,
              eventCount: 1,
              lastEventDate: event.date,
              activityTypes: [activityName],
            );
          }
        }
      }
    }

    final partners = partnerInfoMap.values.toList()
      ..sort((a, b) => b.eventCount.compareTo(a.eventCount));

    return partners;
  }
}
