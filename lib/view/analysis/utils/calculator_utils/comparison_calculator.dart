import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:logging/logging.dart';
import '../../models/period_comparison.dart';

/// Calculates period-over-period comparisons (week-over-week, month-over-month)
/// and days since the last risky activity.
class ComparisonCalculator {
  static final Logger _logger = Logger('ComparisonCalculator');

  /// Compares this week's event count against last week's.
  static PeriodComparison calculateWeekComparison(
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

  /// Compares this month's event count against last month's.
  static PeriodComparison calculateMonthComparison(
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

  /// Returns the number of days since the last event that included a risky
  /// sexual activity, or `-1` if no risky activities were found.
  static int calculateDaysSinceLastRisky(
    List<SexualEvent> sortedEvents,
    EventState providerState,
  ) {
    final now = DateTime.now();
    DateTime? lastRiskyDate;

    for (final event in sortedEvents.reversed) {
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          for (final activityCount in participant.activityCounts) {
            // Look up activity by category + name
            final categoryRef = activityCount.categoryReference.reference;
            final activityName = activityCount.activityName;
            if (categoryRef.isEmpty || activityName.isEmpty) continue;

            final category =
                providerState.sexualActivityCategories?[categoryRef];
            SexualActivity? sexualActivity;
            if (category != null) {
              for (final activity in category.activities) {
                if (activity.name == activityName) {
                  sexualActivity = activity;
                  break;
                }
              }
            }

            if ((sexualActivity?.stiRisk ?? false) ||
                (sexualActivity?.healthRisk ?? false)) {
              lastRiskyDate = event.date;
              _logger.fine(
                'Last risky activity found on ${event.date} with sexual activity ${sexualActivity?.name}',
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
