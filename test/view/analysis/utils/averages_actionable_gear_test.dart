import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/view/analysis/utils/calculator_utils/averages_calculator.dart';

void main() {
  group('AveragesCalculator — actionable vs gear split', () {
    /// Shared thisYearStart used across tests.
    final thisYearStart = DateTime(2024, 1, 1);

    test('averageActionableActivitiesPerEvent is 0 when set is empty', () {
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
        thisYearStart: thisYearStart,
      );

      expect(result.averageActionableActivitiesPerEvent, 0.0);
    });

    test('averageGearPerEvent is 0 when set is empty', () {
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
        thisYearStart: thisYearStart,
      );

      expect(result.averageGearPerEvent, 0.0);
    });

    test('averageActionableActivitiesPerEvent computed from set', () {
      // Three events with 1, 3, and 5 actionable activities respectively.
      // Average = (1 + 3 + 5) / 3 = 3.0
      final result = AveragesCalculator.calculate(
        sortedEvents: [],
        totalActivities: 9,
        eventsThisYear: 3,
        dayOfWeekCounts: {},
        dayOfWeekCountsByType: {},
        eventPartnerCounts: {},
        eventPropertyCounts: {1, 3, 5},
        eventActionablePropertyCounts: {1, 3, 5},
        eventGearPropertyCounts: {},
        eventActivityCounts: {1, 3, 5},
        thisYearStart: thisYearStart,
      );

      expect(result.averageActionableActivitiesPerEvent, closeTo(3.0, 0.001));
    });

    test('averageGearPerEvent computed from set', () {
      // Two events with 2 and 4 gear items respectively.
      // Average = (2 + 4) / 2 = 3.0
      final result = AveragesCalculator.calculate(
        sortedEvents: [],
        totalActivities: 6,
        eventsThisYear: 2,
        dayOfWeekCounts: {},
        dayOfWeekCountsByType: {},
        eventPartnerCounts: {},
        eventPropertyCounts: {2, 4},
        eventActionablePropertyCounts: {},
        eventGearPropertyCounts: {2, 4},
        eventActivityCounts: {2, 4},
        thisYearStart: thisYearStart,
      );

      expect(result.averageGearPerEvent, closeTo(3.0, 0.001));
    });

    test('actionable and gear averages are independent of each other', () {
      // 3 events: actionable counts {2, 4, 6}, gear counts {1, 1, 1}
      // averageActionable = (2+4+6)/3 = 4.0
      // averageGear = (1+1+1)/3 = 1.0
      final result = AveragesCalculator.calculate(
        sortedEvents: [],
        totalActivities: 12,
        eventsThisYear: 3,
        dayOfWeekCounts: {},
        dayOfWeekCountsByType: {},
        eventPartnerCounts: {},
        eventPropertyCounts: {2, 4, 6},
        eventActionablePropertyCounts: {2, 4, 6},
        eventGearPropertyCounts: {1},
        eventActivityCounts: {3, 5, 7},
        thisYearStart: thisYearStart,
      );

      expect(result.averageActionableActivitiesPerEvent, closeTo(4.0, 0.001));
      // {1} is a Set so all three entries deduplicate to a single 1:
      // average = 1 / 1 = 1.0
      expect(result.averageGearPerEvent, closeTo(1.0, 0.001));
    });

    test('mixed events: some with gear, some without', () {
      // eventGearPropertyCounts {0, 3}: average = (0+3)/2 = 1.5
      final result = AveragesCalculator.calculate(
        sortedEvents: [],
        totalActivities: 5,
        eventsThisYear: 2,
        dayOfWeekCounts: {},
        dayOfWeekCountsByType: {},
        eventPartnerCounts: {},
        eventPropertyCounts: {2, 3},
        eventActionablePropertyCounts: {2, 3},
        eventGearPropertyCounts: {0, 3},
        eventActivityCounts: {2, 3},
        thisYearStart: thisYearStart,
      );

      expect(result.averageGearPerEvent, closeTo(1.5, 0.001));
    });

    test('single event with only actionable activities', () {
      final result = AveragesCalculator.calculate(
        sortedEvents: [],
        totalActivities: 4,
        eventsThisYear: 1,
        dayOfWeekCounts: {},
        dayOfWeekCountsByType: {},
        eventPartnerCounts: {},
        eventPropertyCounts: {4},
        eventActionablePropertyCounts: {4},
        eventGearPropertyCounts: {},
        eventActivityCounts: {4},
        thisYearStart: thisYearStart,
      );

      expect(result.averageActionableActivitiesPerEvent, closeTo(4.0, 0.001));
      expect(result.averageGearPerEvent, 0.0);
    });

    test('single event with only gear items', () {
      final result = AveragesCalculator.calculate(
        sortedEvents: [],
        totalActivities: 2,
        eventsThisYear: 1,
        dayOfWeekCounts: {},
        dayOfWeekCountsByType: {},
        eventPartnerCounts: {},
        eventPropertyCounts: {2},
        eventActionablePropertyCounts: {},
        eventGearPropertyCounts: {2},
        eventActivityCounts: {2},
        thisYearStart: thisYearStart,
      );

      expect(result.averageActionableActivitiesPerEvent, 0.0);
      expect(result.averageGearPerEvent, closeTo(2.0, 0.001));
    });

    test('both averages are 0 when totals are 0 but events exist', () {
      final result = AveragesCalculator.calculate(
        sortedEvents: [],
        totalActivities: 0,
        eventsThisYear: 5,
        dayOfWeekCounts: {},
        dayOfWeekCountsByType: {},
        eventPartnerCounts: {},
        eventPropertyCounts: {},
        eventActionablePropertyCounts: {},
        eventGearPropertyCounts: {},
        eventActivityCounts: {0},
        thisYearStart: thisYearStart,
      );

      expect(result.averageActionableActivitiesPerEvent, 0.0);
      expect(result.averageGearPerEvent, 0.0);
    });
  });
}
