import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../models/analysis_data.dart';

/// Calculates comprehensive analysis statistics from a list of events
class AnalysisCalculator {
  static final Logger _logger = Logger('AnalysisCalculator');

  /// Computes all analysis data from the given events
  static Future<AnalysisData> calculate(
    List<SexualEvent> events,
    SexualEventsProvider provider, {
    DateTime? startDate,
    DateTime? endDate,
    String timeWindowLabel = 'Last 12 months',
  }) async {
    final providerState = provider.state;
    if (events.isEmpty) {
      return _emptyAnalysisData(
        events,
        providerState,
        startDate,
        endDate,
        timeWindowLabel,
      );
    }

    // Sort events by date
    final sortedEvents = List<SexualEvent>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate basic counts
    final activityCounts = <String, int>{}; // All time for backwards compat
    final activityCountsThisYear = <String, int>{}; // Last 12 months
    final activityTypes = <String, SexualActivityType>{};
    final personCounts = <String, int>{};
    final personEventCounts = <String, int>{};
    final personEvents = <String, List<SexualEvent>>{};
    final personPropertyCounts = <String, Map<String, int>>{};
    final propertyCountsTotal = <String, int>{};
    final properties = <String, SexualActivityTypeProperty>{};
    final propertyPartnerCounts =
        <
          String,
          Set<String>
        >{}; // Track unique partners per property (all time)

    // Track activity-partner and property-partner counts for last 12 months
    final activityPartnerCountsThisYear = <String, Set<String>>{};
    final propertyPartnerCountsThisYear = <String, Set<String>>{};
    final activityPropertyPartnerCountsThisYear =
        <
          String,
          Map<String, Set<String>>
        >{}; // activity -> property -> partners

    int totalActivities = 0;
    int riskyActivityCount = 0;
    int safeActivityCount = 0;
    int anonymousPartnerInstances = 0;

    final dailyCounts = <String, int>{};
    final dayOfWeekCounts = <int, int>{};
    final monthlyCounts = <String, int>{};
    final weeklyCounts = <String, int>{}; // yyyy-Www format
    final eventPartnerCounts = <int>{}; // Partners per individual event
    final eventPropertyCounts = <int>{}; // Properties per individual event
    final eventActivityCounts = <int>{}; // Activities per individual event

    // Track busiest event (will be filtered to last 12 months later)

    for (final event in sortedEvents) {
      // Daily counts
      final dateKey = DateFormat('yyyy-MM-dd').format(event.date);
      dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;

      // Day of week counts (1 = Monday, 7 = Sunday)
      final dayOfWeek = event.date.weekday;
      dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;

      // Track partners in this event
      final eventPartners = <String>{};

      // Monthly counts
      final monthKey = DateFormat('yyyy-MM').format(event.date);
      monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;

      // Track properties and activities for this event
      int eventProperties = 0;
      int eventActivitiesCount = 0;

      for (final activity in event.activities) {
        eventActivitiesCount++;
        totalActivities++;

        // Activity type counts
        final activityTypeId = activity.type.reference;
        activityCounts[activityTypeId] =
            (activityCounts[activityTypeId] ?? 0) + 1;
        final activityType = providerState.sexualActivityTypes?[activityTypeId];
        if (activityType != null) {
          activityTypes[activityTypeId] = activityType;
        }

        // Check if activity is risky (has any risky properties)
        bool hasRiskyProperty = false;

        for (final participant in activity.participants) {
          final personId = participant.participant.reference;

          // Skip "me" person in partner counts
          final person = await provider.getPersonById(personId);
          if (person?.isSelf ?? false) {
            continue; // Skip "me" from partner statistics
          }

          // Count participants
          personCounts[personId] = (personCounts[personId] ?? 0) + 1;
          eventPartners.add(personId); // Track unique partners in this event

          // Count anonymous partner instances
          if (personId == 'anonymous') {
            anonymousPartnerInstances++;
          }

          // Count properties
          for (final propertyCount in participant.propertyCounts) {
            final propertyId = propertyCount.propertyReference.reference;
            final count = propertyCount.count;

            propertyCountsTotal[propertyId] =
                (propertyCountsTotal[propertyId] ?? 0) + count;
            final property =
                providerState.sexualActivityTypeProperties?[propertyId];
            if (property != null) {
              properties[propertyId] = property;

              // Check if this property is risky
              if (property.isRisky) {
                _logger.fine(
                  'Found risky property: ${property.name} (${property.id})',
                );
                hasRiskyProperty = true;
              }
            }
            eventProperties += count; // Track properties in this event

            // Track properties per partner
            personPropertyCounts.putIfAbsent(personId, () => {});
            personPropertyCounts[personId]![propertyId] =
                (personPropertyCounts[personId]![propertyId] ?? 0) + count;

            // Track unique partners per property
            propertyPartnerCounts.putIfAbsent(propertyId, () => {});
            propertyPartnerCounts[propertyId]!.add(personId);
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
      final weekKey = _getWeekKey(event.date);
      weeklyCounts[weekKey] = (weeklyCounts[weekKey] ?? 0) + 1;
    }

    // Calculate this month/year stats
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);

    // Use provided startDate or default to last 12 months
    final thisYearStart = startDate ?? DateTime(now.year, now.month - 11, 1);

    _logger.info(
      'Filtering for selected time window starting from: $thisYearStart',
    );

    // Track longest and current streak
    final longestStreak = _calculateStreaks(sortedEvents).longestStreak;
    final currentStreak = _calculateStreaks(sortedEvents).currentStreak;

    int eventsThisMonth = 0;
    int eventsThisYear = 0;
    final partnersThisMonth = <String>{};
    final partnersThisYear = <String>{};
    int anonymousCountThisMonth = 0;
    int anonymousCountThisYear = 0;

    // Solo, couple, group counts for last 12 months
    int soloEventsThisYear = 0;
    int coupleEventsThisYear = 0;
    int groupEventsThisYear = 0;

    // Track busiest day/event in last 12 months
    final dailyCountsThisYear = <String, int>{};
    DateTime? busiestDay;
    int busiestDayEventCount = 0;
    SexualEvent? busiestEventThisYear;
    int busiestEventActivityCountThisYear = 0;

    for (final event in sortedEvents) {
      final isThisMonth = event.date.isAfter(
        thisMonthStart.subtract(const Duration(days: 1)),
      );
      final isThisYear = event.date.isAfter(
        thisYearStart.subtract(const Duration(days: 1)),
      );

      if (isThisMonth) {
        eventsThisMonth++;
        for (final activity in event.activities) {
          for (final participant in activity.participants) {
            final personId = participant.participant.reference;
            final person = await provider.getPersonById(personId);
            if (person?.isSelf ?? false) continue; // Skip "me"

            if (personId == 'anonymous') {
              anonymousCountThisMonth++;
            } else {
              partnersThisMonth.add(personId);
            }
          }
        }
      }

      if (isThisYear) {
        eventsThisYear++;

        // Count partners in this event (excluding me)
        final eventPartnersNoMe = <String>{};
        for (final activity in event.activities) {
          final activityTypeId = activity.type.reference;

          // Track activity counts for last 12 months
          activityCountsThisYear[activityTypeId] =
              (activityCountsThisYear[activityTypeId] ?? 0) + 1;

          for (final participant in activity.participants) {
            final personId = participant.participant.reference;
            final person = await provider.getPersonById(personId);
            if (person?.isSelf ?? false) continue; // Skip "me"

            if (personId == 'anonymous') {
              anonymousCountThisYear++;
            } else {
              partnersThisYear.add(personId);
            }
            eventPartnersNoMe.add(personId);

            // Track unique partners per activity type (last 12 months)
            activityPartnerCountsThisYear.putIfAbsent(activityTypeId, () => {});
            activityPartnerCountsThisYear[activityTypeId]!.add(personId);

            // Track unique partners per property (last 12 months)
            for (final propertyCount in participant.propertyCounts) {
              final propertyId = propertyCount.propertyReference.reference;

              propertyPartnerCountsThisYear.putIfAbsent(propertyId, () => {});
              propertyPartnerCountsThisYear[propertyId]!.add(personId);

              // Track unique partners per property within each activity type
              activityPropertyPartnerCountsThisYear.putIfAbsent(
                activityTypeId,
                () => {},
              );
              activityPropertyPartnerCountsThisYear[activityTypeId]!
                  .putIfAbsent(propertyId, () => {});
              activityPropertyPartnerCountsThisYear[activityTypeId]![propertyId]!
                  .add(personId);
            }
          }
        }

        // Categorize event type
        if (eventPartnersNoMe.isEmpty) {
          soloEventsThisYear++;
        } else if (eventPartnersNoMe.length == 1) {
          coupleEventsThisYear++;
        } else {
          groupEventsThisYear++;
        }

        // Track daily counts for busiest day
        final dateKey = DateFormat('yyyy-MM-dd').format(event.date);
        dailyCountsThisYear[dateKey] = (dailyCountsThisYear[dateKey] ?? 0) + 1;

        // Track busiest event
        final eventActivityCount = event.activities.length;
        if (eventActivityCount > busiestEventActivityCountThisYear) {
          busiestEventThisYear = event;
          busiestEventActivityCountThisYear = eventActivityCount;
        }
      }
    }

    // Find busiest day from last 12 months
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

    // Count known partners (excluding anonymous)
    final knownPartners = personCounts.keys
        .where((id) => id != 'anonymous')
        .length;

    // Calculate period comparisons (these use all events, not filtered)
    final thisWeekVsLastWeek = _calculateWeekComparison(sortedEvents, now);
    final thisMonthVsLastMonth = _calculateMonthComparison(sortedEvents, now);

    // Calculate averages based on last 12 months only
    final weeklyCountsThisYear = <String, int>{};
    final monthlyCountsThisYear = <String, int>{};

    for (final event in sortedEvents) {
      if (event.date.isAfter(thisYearStart.subtract(const Duration(days: 1)))) {
        final weekKey = _getWeekKey(event.date);
        weeklyCountsThisYear[weekKey] =
            (weeklyCountsThisYear[weekKey] ?? 0) + 1;

        final monthKey = DateFormat('yyyy-MM').format(event.date);
        monthlyCountsThisYear[monthKey] =
            (monthlyCountsThisYear[monthKey] ?? 0) + 1;
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

    // Calculate event-focused averages (last 12 months)
    final averageEventsPerWeek = eventsThisYear / distinctWeeksThisYear;
    final averageEventsPerMonth = eventsThisYear / distinctMonthsThisYear;

    final averagePartnersPerEvent = eventPartnerCounts.isNotEmpty
        ? eventPartnerCounts.reduce((a, b) => a + b) / eventPartnerCounts.length
        : 0.0;

    final averageActivitiesPerEvent = eventActivityCounts.isNotEmpty
        ? eventActivityCounts.reduce((a, b) => a + b) /
              eventActivityCounts.length
        : 0.0;

    final averagePropertiesPerEvent = eventPropertyCounts.isNotEmpty
        ? eventPropertyCounts.reduce((a, b) => a + b) /
              eventPropertyCounts.length
        : 0.0;

    // Calculate average events per day of week (based on last 12 months)
    final averageEventsPerDayOfWeek = <int, double>{};
    for (int day = 1; day <= 7; day++) {
      final count = dayOfWeekCounts[day] ?? 0;
      averageEventsPerDayOfWeek[day] = count / distinctWeeksThisYear;
    }

    // Convert property-partner counts to final map (all time)
    final propertyPartnerCountsMap = <String, int>{};
    propertyPartnerCounts.forEach((propertyId, partners) {
      propertyPartnerCountsMap[propertyId] = partners.length;
    });

    // Convert activity-partner counts for last 12 months
    final activityPartnerCountsThisYearMap = <String, int>{};
    activityPartnerCountsThisYear.forEach((activityId, partners) {
      activityPartnerCountsThisYearMap[activityId] = partners.length;
    });

    // Convert property-partner counts for last 12 months
    final propertyPartnerCountsThisYearMap = <String, int>{};
    propertyPartnerCountsThisYear.forEach((propertyId, partners) {
      propertyPartnerCountsThisYearMap[propertyId] = partners.length;
    });

    // Convert activity-property-partner counts for last 12 months
    final activityPropertyPartnerCountsThisYearMap =
        <String, Map<String, int>>{};
    activityPropertyPartnerCountsThisYear.forEach((activityId, propertyMap) {
      activityPropertyPartnerCountsThisYearMap[activityId] = {};
      propertyMap.forEach((propertyId, partners) {
        activityPropertyPartnerCountsThisYearMap[activityId]![propertyId] =
            partners.length;
      });
    });

    // Days since last risky activity
    final daysSinceLastRiskyActivity = _calculateDaysSinceLastRisky(
      sortedEvents,
      providerState,
    );

    // Days since last activity
    final lastEventDate = sortedEvents.last.date;
    final daysSinceLastActivity = now.difference(lastEventDate).inDays;

    return AnalysisData(
      timeWindowLabel: timeWindowLabel,
      totalEvents: events.length,
      totalActivities: totalActivities,
      uniquePartners: personCounts.length,
      riskyActivityCount: riskyActivityCount,
      safeActivityCount: safeActivityCount,
      eventsThisMonth: eventsThisMonth,
      eventsThisYear: eventsThisYear,
      uniquePartnersThisMonth: uniquePartnersThisMonth,
      uniquePartnersThisYear: uniquePartnersThisYear,
      knownPartners: knownPartners,
      anonymousPartnerInstances: anonymousPartnerInstances,
      busiestDay: busiestDay,
      busiestDayEventCount: busiestDayEventCount,
      busiestEvent: busiestEventThisYear,
      busiestEventActivityCount: busiestEventActivityCountThisYear,
      soloEventsThisYear: soloEventsThisYear,
      coupleEventsThisYear: coupleEventsThisYear,
      groupEventsThisYear: groupEventsThisYear,
      activityCounts: activityCounts,
      activityCountsThisYear: activityCountsThisYear,
      activityTypes: activityTypes,
      longestStreak: longestStreak,
      currentStreak: currentStreak,
      personCounts: personCounts,
      personEventCounts: personEventCounts,
      personEvents: personEvents,
      personPropertyCounts: personPropertyCounts,
      propertyCountsTotal: propertyCountsTotal,
      properties: properties,
      propertyPartnerCounts: propertyPartnerCountsMap,
      activityPartnerCountsThisYear: activityPartnerCountsThisYearMap,
      propertyPartnerCountsThisYear: propertyPartnerCountsThisYearMap,
      activityPropertyPartnerCountsThisYear:
          activityPropertyPartnerCountsThisYearMap,
      dailyCounts: dailyCounts,
      dayOfWeekCounts: dayOfWeekCounts,
      monthlyCounts: monthlyCounts,
      daysSinceLastRiskyActivity: daysSinceLastRiskyActivity,
      daysSinceLastActivity: daysSinceLastActivity,
      thisWeekVsLastWeek: thisWeekVsLastWeek,
      thisMonthVsLastMonth: thisMonthVsLastMonth,
      averageEventsPerWeek: averageEventsPerWeek,
      averageEventsPerMonth: averageEventsPerMonth,
      averageActivitiesPerWeek: averageActivitiesPerWeek,
      averageActivitiesPerMonth: averageActivitiesPerMonth,
      averagePartnersPerEvent: averagePartnersPerEvent,
      averageActivitiesPerEvent: averageActivitiesPerEvent,
      averagePropertiesPerEvent: averagePropertiesPerEvent,
      averageEventsPerDayOfWeek: averageEventsPerDayOfWeek,
      startDate: startDate,
      endDate: endDate,
      events: events,
    );
  }

  static AnalysisData _emptyAnalysisData(
    List<SexualEvent> events,
    EventState providerState,
    DateTime? startDate,
    DateTime? endDate,
    String timeWindowLabel,
  ) {
    return AnalysisData(
      timeWindowLabel: timeWindowLabel,
      totalEvents: 0,
      totalActivities: 0,
      uniquePartners: 0,
      riskyActivityCount: 0,
      safeActivityCount: 0,
      eventsThisMonth: 0,
      eventsThisYear: 0,
      uniquePartnersThisMonth: 0,
      uniquePartnersThisYear: 0,
      knownPartners: 0,
      anonymousPartnerInstances: 0,
      busiestDay: null,
      busiestDayEventCount: 0,
      busiestEvent: null,
      busiestEventActivityCount: 0,
      soloEventsThisYear: 0,
      coupleEventsThisYear: 0,
      groupEventsThisYear: 0,
      activityCounts: {},
      activityCountsThisYear: {},
      activityTypes: {},
      longestStreak: 0,
      currentStreak: 0,
      personCounts: {},
      personEventCounts: {},
      personEvents: {},
      personPropertyCounts: {},
      propertyCountsTotal: {},
      properties: {},
      propertyPartnerCounts: {},
      activityPartnerCountsThisYear: {},
      propertyPartnerCountsThisYear: {},
      activityPropertyPartnerCountsThisYear: {},
      dailyCounts: {},
      dayOfWeekCounts: {},
      monthlyCounts: {},
      daysSinceLastRiskyActivity: -1,
      daysSinceLastActivity: 0,
      thisWeekVsLastWeek: const PeriodComparison(
        currentPeriodCount: 0,
        previousPeriodCount: 0,
        percentageChange: 0,
        isIncrease: false,
      ),
      thisMonthVsLastMonth: const PeriodComparison(
        currentPeriodCount: 0,
        previousPeriodCount: 0,
        percentageChange: 0,
        isIncrease: false,
      ),
      averageEventsPerWeek: 0.0,
      averageEventsPerMonth: 0.0,
      averageActivitiesPerWeek: 0.0,
      averageActivitiesPerMonth: 0.0,
      averagePartnersPerEvent: 0.0,
      averageActivitiesPerEvent: 0.0,
      averagePropertiesPerEvent: 0.0,
      averageEventsPerDayOfWeek: {},
      startDate: startDate,
      endDate: endDate,
      events: events,
    );
  }

  static _StreakData _calculateStreaks(List<SexualEvent> sortedEvents) {
    if (sortedEvents.isEmpty) {
      return _StreakData(currentStreak: 0, longestStreak: 0);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get all unique dates with events
    final eventDates =
        sortedEvents
            .map((e) {
              final date = e.date;
              return DateTime(date.year, date.month, date.day);
            })
            .toSet()
            .toList()
          ..sort();

    // Calculate current streak (working backwards from today)
    int currentStreak = 0;
    DateTime checkDate = today;

    // Check if there's an event today or yesterday to start the streak
    final lastEventDate = eventDates.last;
    final daysSinceLastEvent = today.difference(lastEventDate).inDays;

    if (daysSinceLastEvent <= 1) {
      // Start counting streak
      while (true) {
        if (eventDates.contains(checkDate)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 1;

    for (int i = 1; i < eventDates.length; i++) {
      final daysDiff = eventDates[i].difference(eventDates[i - 1]).inDays;

      if (daysDiff == 1) {
        // Consecutive days
        tempStreak++;
      } else {
        // Streak broken
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        tempStreak = 1;
      }
    }

    // Check the last streak
    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }

    // Make sure current streak is at least as long as it appears
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    return _StreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  static PeriodComparison _calculateWeekComparison(
    List<SexualEvent> sortedEvents,
    DateTime now,
  ) {
    // Calculate start of this week (Monday) and last week
    final todayWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final thisWeekStart = now.subtract(Duration(days: todayWeekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));

    int thisWeekCount = 0;
    int lastWeekCount = 0;

    for (final event in sortedEvents) {
      if (event.date.isAfter(thisWeekStart.subtract(const Duration(days: 1))) &&
          event.date.isBefore(now.add(const Duration(days: 1)))) {
        thisWeekCount++;
      } else if (event.date.isAfter(
            lastWeekStart.subtract(const Duration(days: 1)),
          ) &&
          event.date.isBefore(lastWeekEnd.add(const Duration(days: 1)))) {
        lastWeekCount++;
      }
    }

    return PeriodComparison.calculate(thisWeekCount, lastWeekCount);
  }

  static PeriodComparison _calculateMonthComparison(
    List<SexualEvent> sortedEvents,
    DateTime now,
  ) {
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
      1,
    );
    final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));

    int thisMonthCount = 0;
    int lastMonthCount = 0;

    for (final event in sortedEvents) {
      if (event.date.isAfter(
            thisMonthStart.subtract(const Duration(days: 1)),
          ) &&
          event.date.isBefore(now.add(const Duration(days: 1)))) {
        thisMonthCount++;
      } else if (event.date.isAfter(
            lastMonthStart.subtract(const Duration(days: 1)),
          ) &&
          event.date.isBefore(lastMonthEnd.add(const Duration(days: 1)))) {
        lastMonthCount++;
      }
    }

    return PeriodComparison.calculate(thisMonthCount, lastMonthCount);
  }

  static int _calculateDaysSinceLastRisky(
    List<SexualEvent> sortedEvents,
    EventState providerState,
  ) {
    final now = DateTime.now();
    DateTime? lastRiskyDate;

    for (final event in sortedEvents.reversed) {
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          for (final propertyCount in participant.propertyCounts) {
            final propertyId = propertyCount.propertyReference.reference;
            final property =
                providerState.sexualActivityTypeProperties?[propertyId];

            if (property?.isRisky ?? false) {
              lastRiskyDate = event.date;
              _logger.fine(
                'Last risky activity found on ${event.date} with property ${property?.name}',
              );
              break;
            }
          }
          if (lastRiskyDate != null) break;
        }
        if (lastRiskyDate != null) break;
      }
      if (lastRiskyDate != null) break;
    }

    if (lastRiskyDate == null) {
      _logger.fine('No risky activities found in event history');
      return -1; // No risky activities found
    }

    final daysSince = now.difference(lastRiskyDate).inDays;
    _logger.fine('Days since last risky activity: $daysSince');
    return daysSince;
  }
}

class _StreakData {
  final int currentStreak;
  final int longestStreak;

  _StreakData({required this.currentStreak, required this.longestStreak});
}

/// Returns a week key in ISO 8601 format (yyyy-Www)
String _getWeekKey(DateTime date) {
  // ISO 8601 week date calculation
  final dayOfYear = _dayOfYear(date);
  final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday

  // Calculate week number
  final week = ((dayOfYear - dayOfWeek + 10) / 7).floor();

  // Handle edge cases for year boundaries
  if (week == 0) {
    // This date belongs to the last week of the previous year
    return _getWeekKey(DateTime(date.year - 1, 12, 28));
  } else if (week == 53) {
    // Check if this week belongs to next year
    final dec31 = DateTime(date.year, 12, 31);
    if (dec31.weekday < 4) {
      return '${date.year + 1}-W01';
    }
  }

  return '${date.year}-W${week.toString().padLeft(2, '0')}';
}

int _dayOfYear(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  return date.difference(firstDayOfYear).inDays + 1;
}
