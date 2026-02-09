import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../models/analysis_data.dart';

/// Calculates comprehensive analysis statistics from a list of events
class AnalysisCalculator {
  static final Logger _logger = Logger('AnalysisCalculator');

  /// Computes all analysis data from the given events
  static AnalysisData calculate(
    List<SexualEvent> events,
    EventState providerState, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (events.isEmpty) {
      return _emptyAnalysisData(events, providerState, startDate, endDate);
    }

    // Sort events by date
    final sortedEvents = List<SexualEvent>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate basic counts
    final activityCounts = <String, int>{};
    final activityTypes = <String, SexualActivityType>{};
    final personCounts = <String, int>{};
    final personEventCounts = <String, int>{};
    final personEvents = <String, List<SexualEvent>>{};
    final personPropertyCounts = <String, Map<String, int>>{};
    final propertyCountsTotal = <String, int>{};
    final properties = <String, SexualActivityTypeProperty>{};

    int totalActivities = 0;
    int riskyActivityCount = 0;
    int safeActivityCount = 0;

    final dailyCounts = <String, int>{};
    final dayOfWeekCounts = <int, int>{};
    final monthlyCounts = <String, int>{};
    final weeklyCounts = <String, int>{}; // yyyy-Www format
    final eventPartnerCounts = <int>{}; // Partners per individual event
    final eventPropertyCounts = <int>{}; // Properties per individual event
    final eventActivityCounts = <int>{}; // Activities per individual event

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

          // Count participants
          personCounts[personId] = (personCounts[personId] ?? 0) + 1;
          eventPartners.add(personId); // Track unique partners in this event

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

    // Calculate streaks
    final streakData = _calculateStreaks(sortedEvents);

    // Calculate period comparisons
    final now = DateTime.now();
    final thisWeekVsLastWeek = _calculateWeekComparison(sortedEvents, now);
    final thisMonthVsLastMonth = _calculateMonthComparison(sortedEvents, now);

    // Calculate averages based on distinct weeks/months with events
    final distinctWeeks = weeklyCounts.length.clamp(1, double.infinity);
    final distinctMonths = monthlyCounts.length.clamp(1, double.infinity);

    final averageActivitiesPerWeek = totalActivities / distinctWeeks;
    final averageActivitiesPerMonth = totalActivities / distinctMonths;

    // Calculate event-focused averages
    final averageEventsPerWeek = events.length / distinctWeeks;
    final averageEventsPerMonth = events.length / distinctMonths;

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

    // Calculate average events per day of week
    final averageEventsPerDayOfWeek = <int, double>{};
    for (int day = 1; day <= 7; day++) {
      final count = dayOfWeekCounts[day] ?? 0;
      averageEventsPerDayOfWeek[day] = count / distinctWeeks;
    }

    // Days since last risky activity
    final daysSinceLastRiskyActivity = _calculateDaysSinceLastRisky(
      sortedEvents,
      providerState,
    );

    // Days since last activity
    final lastEventDate = sortedEvents.last.date;
    final daysSinceLastActivity = now.difference(lastEventDate).inDays;

    return AnalysisData(
      totalEvents: events.length,
      totalActivities: totalActivities,
      uniquePartners: personCounts.length,
      riskyActivityCount: riskyActivityCount,
      safeActivityCount: safeActivityCount,
      activityCounts: activityCounts,
      activityTypes: activityTypes,
      personCounts: personCounts,
      personEventCounts: personEventCounts,
      personEvents: personEvents,
      personPropertyCounts: personPropertyCounts,
      propertyCountsTotal: propertyCountsTotal,
      properties: properties,
      dailyCounts: dailyCounts,
      dayOfWeekCounts: dayOfWeekCounts,
      monthlyCounts: monthlyCounts,
      currentStreak: streakData.currentStreak,
      longestStreak: streakData.longestStreak,
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
  ) {
    return AnalysisData(
      totalEvents: 0,
      totalActivities: 0,
      uniquePartners: 0,
      riskyActivityCount: 0,
      safeActivityCount: 0,
      activityCounts: {},
      activityTypes: {},
      personCounts: {},
      personEventCounts: {},
      personEvents: {},
      personPropertyCounts: {},
      propertyCountsTotal: {},
      properties: {},
      dailyCounts: {},
      dayOfWeekCounts: {},
      monthlyCounts: {},
      currentStreak: 0,
      longestStreak: 0,
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
