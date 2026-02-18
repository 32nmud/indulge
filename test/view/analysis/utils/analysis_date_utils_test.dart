import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/view/analysis/utils/calculator_utils/analysis_date_utils.dart';

void main() {
  group('AnalysisDateUtils', () {
    group('getWeekKey', () {
      test(
        'returns correct ISO week key for a date in the middle of a year',
        () {
          // January 4, 2024 is a Thursday and falls in week 1
          expect(getWeekKey(DateTime(2024, 1, 4)), '2024-W01');

          // January 8, 2024 is a Monday and falls in week 2
          expect(getWeekKey(DateTime(2024, 1, 8)), '2024-W02');
        },
      );

      test('returns correct week key for dates in December', () {
        // December 30, 2024 is a Monday - week 1 of 2025
        expect(getWeekKey(DateTime(2024, 12, 30)), '2025-W01');
      });

      test('returns correct week key for dates in early January', () {
        // January 1, 2023 was a Sunday, falls in week 52 of 2022
        expect(getWeekKey(DateTime(2023, 1, 1)), '2022-W52');

        // January 1, 2024 was a Monday, falls in week 1 of 2024
        expect(getWeekKey(DateTime(2024, 1, 1)), '2024-W01');
      });

      test('returns correct week key for mid-year dates', () {
        expect(getWeekKey(DateTime(2024, 6, 15)), '2024-W24');
        expect(getWeekKey(DateTime(2024, 7, 4)), '2024-W27');
      });

      test('handles leap year dates correctly', () {
        // February 29, 2024 falls on a Thursday
        expect(getWeekKey(DateTime(2024, 2, 29)), '2024-W09');
      });

      test('pads week number with leading zero', () {
        // Week 1-9 should be padded
        expect(getWeekKey(DateTime(2024, 1, 4)), '2024-W01');
        expect(getWeekKey(DateTime(2024, 1, 8)), '2024-W02');
        expect(getWeekKey(DateTime(2024, 3, 4)), '2024-W10');
      });
    });

    group('dateKey', () {
      test('formats date as yyyy-MM-dd', () {
        expect(dateKey(DateTime(2024, 1, 1)), '2024-01-01');
        expect(dateKey(DateTime(2024, 12, 31)), '2024-12-31');
        expect(dateKey(DateTime(2024, 6, 15)), '2024-06-15');
      });

      test('pads single-digit month and day with leading zeros', () {
        expect(dateKey(DateTime(2024, 1, 5)), '2024-01-05');
        expect(dateKey(DateTime(2024, 5, 1)), '2024-05-01');
        expect(dateKey(DateTime(2024, 5, 9)), '2024-05-09');
      });
    });

    group('monthKey', () {
      test('formats date as yyyy-MM', () {
        expect(monthKey(DateTime(2024, 1, 1)), '2024-01');
        expect(monthKey(DateTime(2024, 12, 31)), '2024-12');
        expect(monthKey(DateTime(2024, 6, 15)), '2024-06');
      });

      test('pads single-digit month with leading zero', () {
        expect(monthKey(DateTime(2024, 1, 15)), '2024-01');
        expect(monthKey(DateTime(2024, 5, 1)), '2024-05');
        expect(monthKey(DateTime(2024, 9, 30)), '2024-09');
      });

      test('ignores day component', () {
        // All days in the same month should return the same key
        expect(monthKey(DateTime(2024, 6, 1)), monthKey(DateTime(2024, 6, 15)));
        expect(monthKey(DateTime(2024, 6, 1)), monthKey(DateTime(2024, 6, 30)));
      });
    });
  });
}
