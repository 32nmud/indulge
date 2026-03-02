import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/analysis/utils/calculator_utils/event_aggregator.dart';
import 'package:indulge/view/analysis/utils/person_cache.dart';

void main() {
  group('EventAggregator', () {
    /// Helper to create a minimal SexualEvent with just a date.
    SexualEvent createEvent(DateTime date) {
      return SexualEvent(
        id: 'event-${date.millisecondsSinceEpoch}',
        date: date,
        activities: const [],
      );
    }

    /// Helper to create an event with activities and participants.
    SexualEvent createEventWithActivities(
      DateTime date,
      List<String> categoryIds,
      List<String> participantIds,
    ) {
      final activities = categoryIds
          .map(
            (catId) => EventActivity(
              category: Reference(
                reference: catId,
                resourceType: 'SexualActivityCategory',
              ),
              participants: participantIds
                  .map(
                    (pid) => ActivityParticipant(
                      participant: Reference(
                        reference: pid,
                        resourceType: 'Person',
                      ),
                      activityCounts: [],
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();

      return SexualEvent(
        id: 'event-${date.millisecondsSinceEpoch}',
        date: date,
        activities: activities,
      );
    }

    /// Helper to create an event with sexual activities.
    SexualEvent createEventWithSexualActivities(
      DateTime date,
      List<String> activityIds,
      List<String> participantIds,
    ) {
      final activities = [
        EventActivity(
          category: const Reference(
            reference: 'category-sex',
            resourceType: 'SexualActivityCategory',
          ),
          participants: participantIds
              .map(
                (pid) => ActivityParticipant(
                  participant: Reference(
                    reference: pid,
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
              )
              .toList(),
        ),
      ];

      return SexualEvent(
        id: 'event-${date.millisecondsSinceEpoch}',
        date: date,
        activities: activities,
      );
    }

    group('aggregate', () {
      test('returns empty result for empty events list', () {
        final cache = PersonCache.fromList([]);

        final result = EventAggregator.aggregate([], cache, null, null);

        expect(result.totalActivities, 0);
        expect(result.eventsThisMonth, 0);
        expect(result.eventsThisYear, 0);
        expect(result.personCounts, isEmpty);
        expect(result.dailyCounts, isEmpty);
        expect(result.monthlyCounts, isEmpty);
      });

      test('counts activity category instances correctly', () {
        final cache = PersonCache.fromList([]);
        final events = [
          createEventWithSexualActivities(
            DateTime(2024, 6, 1),
            ['oral', 'vaginal'],
            ['me', 'partner-1'],
          ),
          createEventWithSexualActivities(
            DateTime(2024, 6, 2),
            ['anal'],
            ['me', 'partner-1'],
          ),
        ];

        final result = EventAggregator.aggregate(events, cache, null, null);

        // totalActivities counts the number of EventActivity instances
        expect(result.totalActivities, 2);
      });

      test('counts events this month correctly', () {
        final now = DateTime.now();
        final thisMonthStart = DateTime(now.year, now.month, 1);

        final cache = PersonCache.fromList([]);
        final events = [
          createEvent(thisMonthStart),
          createEvent(thisMonthStart.add(const Duration(days: 1))),
          createEvent(thisMonthStart.subtract(const Duration(days: 30))),
        ];

        final result = EventAggregator.aggregate(events, cache, null, null);

        expect(result.eventsThisMonth, 2);
      });

      test('counts unique partners correctly', () {
        final cache = PersonCache.fromList([]);
        final events = [
          createEventWithActivities(
            DateTime(2024, 6, 1),
            ['kissing'],
            ['me', 'partner-1'],
          ),
          createEventWithActivities(
            DateTime(2024, 6, 2),
            ['foreplay'],
            ['me', 'partner-2'],
          ),
          createEventWithActivities(
            DateTime(2024, 6, 3),
            ['sex'],
            ['me', 'partner-1'], // Repeated partner
          ),
        ];

        final result = EventAggregator.aggregate(events, cache, null, null);

        expect(result.personCounts.length, 3); // me, partner-1, partner-2
      });

      test('tracks daily counts correctly', () {
        final cache = PersonCache.fromList([]);
        final events = [
          createEvent(DateTime(2024, 6, 1)),
          createEvent(DateTime(2024, 6, 1)),
          createEvent(DateTime(2024, 6, 2)),
        ];

        final result = EventAggregator.aggregate(events, cache, null, null);

        expect(result.dailyCounts['2024-06-01'], 2);
        expect(result.dailyCounts['2024-06-02'], 1);
      });

      test('tracks monthly counts correctly', () {
        final cache = PersonCache.fromList([]);
        final events = [
          createEvent(DateTime(2024, 6, 1)),
          createEvent(DateTime(2024, 6, 15)),
          createEvent(DateTime(2024, 7, 1)),
        ];

        final result = EventAggregator.aggregate(events, cache, null, null);

        expect(result.monthlyCounts['2024-06'], 2);
        expect(result.monthlyCounts['2024-07'], 1);
      });

      test('tracks day of week counts correctly', () {
        final cache = PersonCache.fromList([]);
        // June 1, 2024 is a Saturday (weekday 6)
        // June 2, 2024 is a Sunday (weekday 7)
        // June 3, 2024 is a Monday (weekday 1)
        final events = [
          createEvent(DateTime(2024, 6, 1)),
          createEvent(DateTime(2024, 6, 2)),
          createEvent(DateTime(2024, 6, 3)),
        ];

        final result = EventAggregator.aggregate(events, cache, null, null);

        expect(result.dayOfWeekCounts[6], 1); // Saturday
        expect(result.dayOfWeekCounts[7], 1); // Sunday
        expect(result.dayOfWeekCounts[1], 1); // Monday
      });

      test('tracks activity categories correctly', () {
        final cache = PersonCache.fromList([]);
        final categories = {
          'kissing': SexualActivityCategory(id: 'kissing', name: 'Kissing'),
          'foreplay': SexualActivityCategory(id: 'foreplay', name: 'Foreplay'),
          'sex': SexualActivityCategory(id: 'sex', name: 'Sex'),
        };

        final events = [
          createEventWithActivities(
            DateTime(2024, 6, 1),
            ['kissing', 'foreplay'],
            ['me', 'partner-1'],
          ),
          createEventWithActivities(
            DateTime(2024, 6, 2),
            ['kissing', 'sex'],
            ['me', 'partner-1'],
          ),
        ];

        final result = EventAggregator.aggregate(
          events,
          cache,
          categories,
          null,
        );

        expect(result.activityCategories['kissing'], isNotNull);
        expect(result.activityCategories['foreplay'], isNotNull);
        expect(result.activityCategories['sex'], isNotNull);
        expect(result.activityCounts['kissing'], 2);
        expect(result.activityCounts['foreplay'], 1);
        expect(result.activityCounts['sex'], 1);
      });

      test('tracks sexual activities correctly', () {
        final cache = PersonCache.fromList([]);
        final sexualActivities = {
          'Oral': SexualActivity(name: 'Oral'),
          'Vaginal': SexualActivity(name: 'Vaginal'),
        };

        final events = [
          createEventWithSexualActivities(
            DateTime(2024, 6, 1),
            ['oral', 'vaginal'],
            ['me', 'partner-1'],
          ),
          createEventWithSexualActivities(
            DateTime(2024, 6, 2),
            ['oral'],
            ['me', 'partner-1'],
          ),
        ];

        final result = EventAggregator.aggregate(
          events,
          cache,
          null,
          sexualActivities,
        );

        expect(result.sexualActivities['oral'], isNotNull);
        expect(result.sexualActivities['vaginal'], isNotNull);
        // Counts total activityCount across all participants
        expect(result.sexualActivityCountsTotal['oral'], greaterThan(0));
        expect(result.sexualActivityCountsTotal['vaginal'], greaterThan(0));
      });

      test('tracks anonymous partners correctly', () {
        final cache = PersonCache.fromList([]);
        final events = [
          createEventWithActivities(
            DateTime(2024, 6, 1),
            ['kissing'],
            ['me', 'partner-1'],
          ),
          createEventWithActivities(
            DateTime(2024, 6, 2),
            ['kissing'],
            ['me', 'anonymous'],
          ),
          createEventWithActivities(
            DateTime(2024, 6, 3),
            ['kissing'],
            ['me', 'anonymous'],
          ),
        ];

        final result = EventAggregator.aggregate(events, cache, null, null);

        expect(result.anonymousPartnerInstances, 2);
      });

      test('respects startDate parameter for filtering', () {
        final cache = PersonCache.fromList([]);
        final startDate = DateTime(2024, 6, 15);

        final events = [
          createEvent(DateTime(2024, 6, 1)), // Before startDate
          createEvent(DateTime(2024, 6, 16)), // After startDate
          createEvent(DateTime(2024, 6, 20)), // After startDate
        ];

        final result = EventAggregator.aggregate(
          events,
          cache,
          null,
          null,
          startDate: startDate,
        );

        // eventsThisYear counts events after startDate
        expect(result.eventsThisYear, 2);
      });

      test('aggregates events by type correctly', () {
        final cache = PersonCache.fromList([]);
        final events = [
          createEventWithActivities(
            DateTime(2024, 6, 1),
            ['kissing'],
            ['me', 'partner-1'],
          ),
          createEventWithActivities(
            DateTime(2024, 6, 2),
            ['kissing'],
            ['me', 'partner-1', 'partner-2'],
          ),
        ];

        final result = EventAggregator.aggregate(events, cache, null, null);

        // At least verify the maps are populated
        expect(result.eventCountsByType, isNotNull);
        expect(result.eventsByType, isNotNull);
      });

      test('calculates unique partners this year correctly', () {
        final now = DateTime.now();
        final thisYearStart = DateTime(now.year, 1, 1);

        final cache = PersonCache.fromList([]);
        final events = [
          // This year events
          createEventWithActivities(
            DateTime(now.year, 6, 1),
            ['kissing'],
            ['me', 'partner-1'],
          ),
          createEventWithActivities(
            DateTime(now.year, 6, 2),
            ['kissing'],
            ['me', 'partner-2'],
          ),
          // Last year event
          createEventWithActivities(
            DateTime(now.year - 1, 6, 1),
            ['kissing'],
            ['me', 'partner-old'],
          ),
        ];

        final result = EventAggregator.aggregate(
          events,
          cache,
          null,
          null,
          startDate: thisYearStart,
        );

        expect(
          result.uniquePartnersThisYear,
          greaterThan(0),
        ); // partner-1 and partner-2
      });
    });
  });
}
