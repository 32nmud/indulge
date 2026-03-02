import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/view/analysis/utils/calculator_utils/comparison_calculator.dart';

void main() {
  group('ComparisonCalculator', () {
    /// Helper to create a minimal SexualEvent with just a date.
    SexualEvent createEvent(DateTime date) {
      return SexualEvent(
        id: 'event-${date.millisecondsSinceEpoch}',
        date: date,
        activities: const [],
      );
    }

    /// Helper to create a SexualEvent with activities.
    SexualEvent createEventWithActivities(
      DateTime date,
      List<String> activityIds,
    ) {
      final activities = activityIds
          .map(
            (id) => EventActivity(
              category: const Reference(
                reference: 'category-sex',
                resourceType: 'SexualActivityCategory',
              ),
              participants: [
                ActivityParticipant(
                  participant: const Reference(
                    reference: 'me',
                    resourceType: 'Person',
                  ),
                  activityCounts: activityIds
                      .map(
                        (aId) => ActivityCount(
                          categoryReference: Reference(
                            reference: 'category-sex',
                            resourceType: 'SexualActivityCategory',
                          ),
                          activityName: aId,
                          count: 1,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          )
          .toList();

      return SexualEvent(
        id: 'event-${date.millisecondsSinceEpoch}',
        date: date,
        activities: activities,
      );
    }

    group('calculateWeekComparison', () {
      test('returns zero for empty events list', () {
        final now = DateTime(2024, 6, 15); // A Saturday
        final result = ComparisonCalculator.calculateWeekComparison([], now);

        expect(result.currentPeriodCount, 0);
        expect(result.previousPeriodCount, 0);
        expect(result.percentageChange, 0.0);
      });

      test('counts events in this week correctly', () {
        // June 15, 2024 is a Saturday (weekday 6)
        final now = DateTime(2024, 6, 15);
        final events = [
          createEvent(DateTime(2024, 6, 15)), // This week, today
          createEvent(DateTime(2024, 6, 14)), // This week, Friday
          createEvent(DateTime(2024, 6, 13)), // This week, Thursday
        ];

        final result = ComparisonCalculator.calculateWeekComparison(
          events,
          now,
        );

        expect(result.currentPeriodCount, 3);
      });

      test('counts events in last week correctly', () {
        final now = DateTime(2024, 6, 15); // Saturday
        final events = [
          createEvent(DateTime(2024, 6, 8)), // Last week, Saturday
          createEvent(DateTime(2024, 6, 7)), // Last week, Friday
          createEvent(DateTime(2024, 6, 6)), // Last week, Thursday
        ];

        final result = ComparisonCalculator.calculateWeekComparison(
          events,
          now,
        );

        expect(result.previousPeriodCount, 3);
      });

      test('distinguishes between this week and last week', () {
        final now = DateTime(2024, 6, 15); // Saturday
        final events = [
          createEvent(DateTime(2024, 6, 15)), // This week
          createEvent(DateTime(2024, 6, 10)), // This week (Monday)
          createEvent(DateTime(2024, 6, 8)), // Last week (Saturday)
          createEvent(DateTime(2024, 6, 3)), // Last week (Monday)
        ];

        final result = ComparisonCalculator.calculateWeekComparison(
          events,
          now,
        );

        expect(result.currentPeriodCount, 2);
        expect(result.previousPeriodCount, 2);
      });

      test('handles events outside both weeks', () {
        final now = DateTime(2024, 6, 15);
        final events = [
          createEvent(DateTime(2024, 6, 15)), // This week
          createEvent(DateTime(2024, 5, 1)), // Much older
        ];

        final result = ComparisonCalculator.calculateWeekComparison(
          events,
          now,
        );

        expect(result.currentPeriodCount, 1);
        expect(result.previousPeriodCount, 0);
      });
    });

    group('calculateMonthComparison', () {
      test('returns zero for empty events list', () {
        final now = DateTime(2024, 6, 15);
        final result = ComparisonCalculator.calculateMonthComparison([], now);

        expect(result.currentPeriodCount, 0);
        expect(result.previousPeriodCount, 0);
      });

      test('counts events in this month correctly', () {
        final now = DateTime(2024, 6, 15);
        final events = [
          createEvent(DateTime(2024, 6, 15)),
          createEvent(DateTime(2024, 6, 10)),
          createEvent(DateTime(2024, 6, 1)),
        ];

        final result = ComparisonCalculator.calculateMonthComparison(
          events,
          now,
        );

        expect(result.currentPeriodCount, 3);
      });

      test('counts events in last month correctly', () {
        final now = DateTime(2024, 6, 15);
        final events = [
          createEvent(DateTime(2024, 5, 31)),
          createEvent(DateTime(2024, 5, 15)),
          createEvent(DateTime(2024, 5, 1)),
        ];

        final result = ComparisonCalculator.calculateMonthComparison(
          events,
          now,
        );

        expect(result.previousPeriodCount, 3);
      });

      test('handles year boundary correctly (January to December)', () {
        final now = DateTime(2024, 1, 15);
        final events = [
          createEvent(DateTime(2024, 1, 10)), // This month (January)
          createEvent(DateTime(2023, 12, 31)), // Last month (December)
          createEvent(DateTime(2023, 12, 15)),
        ];

        final result = ComparisonCalculator.calculateMonthComparison(
          events,
          now,
        );

        expect(result.currentPeriodCount, 1);
        expect(result.previousPeriodCount, 2);
      });

      test('distinguishes between this month and last month', () {
        final now = DateTime(2024, 6, 15);
        final events = [
          createEvent(DateTime(2024, 6, 15)), // This month
          createEvent(DateTime(2024, 6, 1)), // This month
          createEvent(DateTime(2024, 5, 31)), // Last month
          createEvent(DateTime(2024, 5, 1)), // Last month
        ];

        final result = ComparisonCalculator.calculateMonthComparison(
          events,
          now,
        );

        expect(result.currentPeriodCount, 2);
        expect(result.previousPeriodCount, 2);
      });
    });

    group('calculateDaysSinceLastRisky', () {
      test('returns -1 when no events exist', () {
        final mockState = EventState(sexualActivities: {});
        final result = ComparisonCalculator.calculateDaysSinceLastRisky(
          [],
          mockState,
        );

        expect(result, -1);
      });

      test('returns -1 when no risky activities in state', () {
        final events = [
          createEventWithActivities(
            DateTime.now().subtract(const Duration(days: 5)),
            ['safe-activity'],
          ),
        ];

        final mockState = EventState(
          sexualActivities: {
            'Safe Activity': const SexualActivity(
              name: 'Safe Activity',
              stiRisk: false,
              healthRisk: false,
            ),
          },
        );

        final result = ComparisonCalculator.calculateDaysSinceLastRisky(
          events,
          mockState,
        );

        expect(result, -1);
      });

      test('returns days since last risky activity', () {
        final now = DateTime.now();
        final events = [
          createEventWithActivities(now.subtract(const Duration(days: 10)), [
            'risky-activity',
          ]),
          createEventWithActivities(now.subtract(const Duration(days: 5)), [
            'safe-activity',
          ]),
        ];

        final mockState = EventState(
          sexualActivities: {
            'Risky Activity': const SexualActivity(
              name: 'Risky Activity',
              stiRisk: true,
              healthRisk: false,
            ),
            'Safe Activity': const SexualActivity(
              name: 'Safe Activity',
              stiRisk: false,
              healthRisk: false,
            ),
          },
        );

        final result = ComparisonCalculator.calculateDaysSinceLastRisky(
          events,
          mockState,
        );

        // Should find the risky activity from 10 days ago
        expect(result, closeTo(10, 1));
      });

      test('finds most recent risky activity when mixed with safe ones', () {
        final now = DateTime.now();
        final events = [
          createEventWithActivities(now.subtract(const Duration(days: 3)), [
            'safe-activity',
          ]),
          createEventWithActivities(now.subtract(const Duration(days: 7)), [
            'risky-activity',
          ]),
          createEventWithActivities(now.subtract(const Duration(days: 1)), [
            'another-safe',
          ]),
        ];

        final mockState = EventState(
          sexualActivities: {
            'Risky Activity': const SexualActivity(
              name: 'Risky Activity',
              stiRisk: true,
              healthRisk: false,
            ),
            'Safe Activity': const SexualActivity(
              name: 'Safe Activity',
              stiRisk: false,
              healthRisk: false,
            ),
            'Another Safe': const SexualActivity(
              name: 'Another Safe',
              stiRisk: false,
              healthRisk: false,
            ),
          },
        );

        final result = ComparisonCalculator.calculateDaysSinceLastRisky(
          events,
          mockState,
        );

        // Should find the risky activity from 7 days ago
        expect(result, closeTo(7, 1));
      });

      test('handles null sexualActivities in state', () {
        final events = [
          createEventWithActivities(
            DateTime.now().subtract(const Duration(days: 5)),
            ['any-activity'],
          ),
        ];

        // sexualActivities is null
        final mockState = EventState();

        final result = ComparisonCalculator.calculateDaysSinceLastRisky(
          events,
          mockState,
        );

        expect(result, -1);
      });
    });
  });
}
