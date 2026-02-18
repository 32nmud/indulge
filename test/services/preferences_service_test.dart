import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indulge/services/preferences_service.dart';
import 'package:indulge/view/analysis/widgets/period_comparison/period_comparison_section.dart';
import 'package:indulge/view/analysis/models/analysis_event_type.dart';

void main() {
  group('PreferencesService', () {
    late PreferencesService preferencesService;

    setUp(() async {
      // Set up mock SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      preferencesService = await PreferencesService.build();
    });

    group('initialization', () {
      test('creates service with default values', () async {
        SharedPreferences.setMockInitialValues({});
        final service = await PreferencesService.build();

        expect(service, isNotNull);
        expect(
          service.periodPresetNotifier.value,
          equals(PeriodPreset.lastMonthVsThisMonth),
        );
      });

      test('loads saved period preset', () async {
        SharedPreferences.setMockInitialValues({
          'pref_period_preset': 0,
        });
        final service = await PreferencesService.build();

        expect(
          service.periodPresetNotifier.value,
          equals(PeriodPreset.lastYearVsThisYear),
        );
      });
    });

    group('period preset', () {
      test('getPeriodPreset returns default value', () {
        expect(
          preferencesService.getPeriodPreset(),
          equals(PeriodPreset.lastMonthVsThisMonth),
        );
      });

      test('setPeriodPreset updates value and notifies', () async {
        var notified = false;
        preferencesService.periodPresetNotifier.addListener(
          () => notified = true,
        );

        await preferencesService.setPeriodPreset(
          PeriodPreset.lastWeekVsThisWeek,
        );

        expect(
          preferencesService.getPeriodPreset(),
          equals(PeriodPreset.lastWeekVsThisWeek),
        );
        expect(notified, isTrue);
      });
    });

    group('custom date range', () {
      test('getCustomFirst returns null by default', () {
        expect(preferencesService.getCustomFirst(), isNull);
      });

      test('setCustomFirst updates value', () async {
        final testDate = DateTime(2024, 1, 15);

        await preferencesService.setCustomFirst(testDate);

        expect(preferencesService.getCustomFirst(), equals(testDate));
      });

      test('getCustomSecond returns null by default', () {
        expect(preferencesService.getCustomSecond(), isNull);
      });

      test('setCustomSecond updates value', () async {
        final testDate = DateTime(2024, 12, 31);

        await preferencesService.setCustomSecond(testDate);

        expect(preferencesService.getCustomSecond(), equals(testDate));
      });
    });

    group('activity filter', () {
      test('getActivityFilter returns null by default', () {
        expect(preferencesService.getActivityFilter(), isNull);
      });

      test('setActivityFilter updates value and notifies', () async {
        var notified = false;
        preferencesService.activityFilterNotifier.addListener(
          () => notified = true,
        );

        await preferencesService.setActivityFilter(AnalysisEventType.total);

        expect(
          preferencesService.getActivityFilter(),
          equals(AnalysisEventType.total),
        );
        expect(notified, isTrue);
      });
    });

    group('analysis time window', () {
      test('getAnalysisTimeWindowIndex returns null by default', () {
        expect(preferencesService.getAnalysisTimeWindowIndex(), isNull);
      });

      test('setAnalysisTimeWindowIndex updates value', () async {
        await preferencesService.setAnalysisTimeWindowIndex(2);

        expect(preferencesService.getAnalysisTimeWindowIndex(), equals(2));
      });
    });

    group('analysis specific year', () {
      test('getAnalysisSpecificYear returns null by default', () {
        expect(preferencesService.getAnalysisSpecificYear(), isNull);
      });

      test('setAnalysisSpecificYear updates value', () async {
        await preferencesService.setAnalysisSpecificYear(2024);

        expect(preferencesService.getAnalysisSpecificYear(), equals(2024));
      });
    });

    group('show pattern settings', () {
      test('getMonthlyShowPattern returns false by default', () {
        expect(preferencesService.getMonthlyShowPattern(), isFalse);
      });

      test('setMonthlyShowPattern updates value and notifies', () async {
        var notified = false;
        preferencesService.monthlyShowPatternNotifier.addListener(
          () => notified = true,
        );

        await preferencesService.setMonthlyShowPattern(true);

        expect(preferencesService.getMonthlyShowPattern(), isTrue);
        expect(notified, isTrue);
      });

      test('getCategoryShowPattern returns false by default', () {
        expect(preferencesService.getCategoryShowPattern(), isFalse);
      });

      test('setCategoryShowPattern updates value', () async {
        await preferencesService.setCategoryShowPattern(true);

        expect(preferencesService.getCategoryShowPattern(), isTrue);
      });

      test('getActivityShowPattern returns false by default', () {
        expect(preferencesService.getActivityShowPattern(), isFalse);
      });

      test('setActivityShowPattern updates value', () async {
        await preferencesService.setActivityShowPattern(true);

        expect(preferencesService.getActivityShowPattern(), isTrue);
      });
    });

    group('auto-add location', () {
      test('getAutoAddLocation returns false by default', () {
        expect(preferencesService.getAutoAddLocation(), isFalse);
      });

      test('setAutoAddLocation updates value and notifies', () async {
        var notified = false;
        preferencesService.autoAddLocationNotifier.addListener(
          () => notified = true,
        );

        await preferencesService.setAutoAddLocation(true);

        expect(preferencesService.getAutoAddLocation(), isTrue);
        expect(notified, isTrue);
      });
    });

    group('category selected IDs', () {
      test('getCategorySelectedIds returns empty list by default', () {
        expect(preferencesService.getCategorySelectedIds(), isEmpty);
      });

      test('setCategorySelectedIds updates value and notifies', () async {
        var notified = false;
        preferencesService.categorySelectedIdsNotifier.addListener(
          () => notified = true,
        );

        await preferencesService.setCategorySelectedIds(['cat1', 'cat2']);

        expect(
          preferencesService.getCategorySelectedIds(),
          equals(['cat1', 'cat2']),
        );
        expect(notified, isTrue);
      });
    });

    group('activity selected IDs', () {
      test('getActivitySelectedIds returns empty list by default', () {
        expect(preferencesService.getActivitySelectedIds(), isEmpty);
      });

      test('setActivitySelectedIds updates value', () async {
        await preferencesService.setActivitySelectedIds(['act1', 'act2']);

        expect(
          preferencesService.getActivitySelectedIds(),
          equals(['act1', 'act2']),
        );
      });
    });

    group('properties category selected IDs', () {
      test(
        'getPropertiesCategorySelectedIds returns empty list by default',
        () {
          expect(
            preferencesService.getPropertiesCategorySelectedIds(),
            isEmpty,
          );
        },
      );

      test('setPropertiesCategorySelectedIds updates value', () async {
        await preferencesService.setPropertiesCategorySelectedIds(['prop1']);

        expect(
          preferencesService.getPropertiesCategorySelectedIds(),
          equals(['prop1']),
        );
      });
    });

    group('partner properties category selected IDs', () {
      test(
        'getPartnerPropertiesCategorySelectedIds returns empty list by default',
        () {
          expect(
            preferencesService.getPartnerPropertiesCategorySelectedIds(),
            isEmpty,
          );
        },
      );

      test('setPartnerPropertiesCategorySelectedIds updates value', () async {
        await preferencesService.setPartnerPropertiesCategorySelectedIds([
          'partner1',
        ]);

        expect(
          preferencesService.getPartnerPropertiesCategorySelectedIds(),
          equals(['partner1']),
        );
      });
    });

    group('clearAll', () {
      test('clears all preferences and resets to defaults', () async {
        // Set some values first
        await preferencesService.setPeriodPreset(
          PeriodPreset.lastWeekVsThisWeek,
        );
        await preferencesService.setCustomFirst(DateTime(2024, 1, 1));
        await preferencesService.setAutoAddLocation(true);

        // Clear all
        await preferencesService.clearAll();

        // Verify defaults are restored
        expect(
          preferencesService.getPeriodPreset(),
          equals(PeriodPreset.lastMonthVsThisMonth),
        );
        expect(preferencesService.getCustomFirst(), isNull);
        expect(preferencesService.getAutoAddLocation(), isFalse);
      });
    });

    group('value notifiers', () {
      test('periodPresetNotifier is a ValueNotifier', () {
        expect(
          preferencesService.periodPresetNotifier,
          isA<ValueNotifier<PeriodPreset>>(),
        );
      });

      test('customFirstNotifier is a ValueNotifier', () {
        expect(
          preferencesService.customFirstNotifier,
          isA<ValueNotifier<DateTime?>>(),
        );
      });

      test('customSecondNotifier is a ValueNotifier', () {
        expect(
          preferencesService.customSecondNotifier,
          isA<ValueNotifier<DateTime?>>(),
        );
      });

      test('activityFilterNotifier is a ValueNotifier', () {
        expect(
          preferencesService.activityFilterNotifier,
          isA<ValueNotifier<AnalysisEventType?>>(),
        );
      });

      test('analysisTimeWindowNotifier is a ValueNotifier', () {
        expect(
          preferencesService.analysisTimeWindowNotifier,
          isA<ValueNotifier<int?>>(),
        );
      });

      test('monthlyShowPatternNotifier is a ValueNotifier', () {
        expect(
          preferencesService.monthlyShowPatternNotifier,
          isA<ValueNotifier<bool>>(),
        );
      });

      test('autoAddLocationNotifier is a ValueNotifier', () {
        expect(
          preferencesService.autoAddLocationNotifier,
          isA<ValueNotifier<bool>>(),
        );
      });
    });
  });
}
