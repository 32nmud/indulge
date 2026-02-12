import 'package:indulge/data/models.dart';

/// Result of streak calculation.
class StreakData {
  final int currentStreak;
  final int longestStreak;

  const StreakData({required this.currentStreak, required this.longestStreak});
}

/// Calculates current and longest streaks from a list of sorted events.
class StreakCalculator {
  /// Computes the current and longest consecutive-day streaks from
  /// [sortedEvents] (which must already be sorted by date ascending).
  static StreakData calculate(List<SexualEvent> sortedEvents) {
    if (sortedEvents.isEmpty) {
      return const StreakData(currentStreak: 0, longestStreak: 0);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get all unique dates with events — keep both a Set (for O(1) lookups)
    // and a sorted List (for sequential streak scanning).
    final eventDateSet = <DateTime>{};
    for (final e in sortedEvents) {
      eventDateSet.add(DateTime(e.date.year, e.date.month, e.date.day));
    }
    final eventDates = eventDateSet.toList()..sort();

    // Calculate current streak (working backwards from today)
    int currentStreak = 0;
    DateTime checkDate = today;

    // Check if there's an event today or yesterday to start the streak
    final lastEventDate = eventDates.last;
    final daysSinceLastEvent = today.difference(lastEventDate).inDays;

    if (daysSinceLastEvent <= 1) {
      // Start counting streak — O(1) per lookup via Set
      while (true) {
        if (eventDateSet.contains(checkDate)) {
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

    return StreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }
}
