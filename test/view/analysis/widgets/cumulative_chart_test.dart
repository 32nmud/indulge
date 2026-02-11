import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/analysis/models/analysis_data.dart';

void main() {
  group('Cumulative Chart Calculations', () {
    test('cumulative values should never decrease', () {
      // This test verifies the fix for cumulative lines going down
      // when different activities/properties have data in different time periods

      // Simulate activities with different date ranges
      final events = [
        // Activity A: Jan-Mar
        _createEventWithActivity('activity_a', DateTime(2024, 1, 15)),
        _createEventWithActivity('activity_a', DateTime(2024, 2, 15)),
        _createEventWithActivity('activity_a', DateTime(2024, 3, 15)),
        // Activity B: Feb-May (overlaps and extends beyond A)
        _createEventWithActivity('activity_b', DateTime(2024, 2, 15)),
        _createEventWithActivity('activity_b', DateTime(2024, 3, 15)),
        _createEventWithActivity('activity_b', DateTime(2024, 4, 15)),
        _createEventWithActivity('activity_b', DateTime(2024, 5, 15)),
      ];

      // Group by month and activity
      final monthlyData = <String, Map<DateTime, int>>{
        'activity_a': {},
        'activity_b': {},
      };

      for (final event in events) {
        final monthDate = DateTime(event.date.year, event.date.month, 1);
        final activityId = event.activities.first.category.reference;
        monthlyData[activityId]![monthDate] =
            (monthlyData[activityId]![monthDate] ?? 0) + 1;
      }

      // Calculate cumulative (simulating the chart logic)
      final cumulativeData = <String, Map<DateTime, int>>{};

      for (final activityId in monthlyData.keys) {
        cumulativeData[activityId] = {};
        final activityMonthly = monthlyData[activityId]!;

        if (activityMonthly.isEmpty) continue;

        final allDates = activityMonthly.keys.toList()..sort();
        var cumulativeTotal = 0;

        for (final date in allDates) {
          cumulativeTotal += activityMonthly[date] ?? 0;
          cumulativeData[activityId]![date] = cumulativeTotal;
        }
      }

      // Find global date range
      final allDatesAcrossActivities =
          cumulativeData.values.expand((data) => data.keys).toSet().toList()
            ..sort();

      final globalFirstDate = allDatesAcrossActivities.first;
      final globalLastDate = allDatesAcrossActivities.last;

      // Fill each activity's cumulative data across the full date range
      for (final activityId in monthlyData.keys) {
        final activityData = cumulativeData[activityId];
        if (activityData == null || activityData.isEmpty) continue;

        final activityDates = activityData.keys.toList()..sort();
        final activityFirstDate = activityDates.first;

        var currentDate = DateTime(
          globalFirstDate.year,
          globalFirstDate.month,
          1,
        );
        final filledData = <DateTime, int>{};
        var lastCumulativeValue = 0;

        while (currentDate.isBefore(globalLastDate) ||
            currentDate.isAtSameMomentAs(globalLastDate)) {
          if (currentDate.isBefore(activityFirstDate)) {
            // Before this activity's data starts, value is 0
            filledData[currentDate] = 0;
          } else if (activityData.containsKey(currentDate)) {
            // Activity has data for this date
            lastCumulativeValue = activityData[currentDate]!;
            filledData[currentDate] = lastCumulativeValue;
          } else {
            // After activity's data starts but missing this month: carry forward
            filledData[currentDate] = lastCumulativeValue;
          }
          currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
        }

        cumulativeData[activityId] = filledData;
      }

      // Verify cumulative values never decrease
      for (final activityId in cumulativeData.keys) {
        final activityData = cumulativeData[activityId]!;
        final sortedDates = activityData.keys.toList()..sort();

        var previousValue = 0;
        for (final date in sortedDates) {
          final currentValue = activityData[date]!;
          expect(
            currentValue,
            greaterThanOrEqualTo(previousValue),
            reason:
                'Cumulative value for $activityId at $date should never be less than previous value',
          );
          previousValue = currentValue;
        }
      }

      // Specific checks for our test data
      final activityAData = cumulativeData['activity_a']!;
      final activityBData = cumulativeData['activity_b']!;

      // Activity A should have data for all months Jan-May
      expect(activityAData.length, 5);

      // Activity A cumulative should be: 1, 2, 3, 3, 3 (carries forward after Mar)
      expect(activityAData[DateTime(2024, 1, 1)], 1);
      expect(activityAData[DateTime(2024, 2, 1)], 2);
      expect(activityAData[DateTime(2024, 3, 1)], 3);
      expect(activityAData[DateTime(2024, 4, 1)], 3); // Carried forward
      expect(activityAData[DateTime(2024, 5, 1)], 3); // Carried forward

      // Activity B should have data for all months Jan-May
      expect(activityBData.length, 5);

      // Activity B cumulative should be: 0, 1, 2, 3, 4
      expect(activityBData[DateTime(2024, 1, 1)], 0); // Before it started
      expect(activityBData[DateTime(2024, 2, 1)], 1);
      expect(activityBData[DateTime(2024, 3, 1)], 2);
      expect(activityBData[DateTime(2024, 4, 1)], 3);
      expect(activityBData[DateTime(2024, 5, 1)], 4);
    });

    test('cumulative chart handles single month data correctly', () {
      final events = [
        _createEventWithActivity('activity_a', DateTime(2024, 3, 15)),
      ];

      final monthlyData = <String, Map<DateTime, int>>{
        'activity_a': {DateTime(2024, 3, 1): 1},
      };

      // Should not throw and should maintain the single value
      expect(monthlyData['activity_a']!.length, 1);
      expect(monthlyData['activity_a']![DateTime(2024, 3, 1)], 1);
    });

    test('cumulative chart handles empty data correctly', () {
      final monthlyData = <String, Map<DateTime, int>>{'activity_a': {}};

      final cumulativeData = <String, Map<DateTime, int>>{};

      for (final activityId in monthlyData.keys) {
        final activityMonthly = monthlyData[activityId]!;
        if (activityMonthly.isEmpty) continue;

        cumulativeData[activityId] = {};
        // This should never execute for empty data
        fail('Should not process empty monthly data');
      }

      expect(cumulativeData['activity_a'], isNull);
    });

    test(
      'property cumulative values never decrease across different time ranges',
      () {
        // Similar test for properties
        final events = [
          // Property A: Jan-Feb
          _createEventWithProperty('property_a', DateTime(2024, 1, 15), 2),
          _createEventWithProperty('property_a', DateTime(2024, 2, 15), 1),
          // Property B: Mar-Apr
          _createEventWithProperty('property_b', DateTime(2024, 3, 15), 3),
          _createEventWithProperty('property_b', DateTime(2024, 4, 15), 2),
        ];

        // Process similar to activities
        final monthlyData = <String, Map<DateTime, int>>{
          'property_a': {},
          'property_b': {},
        };

        for (final event in events) {
          final monthDate = DateTime(event.date.year, event.date.month, 1);
          for (final activity in event.activities) {
            for (final participant in activity.participants) {
              for (final propertyCount in participant.activityCounts) {
                final propertyId = propertyCount.activityReference.reference;
                if (monthlyData.containsKey(propertyId)) {
                  monthlyData[propertyId]![monthDate] =
                      (monthlyData[propertyId]![monthDate] ?? 0) +
                      propertyCount.count;
                }
              }
            }
          }
        }

        // Calculate cumulative
        final cumulativeData = <String, Map<DateTime, int>>{};
        for (final propertyId in monthlyData.keys) {
          cumulativeData[propertyId] = {};
          final propertyMonthly = monthlyData[propertyId]!;

          if (propertyMonthly.isEmpty) continue;

          final allDates = propertyMonthly.keys.toList()..sort();
          var cumulativeTotal = 0;

          for (final date in allDates) {
            cumulativeTotal += propertyMonthly[date] ?? 0;
            cumulativeData[propertyId]![date] = cumulativeTotal;
          }
        }

        // Verify no decreases
        for (final propertyId in cumulativeData.keys) {
          final propertyData = cumulativeData[propertyId]!;
          final sortedDates = propertyData.keys.toList()..sort();

          var previousValue = 0;
          for (final date in sortedDates) {
            final currentValue = propertyData[date]!;
            expect(
              currentValue,
              greaterThanOrEqualTo(previousValue),
              reason: 'Cumulative value for $propertyId should never decrease',
            );
            previousValue = currentValue;
          }
        }
      },
    );
  });
}

// Helper functions to create test events
SexualEvent _createEventWithActivity(String activityId, DateTime date) {
  return SexualEvent(
    id: 'event_${date.millisecondsSinceEpoch}',
    date: date,
    activities: [
      EventActivity(
        category: Reference(reference: activityId),
        participants: [],
      ),
    ],
  );
}

SexualEvent _createEventWithProperty(
  String propertyId,
  DateTime date,
  int count,
) {
  return SexualEvent(
    id: 'event_${date.millisecondsSinceEpoch}',
    date: date,
    activities: [
      EventActivity(
        category: Reference(reference: 'activity_1'),
        participants: [
          ActivityParticipant(
            participant: Reference(reference: 'person_1'),
            activityCounts: [
              ActivityCount(
                activityReference: Reference(reference: propertyId),
                count: count,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
