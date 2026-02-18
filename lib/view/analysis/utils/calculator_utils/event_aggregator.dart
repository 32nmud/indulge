import 'package:indulge/data/models.dart';
import 'package:logging/logging.dart';
import 'analysis_date_utils.dart';
import '../person_cache.dart';
import '../../models/analysis_event_type.dart';

/// Result of the single pass through events, containing all raw counts
/// and accumulated data needed by downstream calculators, including
/// period-scoped statistics (previously computed in a separate pass by
/// PeriodStatsCalculator).
class EventAggregationResult {
  final Map<String, int> activityCounts;
  final Map<String, SexualActivityCategory> activityCategories;
  final Map<String, int> personCounts;
  final Map<String, int> personEventCounts;
  final Map<String, List<SexualEvent>> personEvents;
  final Map<String, Map<String, int>> personPropertyCounts;
  final Map<String, int> sexualActivityCountsTotal;
  final Map<String, SexualActivity> sexualActivities;
  final Map<String, Set<String>> sexualActivityPartnerCounts;

  final Map<String, int> soloActivityCounts;
  final Map<String, int> soloSexualActivityCounts;
  final int soloEventsTotal;
  final int nonSoloEventsTotal;

  final Map<AnalysisEventType, Map<String, int>> activityCountsByType;
  final Map<AnalysisEventType, Map<String, int>> sexualActivityCountsByType;
  final Map<AnalysisEventType, Map<String, int>> monthlyCountsByType;
  final Map<AnalysisEventType, Map<int, int>> dayOfWeekCountsByType;
  final Map<AnalysisEventType, int> eventCountsByType;
  final Map<AnalysisEventType, List<SexualEvent>> eventsByType;

  final int totalActivities;
  final int riskyActivityCount;
  final int safeActivityCount;
  final int anonymousPartnerInstances;

  final Map<String, int> dailyCounts;
  final Map<int, int> dayOfWeekCounts;
  final Map<String, int> monthlyCounts;
  final Map<String, int> weeklyCounts;

  /// Number of unique partners per event (unordered collection).
  final Set<int> eventPartnerCounts;

  /// Number of sexual activity instances per event (unordered collection).
  final Set<int> eventPropertyCounts;

  /// Number of activity categories per event (unordered collection).
  final Set<int> eventActivityCounts;

  // --- Period-scoped stats (formerly PeriodStatsResult) ---

  final int eventsThisMonth;
  final int eventsThisYear;
  final int uniquePartnersThisMonth;
  final int uniquePartnersThisYear;
  final int soloEventsThisYear;
  final int coupleEventsThisYear;
  final int groupEventsThisYear;
  final DateTime? busiestDay;
  final int busiestDayEventCount;
  final SexualEvent? busiestEvent;
  final int busiestEventActivityCount;
  final Map<String, int> activityCountsThisYear;
  final Map<String, int> soloActivityCountsThisYear;
  final Map<String, int> soloSexualActivityCountsThisYear;

  /// Partner counts scoped to this year, keyed by category ID.
  final Map<String, Set<String>> categoryPartnerCountsThisYear;

  /// Partner counts scoped to this year, keyed by sexual activity ID.
  final Map<String, Set<String>> sexualActivityPartnerCountsThisYear;

  /// Partner counts scoped to this year, keyed by category ID → sexual activity ID → partner set.
  final Map<String, Map<String, Set<String>>>
  categoryActivityPartnerCountsThisYear;

  const EventAggregationResult({
    required this.activityCounts,
    required this.activityCategories,
    required this.personCounts,
    required this.personEventCounts,
    required this.personEvents,
    required this.personPropertyCounts,
    required this.sexualActivityCountsTotal,
    required this.sexualActivities,
    required this.sexualActivityPartnerCounts,
    required this.soloActivityCounts,
    required this.soloSexualActivityCounts,
    required this.soloEventsTotal,
    required this.nonSoloEventsTotal,
    required this.activityCountsByType,
    required this.sexualActivityCountsByType,
    required this.monthlyCountsByType,
    required this.dayOfWeekCountsByType,
    required this.eventCountsByType,
    required this.eventsByType,
    required this.totalActivities,
    required this.riskyActivityCount,
    required this.safeActivityCount,
    required this.anonymousPartnerInstances,
    required this.dailyCounts,
    required this.dayOfWeekCounts,
    required this.monthlyCounts,
    required this.weeklyCounts,
    required this.eventPartnerCounts,
    required this.eventPropertyCounts,
    required this.eventActivityCounts,
    // Period-scoped
    required this.eventsThisMonth,
    required this.eventsThisYear,
    required this.uniquePartnersThisMonth,
    required this.uniquePartnersThisYear,
    required this.soloEventsThisYear,
    required this.coupleEventsThisYear,
    required this.groupEventsThisYear,
    required this.busiestDay,
    required this.busiestDayEventCount,
    required this.busiestEvent,
    required this.busiestEventActivityCount,
    required this.activityCountsThisYear,
    required this.soloActivityCountsThisYear,
    required this.soloSexualActivityCountsThisYear,
    required this.categoryPartnerCountsThisYear,
    required this.sexualActivityPartnerCountsThisYear,
    required this.categoryActivityPartnerCountsThisYear,
  });
}

