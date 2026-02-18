import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/analysis/utils/calculator_utils/streak_calculator.dart';

void main() {
  group('StreakCalculator', () {
    /// Helper to create a minimal SexualEvent with just a date.
    SexualEvent createEvent(DateTime date) {
      return SexualEvent(
        id: 'event-${date.millisecondsSinceEpoch}',
        date: date,
        activities: const [],
      );
    }

    group('calculate', () {
      test('returns zero streaks for empty events list', () {
        final result = StreakCalculator.calculate([]);

        expect(result.currentStreak, 0);
        expect(result.longestStreak, 0);
      });

      test('returns streak of 1 for single event', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final events = [createEvent(today)];

        final result = StreakCalculator.calculate(events);

        expect(result.currentStreak, 1);
        expect(result.longestStreak, 1);
      });

      test(
        'calculates correct current streak when events are today and yesterday',
        () {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          final events = [createEvent(today), createEvent(yesterday)];

          final result = StreakCalculator.calculate(events);

          expect(result.currentStreak, 2);
          expect(result.longestStreak, 2);
        },
      );

      test(
        'calculates correct current streak for consecutive days ending today',
        () {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final day2 = today.subtract(const Duration(days: 1));
          final day3 = today.subtract(const Duration(days: 2));

          final events = [
            createEvent(today),
            createEvent(day2),
            createEvent(day3),
          ];

          final result = StreakCalculator.calculate(events);

          expect(result.currentStreak, 3);
          expect(result.longestStreak, 3);
        },
      );

      test('resets current streak when last event was 2 days ago', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final threeDaysAgo = today.subtract(const Duration(days: 3));

        final events = [createEvent(threeDaysAgo)];

        final result = StreakCalculator.calculate(events);

        expect(result.currentStreak, 0);
        expect(result.longestStreak, 1);
      });

      test('calculates longest streak correctly with gaps', () {
        // Events on Mon, Tue, Thu, Fri, Sat (gap on Wed)
        final base = DateTime(2024, 1, 1); // Monday
        final events = [
          createEvent(base), // Mon
          createEvent(base.add(const Duration(days: 1))), // Tue
          createEvent(base.add(const Duration(days: 3))), // Thu
          createEvent(base.add(const Duration(days: 4))), // Fri
          createEvent(base.add(const Duration(days: 5))), // Sat
        ];

        final result = StreakCalculator.calculate(events);

        expect(result.longestStreak, 3); // Thu, Fri, Sat
        expect(result.currentStreak, 0); // No recent activity
      });

      test('handles multiple separate streaks and returns the longest', () {
        // Events: 1, 2 (streak of 2), then gap, then 4, 5, 6 (streak of 3)
        final base = DateTime(2024, 1, 1);
        final events = [
          createEvent(base),
          createEvent(base.add(const Duration(days: 1))),
          createEvent(base.add(const Duration(days: 4))),
          createEvent(base.add(const Duration(days: 5))),
          createEvent(base.add(const Duration(days: 6))),
        ];

        final result = StreakCalculator.calculate(events);

        expect(result.longestStreak, 3);
      });

      test('handles unsorted events (they should be sorted internally)', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final twoDaysAgo = today.subtract(const Duration(days: 2));

        // Pass in reverse order
        final events = [
          createEvent(today),
          createEvent(twoDaysAgo),
          createEvent(yesterday),
        ];

        final result = StreakCalculator.calculate(events);

        expect(result.currentStreak, 3);
        expect(result.longestStreak, 3);
      });

      test('handles multiple events on the same day', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        // Multiple events on same day should count as one unique day
        final events = [
          createEvent(today),
          createEvent(today),
          createEvent(today),
          createEvent(yesterday),
        ];

        final result = StreakCalculator.calculate(events);

        expect(result.currentStreak, 2);
        expect(result.longestStreak, 2);
      });

      test('longest streak includes current streak if it is the longest', () {
        // Recent streak of 5, no longer streaks before
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final events = [
          createEvent(today),
          createEvent(today.subtract(const Duration(days: 1))),
          createEvent(today.subtract(const Duration(days: 2))),
          createEvent(today.subtract(const Duration(days: 3))),
          createEvent(today.subtract(const Duration(days: 4))),
        ];

        final result = StreakCalculator.calculate(events);

        expect(result.currentStreak, 5);
        expect(result.longestStreak, 5);
      });

      test('returns correct streaks when events span many days with gaps', () {
        // Pattern: 10-day streak, gap of 5, 3-day streak
        final base = DateTime(2024, 1, 1);
        final events = <SexualEvent>[];

        // First streak: days 0-9
        for (int i = 0; i < 10; i++) {
          events.add(createEvent(base.add(Duration(days: i))));
        }

        // Gap: days 10-14 (no events)

        // Second streak: days 15-17
        for (int i = 15; i < 18; i++) {
          events.add(createEvent(base.add(Duration(days: i))));
        }

        final result = StreakCalculator.calculate(events);

        expect(result.longestStreak, 10);
        // Current streak depends on today's date relative to last event
      });
    });
  });
}
