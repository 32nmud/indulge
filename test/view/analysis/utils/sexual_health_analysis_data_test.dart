import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/analysis/models/sexual_health_analysis_data.dart';

void main() {
  group('SexualHealthAnalysisData', () {
    group('riskLevel', () {
      test('returns Low for risk score < 20', () {
        final data = _createData(riskScore: 0);
        expect(data.riskLevel, 'Low');
      });

      test('returns Low for risk score 19', () {
        final data = _createData(riskScore: 19);
        expect(data.riskLevel, 'Low');
      });

      test('returns Moderate for risk score 20-49', () {
        final data = _createData(riskScore: 20);
        expect(data.riskLevel, 'Moderate');
      });

      test('returns Moderate for risk score 49', () {
        final data = _createData(riskScore: 49);
        expect(data.riskLevel, 'Moderate');
      });

      test('returns High for risk score 50-74', () {
        final data = _createData(riskScore: 50);
        expect(data.riskLevel, 'High');
      });

      test('returns Very High for risk score 75+', () {
        final data = _createData(riskScore: 75);
        expect(data.riskLevel, 'Very High');
      });
    });

    group('riskDescription', () {
      test('returns "No test data available" when hasValidData is false', () {
        final data = _createData(hasValidData: false);
        expect(data.riskDescription, 'No test data available');
      });

      test('returns "No STI tests recorded" when testDates is empty', () {
        final data = _createData(hasValidData: true, testDates: []);
        expect(data.riskDescription, 'No STI tests recorded');
      });

      test('returns "No sexual activity in this period" when no events', () {
        final data = _createData(
          hasValidData: true,
          testDates: [DateTime.now()],
          eventCountInPeriod: 0,
        );
        expect(data.riskDescription, 'No sexual activity in this period');
      });

      test('returns description with event and partner count', () {
        final data = _createData(
          hasValidData: true,
          testDates: [DateTime.now()],
          eventCountInPeriod: 5,
          uniquePartnersInPeriod: 2,
          periodStartDate: DateTime(2024, 1, 1),
          periodEndDate: DateTime(2024, 1, 31),
        );
        expect(data.riskDescription, contains('5 events'));
        expect(data.riskDescription, contains('2 partners'));
      });
    });

    group('testedPositive', () {
      test('returns false when positiveTests is empty', () {
        final data = _createData(positiveTests: const []);
        expect(data.testedPositive, false);
      });
    });

    group('daysUntilNextTest', () {
      test('returns 0 when nextRecommendedTestDate is null', () {
        final data = _createData(nextRecommendedTestDate: null);
        expect(data.daysUntilNextTest, 0);
      });

      test('returns positive days when test is in the future', () {
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final data = _createData(nextRecommendedTestDate: futureDate);
        expect(data.daysUntilNextTest, closeTo(30, 1));
      });

      test('returns negative days when test is overdue', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 10));
        final data = _createData(nextRecommendedTestDate: pastDate);
        expect(data.daysUntilNextTest, closeTo(-10, 1));
      });
    });

    group('isOverdueForTesting', () {
      test('returns false when daysUntilNextTest is positive', () {
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final data = _createData(nextRecommendedTestDate: futureDate);
        expect(data.isOverdueForTesting, false);
      });

      test('returns true when daysUntilNextTest is negative', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 10));
        final data = _createData(nextRecommendedTestDate: pastDate);
        expect(data.isOverdueForTesting, true);
      });

      test('returns false when daysUntilNextTest is 0', () {
        final today = DateTime.now();
        final data = _createData(nextRecommendedTestDate: today);
        expect(data.isOverdueForTesting, false);
      });
    });

    group('periodLabel', () {
      test('returns "No tests" when testDates is empty', () {
        final data = _createData(testDates: []);
        expect(data.periodLabel, 'No tests');
      });

      test('returns "Most Recent Test" when selectedTestIndex is 0', () {
        final data = _createData(
          testDates: [DateTime.now()],
          selectedTestIndex: 0,
        );
        expect(data.periodLabel, 'Most Recent Test');
      });

      test('returns "2nd Most Recent" when selectedTestIndex is 1', () {
        final data = _createData(
          testDates: [DateTime.now(), DateTime.now()],
          selectedTestIndex: 1,
        );
        expect(data.periodLabel, '2nd Most Recent');
      });

      test('returns ordinal for higher indices', () {
        final data = _createData(
          testDates: List.generate(5, (_) => DateTime.now()),
          selectedTestIndex: 4,
        );
        expect(data.periodLabel, '5th Most Recent');
      });
    });

    group('empty factory', () {
      test('creates data with empty test dates', () {
        final data = SexualHealthAnalysisData.empty();
        expect(data.testDates, isEmpty);
        expect(data.hasValidData, false);
      });
    });

    group('STI and Health risk counts', () {
      test('stores stiRiskCountInPeriod correctly', () {
        final data = _createData(stiRiskCountInPeriod: 5);
        expect(data.stiRiskCountInPeriod, 5);
      });

      test('stores healthRiskCountInPeriod correctly', () {
        final data = _createData(healthRiskCountInPeriod: 3);
        expect(data.healthRiskCountInPeriod, 3);
      });

      test('stores combined riskyActivityCountInPeriod correctly', () {
        final data = _createData(riskyActivityCountInPeriod: 8);
        expect(data.riskyActivityCountInPeriod, 8);
      });

      test('stores safeActivityCountInPeriod correctly', () {
        final data = _createData(safeActivityCountInPeriod: 10);
        expect(data.safeActivityCountInPeriod, 10);
      });

      test('default values are 0', () {
        final data = _createData();
        expect(data.stiRiskCountInPeriod, 0);
        expect(data.healthRiskCountInPeriod, 0);
        expect(data.riskyActivityCountInPeriod, 0);
        expect(data.safeActivityCountInPeriod, 0);
      });
    });
  });

  group('PartnerNotificationInfo', () {
    test('displayName returns "Anonymous Partner" for anonymous', () {
      const info = PartnerNotificationInfo(
        partnerId: 'anonymous',
        isAnonymous: true,
        eventCount: 1,
      );
      expect(info.displayName, 'Anonymous Partner');
    });

    test('displayName returns partnerName when provided', () {
      const info = PartnerNotificationInfo(
        partnerId: 'person-1',
        partnerName: 'John',
        isAnonymous: false,
        eventCount: 1,
      );
      expect(info.displayName, 'John');
    });

    test(
      'displayName returns "Unknown Partner" when not anonymous and no name',
      () {
        const info = PartnerNotificationInfo(
          partnerId: 'person-1',
          isAnonymous: false,
          eventCount: 1,
        );
        expect(info.displayName, 'Unknown Partner');
      },
    );
  });
}

