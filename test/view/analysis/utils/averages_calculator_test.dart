import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/analysis/utils/calculator_utils/averages_calculator.dart';
import 'package:indulge/view/analysis/models/analysis_event_type.dart';

void main() {
  group('AveragesCalculator', () {
    /// Helper to create a minimal SexualEvent with just a date.
    SexualEvent createEvent(
      DateTime date, {
      List<String> partnerIds = const [],
    }) {
      // Create activities with the given partner IDs
      final activities = <EventActivity>[];

      for (final partnerId in partnerIds) {
        activities.add(
          EventActivity(
            category: const Reference(
              reference: 'activity-kiss',
              resourceType: 'SexualActivity',
            ),
            participants: [
              ActivityParticipant(
                participant: const Reference(
                  reference: 'me',
                  resourceType: 'Person',
                ),
                activityCounts: [],
              ),
              ActivityParticipant(
                participant: Reference(
                  reference: partnerId,
                  resourceType: 'Person',
                ),
                activityCounts: [],
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
      test('returns zero averages for empty events list', () {
        final result = AveragesCalculator.calculate(
          sortedEvents: [],
          totalActivities: 0,
          eventsThisYear: 0,
          dayOfWeekCounts: {},
          dayOfWeekCountsByType: {},
          eventPartnerCounts: {},
          eventPropertyCounts: {},
          eventActionablePropertyCounts: {},
          eventGearPropertyCounts: {},
          eventActivityCounts: {},
          thisYearStart: DateTime.now().subtract(const Duration(days: 365)),
        );

        expect(result.averageEventsPerWeek, 0.0);
        expect(result.averageEventsPerMonth, 0.0);
        expect(result.averageActivitiesPerWeek, 0.0);
        expect(result.averageActivitiesPerMonth, 0.0);
        expect(result.averagePartnersPerEvent, 0.0);
        expect(result.averageActivitiesPerEvent, 0.0);
        expect(result.averageSexualActivitiesPerEvent, 0.0);
      });

      test('calculates average events per week correctly', () {
        final now = DateTime.now();
        final thisYearStart = DateTime(now.year, 1, 1);

        // Create 7 events (one per week over 7 weeks)
        final events = List.generate(
          7,
          (i) => createEvent(thisYearStart.add(Duration(days: i * 7))),
        );

        final result = AveragesCalculator.calculate(
          sortedEvents: events,
          totalActivities: 7,
          eventsThisYear: 7,
          dayOfWeekCounts: {DateTime.now().weekday: 7},
          dayOfWeekCountsByType: {
            AnalysisEventType.couple: {DateTime.now().weekday: 7},
          },
          eventPartnerCounts: {1},
          eventPropertyCounts: {1},
          eventActionablePropertyCounts: {},
          eventGearPropertyCounts: {},
          eventActivityCounts: {1},
          thisYearStart: thisYearStart,
        );

        expect(result.averageEventsPerWeek, closeTo(1.0, 0.1));
        expect(result.averageActivitiesPerWeek, closeTo(1.0, 0.1));
      });

      test('calculates average events per month correctly', () {
        final now = DateTime.now();
        final thisYearStart = DateTime(now.year, 1, 1);

        // Create 12 events (one per month over 12 months)
        final events = List.generate(
          12,
          (i) => createEvent(thisYearStart.add(Duration(days: i * 30))),
        );

        final result = AveragesCalculator.calculate(
          sortedEvents: events,
          totalActivities: 12,
          eventsThisYear: 12,
          dayOfWeekCounts: {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 1, 7: 1},
          dayOfWeekCountsByType: {
            AnalysisEventType.couple: {
              1: 2,
              2: 2,
              3: 2,
              4: 2,
              5: 2,
              6: 1,
              7: 1,
            },
          },
          eventPartnerCounts: {1},
          eventPropertyCounts: {1},
          eventActionablePropertyCounts: {},
          eventGearPropertyCounts: {},
          eventActivityCounts: {1},
          thisYearStart: thisYearStart,
        );

        expect(result.averageEventsPerMonth, closeTo(1.0, 0.2));
      });

      test('calculates average partners per event correctly', () {
        final events = <SexualEvent>[];

        // Event with 1 partner
        events.add(createEvent(DateTime(2024, 1, 1), partnerIds: ['partner1']));
        // Event with 2 partners
        events.add(
          createEvent(
            DateTime(2024, 1, 2),
            partnerIds: ['partner1', 'partner2'],
          ),
        );
        // Event with 3 partners
        events.add(
          createEvent(
            DateTime(2024, 1, 3),
            partnerIds: ['partner1', 'partner2', 'partner3'],
          ),
        );

        final result = AveragesCalculator.calculate(
          sortedEvents: events,
          totalActivities: 6, // 1 + 2 + 3 partner activities
          eventsThisYear: 3,
          dayOfWeekCounts: {1: 1, 2: 1, 3: 1},
          dayOfWeekCountsByType: {},
          eventPartnerCounts: {1, 2, 3},
          eventPropertyCounts: {1, 2, 3},
          eventActionablePropertyCounts: {},
          eventGearPropertyCounts: {},
          eventActivityCounts: {1, 2, 3},
          thisYearStart: DateTime(2024, 1, 1),
        );

        // (1 + 2 + 3) / 3 = 2
        expect(result.averagePartnersPerEvent, closeTo(2.0, 0.001));
      });

      test('calculates average activities per event correctly', () {
        final events = <SexualEvent>[];

        // Event with 2 activities
        events.add(createEvent(DateTime(2024, 1, 1), partnerIds: ['p1']));
        events.add(createEvent(DateTime(2024, 1, 1), partnerIds: ['p1']));
        // Event with 3 activities
        events.add(
          createEvent(DateTime(2024, 1, 2), partnerIds: ['p1', 'p1', 'p1']),
        );
        events.add(createEvent(DateTime(2024, 1, 2), partnerIds: ['p1']));
        events.add(createEvent(DateTime(2024, 1, 2), partnerIds: ['p1']));

        final result = AveragesCalculator.calculate(
          sortedEvents: events,
          totalActivities: 5,
          eventsThisYear: 2,
          dayOfWeekCounts: {1: 1, 2: 1},
          dayOfWeekCountsByType: {},
          eventPartnerCounts: {1},
          eventPropertyCounts: {2, 3},
          eventActionablePropertyCounts: {},
          eventGearPropertyCounts: {},
          eventActivityCounts: {2, 3},
          thisYearStart: DateTime(2024, 1, 1),
        );

        // (2 + 3) / 2 = 2.5
        expect(result.averageActivitiesPerEvent, closeTo(2.5, 0.001));
      });

      test('handles empty eventPartnerCounts gracefully', () {
        final result = AveragesCalculator.calculate(
          sortedEvents: [],
          totalActivities: 0,
          eventsThisYear: 0,
          dayOfWeekCounts: {},
          dayOfWeekCountsByType: {},
          eventPartnerCounts: {}, // Empty set
          eventPropertyCounts: {},
          eventActionablePropertyCounts: {},
          eventGearPropertyCounts: {},
          eventActivityCounts: {},
          thisYearStart: DateTime.now(),
        );

        expect(result.averagePartnersPerEvent, 0.0);
        expect(result.averageActivitiesPerEvent, 0.0);
        expect(result.averageSexualActivitiesPerEvent, 0.0);
      });

      test('returns averageEventsPerDayOfWeek for all days of week', () {
        final result = AveragesCalculator.calculate(
          sortedEvents: [],
          totalActivities: 0,
          eventsThisYear: 0,
          dayOfWeekCounts: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0},
          dayOfWeekCountsByType: {},
          eventPartnerCounts: {},
          eventPropertyCounts: {},
          eventActionablePropertyCounts: {},
          eventGearPropertyCounts: {},
          eventActivityCounts: {},
          thisYearStart: DateTime(2024, 1, 1),
        );

        // Should have entries for all 7 days
        expect(result.averageEventsPerDayOfWeek.length, 7);
        expect(result.averageEventsPerDayOfWeek.containsKey(1), true); // Monday
        expect(result.averageEventsPerDayOfWeek.containsKey(7), true); // Sunday
      });

      test('returns averageDayOfWeekCountsByType for all event types', () {
        final result = AveragesCalculator.calculate(
          sortedEvents: [],
          totalActivities: 0,
          eventsThisYear: 0,
          dayOfWeekCounts: {},
          dayOfWeekCountsByType: {},
          eventPartnerCounts: {},
          eventPropertyCounts: {},
          eventActionablePropertyCounts: {},
          eventGearPropertyCounts: {},
          eventActivityCounts: {},
          thisYearStart: DateTime(2024, 1, 1),
        );

        // Should have entries for all event types
        expect(
          result.averageDayOfWeekCountsByType.containsKey(
            AnalysisEventType.solo,
          ),
          true,
        );
        expect(
          result.averageDayOfWeekCountsByType.containsKey(
            AnalysisEventType.couple,
          ),
          true,
        );
        expect(
          result.averageDayOfWeekCountsByType.containsKey(
            AnalysisEventType.group,
          ),
          true,
        );
      });

      test(
        'handles windowStart adjustment when first event is after thisYearStart',
        () {
          final thisYearStart = DateTime(2024, 1, 1);

          // First event is March 1st, not January
          final events = [
            createEvent(DateTime(2024, 3, 1)),
            createEvent(DateTime(2024, 3, 2)),
            createEvent(DateTime(2024, 3, 3)),
          ];

          final result = AveragesCalculator.calculate(
            sortedEvents: events,
            totalActivities: 3,
            eventsThisYear: 3,
            dayOfWeekCounts: {6: 3}, // All on Friday (March 1, 2, 3 2024)
            dayOfWeekCountsByType: {
              AnalysisEventType.couple: {6: 3},
            },
            eventPartnerCounts: {1},
            eventPropertyCounts: {1},
          eventActionablePropertyCounts: {},
          eventGearPropertyCounts: {},
            eventActivityCounts: {1},
            thisYearStart: thisYearStart,
          );

          // Should calculate based on actual window (March) not thisYearStart (January)
          expect(result.averageEventsPerWeek, greaterThan(0));
        },
      );
    });
  });
}