/// Performs a single pass through events, accumulating all raw counts
/// (activity counts, partner counts, daily/weekly/monthly counts,
/// event type classification, risky/safe tallies, etc.) **and** all
/// period-scoped statistics (this month, this year, busiest day/event).
///
/// This replaces the previous two-pass design where [EventAggregator] and
/// `PeriodStatsCalculator` iterated over all events independently.
class EventAggregator {
  static final Logger _logger = Logger('EventAggregator');

  /// Iterates through [sortedEvents] (pre-sorted by date ascending) and
  /// accumulates every raw count needed for downstream analysis, including
  /// period-scoped stats.
  ///
  /// Uses a pre-built [PersonCache] for synchronous person lookups instead
  /// of hitting the database per participant.
  ///
  /// [startDate] is the beginning of the selected time window (e.g. 12 months
  /// ago). If null, defaults to 12 months before now.
  static EventAggregationResult aggregate(
    List<SexualEvent> sortedEvents,
    PersonCache personCache,
    Map<String, SexualActivityCategory>? sexualActivityCategories,
    Map<String, SexualActivity>? sexualActivitiesMap, {
    DateTime? startDate,
  }) {
    // ---------- time window boundaries ----------
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisYearStart = startDate ?? DateTime(now.year, now.month - 11, 1);

    _logger.info('Aggregating with time window starting from: $thisYearStart');

    // ---------- all-time accumulators ----------
    final activityCounts = <String, int>{};
    final activityCategories = <String, SexualActivityCategory>{};
    final personCounts = <String, int>{};
    final personEventCounts = <String, int>{};
    final personEvents = <String, List<SexualEvent>>{};
    final personPropertyCounts = <String, Map<String, int>>{};
    final sexualActivityCountsTotal = <String, int>{};
    final sexualActivities = <String, SexualActivity>{};
    final sexualActivityPartnerCounts = <String, Set<String>>{};

    final soloActivityCounts = <String, int>{};
    final soloSexualActivityCounts = <String, int>{};
    int soloEventsTotal = 0;
    int nonSoloEventsTotal = 0;

    final activityCountsByType = {
      for (var type in AnalysisEventType.values) type: <String, int>{},
    };
    final sexualActivityCountsByType = {
      for (var type in AnalysisEventType.values) type: <String, int>{},
    };
    final monthlyCountsByType = {
      for (var type in AnalysisEventType.values) type: <String, int>{},
    };
    final dayOfWeekCountsByType = {
      for (var type in AnalysisEventType.values) type: <int, int>{},
    };
    final eventCountsByType = {
      for (var type in AnalysisEventType.values) type: 0,
    };
    final eventsByType = {
      for (var type in AnalysisEventType.values) type: <SexualEvent>[],
    };

    int totalActivities = 0;
    int riskyActivityCount = 0;
    int safeActivityCount = 0;
    int anonymousPartnerInstances = 0;

    final dailyCounts = <String, int>{};
    final dayOfWeekCounts = <int, int>{};
    final monthlyCounts = <String, int>{};
    final weeklyCounts = <String, int>{};
    final eventPartnerCounts = <int>{};
    final eventPropertyCounts = <int>{};
    final eventActivityCounts = <int>{};

    // ---------- period-scoped accumulators ----------
    int eventsThisMonth = 0;
    int eventsThisYear = 0;
    final partnersThisMonth = <String>{};
    final partnersThisYear = <String>{};
    int anonymousCountThisMonth = 0;
    int anonymousCountThisYear = 0;

    int soloEventsThisYear = 0;
    int coupleEventsThisYear = 0;
    int groupEventsThisYear = 0;

    final dailyCountsThisYear = <String, int>{};
    DateTime? busiestDay;
    int busiestDayEventCount = 0;
    SexualEvent? busiestEventThisYear;
    int busiestEventActivityCountThisYear = 0;

    final activityCountsThisYear = <String, int>{};
    final soloActivityCountsThisYear = <String, int>{};
    final soloSexualActivityCountsThisYear = <String, int>{};

    final categoryPartnerCountsThisYear = <String, Set<String>>{};
    final sexualActivityPartnerCountsThisYear = <String, Set<String>>{};
    final categoryActivityPartnerCountsThisYear =
        <String, Map<String, Set<String>>>{};

    // ---------- iterate events (single pass) ----------
    for (final event in sortedEvents) {
      // --- Time window flags ---
      final isThisMonth = event.date.isAfter(
        thisMonthStart.subtract(const Duration(days: 1)),
      );
      final isThisYear = event.date.isAfter(
        thisYearStart.subtract(const Duration(days: 1)),
      );

      // --- All-time: daily counts ---
      final dKey = dateKey(event.date);
      dailyCounts[dKey] = (dailyCounts[dKey] ?? 0) + 1;

      // --- All-time: day of week counts (1 = Monday, 7 = Sunday) ---
      final dayOfWeek = event.date.weekday;
      dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;

      // --- All-time: monthly counts ---
      final mKey = monthKey(event.date);
      monthlyCounts[mKey] = (monthlyCounts[mKey] ?? 0) + 1;

      // --- Period: this-month counter ---
      if (isThisMonth) {
        eventsThisMonth++;
      }

      // --- Period: this-year counter ---
      if (isThisYear) {
        eventsThisYear++;
      }

      // Track partners in this event (all-time)
      final eventPartners = <String>{};
      // Track partners in this event scoped to this-year
      final eventPartnersThisYear = <String>{};

      // Track activities and sexual activities for this event
      int eventProperties = 0;
      int eventActivitiesCount = 0;
      final eventActivityCategoryIds = <String, int>{};
      final eventSexualActivityIds = <String, int>{};

      for (final activity in event.activities) {
        eventActivitiesCount++;
        totalActivities++;

        // Activity category counts
        final activityCategoryId = activity.category.reference;
        activityCounts[activityCategoryId] =
            (activityCounts[activityCategoryId] ?? 0) + 1;
        eventActivityCategoryIds[activityCategoryId] =
            (eventActivityCategoryIds[activityCategoryId] ?? 0) + 1;
        final activityCategory = sexualActivityCategories?[activityCategoryId];
        if (activityCategory != null) {
          activityCategories[activityCategoryId] = activityCategory;
        }

        // Period: activity counts this year
        if (isThisYear) {
          activityCountsThisYear[activityCategoryId] =
              (activityCountsThisYear[activityCategoryId] ?? 0) + 1;
        }

        // Check if activity is risky (has any risky sexual activities)
        bool hasRiskyProperty = false;

        for (final participant in activity.participants) {
          final personId = participant.participant.reference;

          // Check if participant is "me" — synchronous cache lookup
          final isMe = personCache.isSelf(personId);

          if (!isMe) {
            // --- All-time: count participants (partners only) ---
            personCounts[personId] = (personCounts[personId] ?? 0) + 1;
            eventPartners.add(personId);

            // Count anonymous partner instances
            if (personId == 'anonymous') {
              anonymousPartnerInstances++;
            }

            // --- Period: this-month partner tracking ---
            if (isThisMonth) {
              if (personId == 'anonymous') {
                anonymousCountThisMonth++;
              } else {
                partnersThisMonth.add(personId);
              }
            }

            // --- Period: this-year partner tracking ---
            if (isThisYear) {
              if (personId == 'anonymous') {
                anonymousCountThisYear++;
              } else {
                partnersThisYear.add(personId);
              }
              eventPartnersThisYear.add(personId);

              // Track unique partners per activity category (this year)
              categoryPartnerCountsThisYear.putIfAbsent(
                activityCategoryId,
                () => {},
              );
              categoryPartnerCountsThisYear[activityCategoryId]!.add(personId);
            }
          }

          // Count sexual activities (for everyone, including me)
          for (final activityCount in participant.activityCounts) {
            final sexualActivityId = activityCount.activityReference.reference;
            final count = activityCount.count;

            sexualActivityCountsTotal[sexualActivityId] =
                (sexualActivityCountsTotal[sexualActivityId] ?? 0) + count;
            eventSexualActivityIds[sexualActivityId] =
                (eventSexualActivityIds[sexualActivityId] ?? 0) + count;
            final sexualActivity = sexualActivitiesMap?[sexualActivityId];
            if (sexualActivity != null) {
              sexualActivities[sexualActivityId] = sexualActivity;

              // Check if this sexual activity is risky
              if (sexualActivity.isRisky) {
                _logger.fine(
                  'Found risky sexual activity: ${sexualActivity.name} (${sexualActivity.id})',
                );
                hasRiskyProperty = true;
              }
            }
            eventProperties += count;

            if (!isMe) {
              // Track sexual activities per partner
              personPropertyCounts.putIfAbsent(personId, () => {});
              personPropertyCounts[personId]![sexualActivityId] =
                  (personPropertyCounts[personId]![sexualActivityId] ?? 0) +
                  count;

              // Track unique partners per sexual activity (all-time)
              sexualActivityPartnerCounts.putIfAbsent(
                sexualActivityId,
                () => {},
              );
              sexualActivityPartnerCounts[sexualActivityId]!.add(personId);

              // --- Period: this-year sexual activity partner tracking ---
              if (isThisYear) {
                sexualActivityPartnerCountsThisYear.putIfAbsent(
                  sexualActivityId,
                  () => {},
                );
                sexualActivityPartnerCountsThisYear[sexualActivityId]!.add(
                  personId,
                );

                // Track unique partners per sexual activity within each category
                categoryActivityPartnerCountsThisYear.putIfAbsent(
                  activityCategoryId,
                  () => {},
                );
                categoryActivityPartnerCountsThisYear[activityCategoryId]!
                    .putIfAbsent(sexualActivityId, () => {});
                categoryActivityPartnerCountsThisYear[activityCategoryId]![sexualActivityId]!
                    .add(personId);
              }
            }
          }
        }

        // Count risky vs safe activities
        if (hasRiskyProperty) {
          riskyActivityCount++;
          _logger.fine('Risky activity count: $riskyActivityCount');
        } else {
          safeActivityCount++;
        }
      }

      // ---------- classify event type (all-time) ----------
      AnalysisEventType eventType;
      if (eventPartners.isEmpty) {
        eventType = AnalysisEventType.solo;
        soloEventsTotal++;
        eventActivityCategoryIds.forEach((key, count) {
          soloActivityCounts[key] = (soloActivityCounts[key] ?? 0) + count;
        });
        eventSexualActivityIds.forEach((key, count) {
          soloSexualActivityCounts[key] =
              (soloSexualActivityCounts[key] ?? 0) + count;
        });
      } else if (eventPartners.length == 1) {
        eventType = AnalysisEventType.couple;
        nonSoloEventsTotal++;
      } else {
        eventType = AnalysisEventType.group;
        nonSoloEventsTotal++;
      }

      eventCountsByType[eventType] = (eventCountsByType[eventType] ?? 0) + 1;
      eventsByType[eventType]!.add(event);

      // Update by-type maps
      eventActivityCategoryIds.forEach((key, count) {
        activityCountsByType[eventType]![key] =
            (activityCountsByType[eventType]![key] ?? 0) + count;
      });
      eventSexualActivityIds.forEach((key, count) {
        sexualActivityCountsByType[eventType]![key] =
            (sexualActivityCountsByType[eventType]![key] ?? 0) + count;
      });
      monthlyCountsByType[eventType]![mKey] =
          (monthlyCountsByType[eventType]![mKey] ?? 0) + 1;
      dayOfWeekCountsByType[eventType]![dayOfWeek] =
          (dayOfWeekCountsByType[eventType]![dayOfWeek] ?? 0) + 1;

      // Record partners, properties, and activities for this event
      eventPartnerCounts.add(eventPartners.length);
      eventPropertyCounts.add(eventProperties);
      eventActivityCounts.add(eventActivitiesCount);

      // Track events per partner
      for (final partnerId in eventPartners) {
        personEventCounts[partnerId] = (personEventCounts[partnerId] ?? 0) + 1;
        personEvents.putIfAbsent(partnerId, () => []).add(event);
      }

      // Track weekly counts (ISO 8601 week)
      final wKey = getWeekKey(event.date);
      weeklyCounts[wKey] = (weeklyCounts[wKey] ?? 0) + 1;

      // ---------- period: this-year event type classification ----------
      if (isThisYear) {
        if (eventPartnersThisYear.isEmpty) {
          soloEventsThisYear++;
          eventActivityCategoryIds.forEach((key, count) {
            soloActivityCountsThisYear[key] =
                (soloActivityCountsThisYear[key] ?? 0) + count;
          });
          // Note: sexual activity counts for solo events this year are
          // accumulated from the eventSexualActivityIds that were built
          // during the participant loop (which skips "me"), so for pure
          // solo events these will typically be empty.
          eventSexualActivityIds.forEach((key, count) {
            // Only include if the solo classification came from the
            // this-year partner set (eventPartnersThisYear).
            soloSexualActivityCountsThisYear[key] =
                (soloSexualActivityCountsThisYear[key] ?? 0) + count;
          });
        } else if (eventPartnersThisYear.length == 1) {
          coupleEventsThisYear++;
        } else {
          groupEventsThisYear++;
        }

        // Track daily counts for busiest day (this year)
        dailyCountsThisYear[dKey] = (dailyCountsThisYear[dKey] ?? 0) + 1;

        // Track busiest event (this year)
        final eventActivityCount = event.activities.length;
        if (eventActivityCount > busiestEventActivityCountThisYear) {
          busiestEventThisYear = event;
          busiestEventActivityCountThisYear = eventActivityCount;
        }
      }
    }

    // ---------- post-loop: find busiest day from this year ----------
    dailyCountsThisYear.forEach((dateStr, count) {
      if (count > busiestDayEventCount) {
        busiestDayEventCount = count;
        busiestDay = DateTime.parse(dateStr);
      }
    });

    final uniquePartnersThisMonth =
        partnersThisMonth.length + anonymousCountThisMonth;
    final uniquePartnersThisYear =
        partnersThisYear.length + anonymousCountThisYear;

    return EventAggregationResult(
      activityCounts: activityCounts,
      activityCategories: activityCategories,
      personCounts: personCounts,
      personEventCounts: personEventCounts,
      personEvents: personEvents,
      personPropertyCounts: personPropertyCounts,
      sexualActivityCountsTotal: sexualActivityCountsTotal,
      sexualActivities: sexualActivities,
      sexualActivityPartnerCounts: sexualActivityPartnerCounts,
      soloActivityCounts: soloActivityCounts,
      soloSexualActivityCounts: soloSexualActivityCounts,
      soloEventsTotal: soloEventsTotal,
      nonSoloEventsTotal: nonSoloEventsTotal,
      activityCountsByType: activityCountsByType,
      sexualActivityCountsByType: sexualActivityCountsByType,
      monthlyCountsByType: monthlyCountsByType,
      dayOfWeekCountsByType: dayOfWeekCountsByType,
      eventCountsByType: eventCountsByType,
      eventsByType: eventsByType,
      totalActivities: totalActivities,
      riskyActivityCount: riskyActivityCount,
      safeActivityCount: safeActivityCount,
      anonymousPartnerInstances: anonymousPartnerInstances,
      dailyCounts: dailyCounts,
      dayOfWeekCounts: dayOfWeekCounts,
      monthlyCounts: monthlyCounts,
      weeklyCounts: weeklyCounts,
      eventPartnerCounts: eventPartnerCounts,
      eventPropertyCounts: eventPropertyCounts,
      eventActivityCounts: eventActivityCounts,
      // Period-scoped
      eventsThisMonth: eventsThisMonth,
      eventsThisYear: eventsThisYear,
      uniquePartnersThisMonth: uniquePartnersThisMonth,
      uniquePartnersThisYear: uniquePartnersThisYear,
      soloEventsThisYear: soloEventsThisYear,
      coupleEventsThisYear: coupleEventsThisYear,
      groupEventsThisYear: groupEventsThisYear,
      busiestDay: busiestDay,
      busiestDayEventCount: busiestDayEventCount,
      busiestEvent: busiestEventThisYear,
      busiestEventActivityCount: busiestEventActivityCountThisYear,
      activityCountsThisYear: activityCountsThisYear,
      soloActivityCountsThisYear: soloActivityCountsThisYear,
      soloSexualActivityCountsThisYear: soloSexualActivityCountsThisYear,
      categoryPartnerCountsThisYear: categoryPartnerCountsThisYear,
      sexualActivityPartnerCountsThisYear: sexualActivityPartnerCountsThisYear,
      categoryActivityPartnerCountsThisYear:
          categoryActivityPartnerCountsThisYear,
    );
  }
}
