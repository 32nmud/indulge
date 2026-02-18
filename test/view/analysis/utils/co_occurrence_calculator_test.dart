import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/analysis/utils/calculator_utils/co_occurrence_calculator.dart';

void main() {
  group('CoOccurrenceCalculator', () {
    /// Helper to create a SexualEvent with activities and participants.
    SexualEvent createEvent(
      DateTime date, {
      List<String> categoryIds = const [],
      List<String> activityIds = const [],
    }) {
      final activities = <EventActivity>[];

      // Add activities for each category
      for (final catId in categoryIds) {
        activities.add(
          EventActivity(
            category: Reference(
              reference: catId,
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
                        activityReference: Reference(
                          reference: aId,
                          resourceType: 'SexualActivity',
                        ),
                        count: 1,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      }

      return SexualEvent(
        id: 'event-${date.millisecondsSinceEpoch}',
        date: date,
        activities: activities,
      );
    }

    group('calculate', () {
      test('returns empty results for empty events list', () {
        final result = CoOccurrenceCalculator.calculate(
          [],
          activityCategories: {},
          sexualActivities: {},
        );

        expect(result.topCategoryPairs, isEmpty);
        expect(result.topActivityPairs, isEmpty);
      });

      test('returns empty results for events with no activities', () {
        final events = [
          SexualEvent(
            id: 'event-1',
            date: DateTime(2024, 1, 1),
            activities: const [],
          ),
        ];

        final result = CoOccurrenceCalculator.calculate(
          events,
          activityCategories: {},
          sexualActivities: {},
        );

        expect(result.topCategoryPairs, isEmpty);
        expect(result.topActivityPairs, isEmpty);
      });

      test('calculates category co-occurrences correctly for single event', () {
        final events = [
          createEvent(
            DateTime(2024, 1, 1),
            categoryIds: ['kissing', 'foreplay'],
          ),
        ];

        final categories = {
          'kissing': SexualActivityCategory(id: 'kissing', name: 'Kissing'),
          'foreplay': SexualActivityCategory(id: 'foreplay', name: 'Foreplay'),
        };

        final result = CoOccurrenceCalculator.calculate(
          events,
          activityCategories: categories,
          sexualActivities: {},
        );

        expect(result.topCategoryPairs.length, 1);
        expect(result.topCategoryPairs[0].id1, 'foreplay');
        expect(result.topCategoryPairs[0].id2, 'kissing');
        expect(result.topCategoryPairs[0].count, 1);
      });

      test('calculates activity co-occurrences correctly', () {
        final events = [
          createEvent(
            DateTime(2024, 1, 1),
            categoryIds: ['sex'],
            activityIds: ['oral-male', 'vaginal'],
          ),
        ];

        final activities = {
          'oral-male': SexualActivity(id: 'oral-male', name: 'Oral (Male)'),
          'vaginal': SexualActivity(id: 'vaginal', name: 'Vaginal'),
        };

        final result = CoOccurrenceCalculator.calculate(
          events,
          activityCategories: {},
          sexualActivities: activities,
        );

        expect(result.topActivityPairs.length, 1);
        expect(result.topActivityPairs[0].count, 1);
      });

      test('counts co-occurrences across multiple events', () {
        // Two events with the same category pair
        final events = [
          createEvent(
            DateTime(2024, 1, 1),
            categoryIds: ['kissing', 'foreplay'],
          ),
          createEvent(
            DateTime(2024, 1, 2),
            categoryIds: ['kissing', 'foreplay'],
          ),
          createEvent(DateTime(2024, 1, 3), categoryIds: ['kissing']),
        ];

        final categories = {
          'kissing': SexualActivityCategory(id: 'kissing', name: 'Kissing'),
          'foreplay': SexualActivityCategory(id: 'foreplay', name: 'Foreplay'),
        };

        final result = CoOccurrenceCalculator.calculate(
          events,
          activityCategories: categories,
          sexualActivities: {},
        );

        // Should have 1 pair: kissing+foreplay with count 2
        expect(result.topCategoryPairs.length, 1);
        expect(result.topCategoryPairs[0].count, 2);
      });

      test('sorts pairs by count descending', () {
        final events = [
          createEvent(DateTime(2024, 1, 1), categoryIds: ['a', 'b']),
          createEvent(DateTime(2024, 1, 2), categoryIds: ['a', 'b']),
          createEvent(DateTime(2024, 1, 3), categoryIds: ['a', 'c']),
        ];

        final categories = {
          'a': SexualActivityCategory(id: 'a', name: 'A'),
          'b': SexualActivityCategory(id: 'b', name: 'B'),
          'c': SexualActivityCategory(id: 'c', name: 'C'),
        };

        final result = CoOccurrenceCalculator.calculate(
          events,
          activityCategories: categories,
          sexualActivities: {},
        );

        // a+b appears twice, a+c appears once
        expect(result.topCategoryPairs.length, 2);
        expect(result.topCategoryPairs[0].count, 2);
        expect(result.topCategoryPairs[1].count, 1);
      });

      test('uses Unknown for missing category/activity names', () {
        // Need at least 2 categories/activities to form a pair
        final events = [
          createEvent(
            DateTime(2024, 1, 1),
            categoryIds: ['unknown-category-1', 'unknown-category-2'],
            activityIds: ['unknown-activity-1', 'unknown-activity-2'],
          ),
        ];

        final result = CoOccurrenceCalculator.calculate(
          events,
          activityCategories: {},
          sexualActivities: {},
        );

        expect(result.topCategoryPairs.isNotEmpty, true);
        expect(result.topCategoryPairs[0].name1, 'Unknown');
        expect(result.topCategoryPairs[0].name2, 'Unknown');
        expect(result.topActivityPairs.isNotEmpty, true);
        expect(result.topActivityPairs[0].name1, 'Unknown');
        expect(result.topActivityPairs[0].name2, 'Unknown');
      });

      test('handles multiple categories and activities in single event', () {
        final events = [
          createEvent(
            DateTime(2024, 1, 1),
            categoryIds: ['kissing', 'foreplay', 'sex'],
            activityIds: ['oral', 'vaginal', 'anal'],
          ),
        ];

        final categories = {
          'kissing': SexualActivityCategory(id: 'kissing', name: 'Kissing'),
          'foreplay': SexualActivityCategory(id: 'foreplay', name: 'Foreplay'),
          'sex': SexualActivityCategory(id: 'sex', name: 'Sex'),
        };

        final activities = {
          'oral': SexualActivity(id: 'oral', name: 'Oral'),
          'vaginal': SexualActivity(id: 'vaginal', name: 'Vaginal'),
          'anal': SexualActivity(id: 'anal', name: 'Anal'),
        };

        final result = CoOccurrenceCalculator.calculate(
          events,
          activityCategories: categories,
          sexualActivities: activities,
        );

        // 3 categories = 3 choose 2 = 3 pairs
        expect(result.topCategoryPairs.length, 3);
        // 3 activities = 3 choose 2 = 3 pairs
        expect(result.topActivityPairs.length, 3);
      });

      test('does not create pairs for single category/activity events', () {
        final events = [
          createEvent(
            DateTime(2024, 1, 1),
            categoryIds: ['solo'],
            activityIds: ['masturbation'],
          ),
        ];

        final result = CoOccurrenceCalculator.calculate(
          events,
          activityCategories: {},
          sexualActivities: {},
        );

        expect(result.topCategoryPairs, isEmpty);
        expect(result.topActivityPairs, isEmpty);
      });

      test('handles multiple events with different pairs', () {
        final events = [
          createEvent(DateTime(2024, 1, 1), categoryIds: ['a', 'b']),
          createEvent(DateTime(2024, 1, 2), categoryIds: ['b', 'c']),
          createEvent(DateTime(2024, 1, 3), categoryIds: ['a', 'c']),
        ];

        final categories = {
          'a': SexualActivityCategory(id: 'a', name: 'A'),
          'b': SexualActivityCategory(id: 'b', name: 'B'),
          'c': SexualActivityCategory(id: 'c', name: 'C'),
        };

        final result = CoOccurrenceCalculator.calculate(
          events,
          activityCategories: categories,
          sexualActivities: {},
        );

        // Each pair appears once, sorted by count (all 1)
        expect(result.topCategoryPairs.length, 3);
        // First pair should be alphabetically first (a|b since sorted)
        expect(result.topCategoryPairs[0].count, 1);
      });
    });
  });
}
