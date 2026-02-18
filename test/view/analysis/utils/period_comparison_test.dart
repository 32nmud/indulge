import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/view/analysis/models/period_comparison.dart';

void main() {
  group('PeriodComparison', () {
    group('calculate', () {
      test('returns zero when both periods have no events', () {
        final result = PeriodComparison.calculate(0, 0);
        expect(result.currentPeriodCount, 0);
        expect(result.previousPeriodCount, 0);
        expect(result.percentageChange, 0.0);
        expect(result.isIncrease, false);
      });

      test('returns 100 percent increase when previous was zero', () {
        final result = PeriodComparison.calculate(5, 0);
        expect(result.percentageChange, 100.0);
        expect(result.isIncrease, true);
      });

      test('calculates correct percentage increase', () {
        final result = PeriodComparison.calculate(10, 5);
        expect(result.percentageChange, 100.0);
        expect(result.isIncrease, true);
      });

      test('calculates correct percentage decrease', () {
        final result = PeriodComparison.calculate(5, 10);
        expect(result.percentageChange, 50.0);
        expect(result.isIncrease, false);
      });

      test('returns zero when counts are equal', () {
        final result = PeriodComparison.calculate(7, 7);
        expect(result.percentageChange, 0.0);
        expect(result.isIncrease, false);
      });

      test('handles large numbers', () {
        final result = PeriodComparison.calculate(1000, 500);
        expect(result.percentageChange, 100.0);
        expect(result.isIncrease, true);
      });
    });
  });
}