// Helper function to create test data
SexualHealthAnalysisData _createData({
  List<DateTime>? testDates,
  int selectedTestIndex = 0,
  DateTime? periodStartDate,
  DateTime? periodEndDate,
  int riskScore = 0,
  bool hasValidData = true,
  int eventCountInPeriod = 0,
  int uniquePartnersInPeriod = 0,
  int stiRiskCountInPeriod = 0,
  int healthRiskCountInPeriod = 0,
  int riskyActivityCountInPeriod = 0,
  int safeActivityCountInPeriod = 0,
  List<ClinicalTestResult>? positiveTests,
  DateTime? nextRecommendedTestDate,
}) {
  return SexualHealthAnalysisData(
    testDates: testDates ?? [DateTime.now()],
    selectedTestIndex: selectedTestIndex,
    periodStartDate: periodStartDate ?? DateTime.now(),
    periodEndDate: periodEndDate ?? DateTime.now(),
    riskScore: riskScore,
    hasValidData: hasValidData,
    eventCountInPeriod: eventCountInPeriod,
    uniquePartnersInPeriod: uniquePartnersInPeriod,
    stiRiskCountInPeriod: stiRiskCountInPeriod,
    healthRiskCountInPeriod: healthRiskCountInPeriod,
    riskyActivityCountInPeriod: riskyActivityCountInPeriod,
    safeActivityCountInPeriod: safeActivityCountInPeriod,
    positiveTests: positiveTests ?? const [],
    nextRecommendedTestDate: nextRecommendedTestDate,
  );
}
