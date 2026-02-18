class PeriodComparison {
  final int currentPeriodCount;
  final int previousPeriodCount;
  final double percentageChange;
  final bool isIncrease;

  const PeriodComparison({
    required this.currentPeriodCount,
    required this.previousPeriodCount,
    required this.percentageChange,
    required this.isIncrease,
  });

  static PeriodComparison calculate(int current, int previous) {
    if (previous == 0) {
      return PeriodComparison(
        currentPeriodCount: current,
        previousPeriodCount: previous,
        percentageChange: current > 0 ? 100.0 : 0.0,
        isIncrease: current > previous,
      );
    }

    final change = ((current - previous) / previous) * 100;
    return PeriodComparison(
      currentPeriodCount: current,
      previousPeriodCount: previous,
      percentageChange: change.abs(),
      isIncrease: current > previous,
    );
  }
}
