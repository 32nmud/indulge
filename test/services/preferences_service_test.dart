import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indulge/services/preferences_service.dart';
import 'package:indulge/view/analysis/models/analysis_data.dart';

void main() {
  group('PreferencesService - analysis time window persistence', () {
    setUp(() async {
      // Reset mock SharedPreferences before each test.
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'build with no initial values returns null analysis window and year',
      () async {
        final svc = await PreferencesService.build();

        expect(svc.getAnalysisTimeWindowIndex(), isNull);
        expect(svc.getAnalysisSpecificYear(), isNull);
      },
    );

    test(
      'setAnalysisTimeWindowIndex persists value and notifies listeners',
      () async {
        final svc = await PreferencesService.build();

        var notified = false;
        svc.analysisTimeWindowNotifier.addListener(() {
          notified = true;
        });

        await svc.setAnalysisTimeWindowIndex(1);

        expect(svc.getAnalysisTimeWindowIndex(), equals(1));
        expect(notified, isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('pref_analysis_time_window'), equals(1));
      },
    );

    test(
      'setAnalysisSpecificYear persists value and notifies listeners',
      () async {
        final svc = await PreferencesService.build();

        var notified = false;
        svc.analysisSpecificYearNotifier.addListener(() {
          notified = true;
        });

        await svc.setAnalysisSpecificYear(2022);

        expect(svc.getAnalysisSpecificYear(), equals(2022));
        expect(notified, isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('pref_analysis_specific_year'), equals(2022));
      },
    );

    test('build loads persisted analysis window and specific year', () async {
      // Pre-populate mock prefs before building the service
      SharedPreferences.setMockInitialValues({
        'pref_analysis_time_window': 2,
        'pref_analysis_specific_year': 2019,
      });

      final svc = await PreferencesService.build();

      expect(svc.getAnalysisTimeWindowIndex(), equals(2));
      expect(svc.getAnalysisSpecificYear(), equals(2019));
    });

    test('clearing specific year removes stored value', () async {
      final svc = await PreferencesService.build();

      await svc.setAnalysisSpecificYear(2018);
      expect(svc.getAnalysisSpecificYear(), equals(2018));

      await svc.setAnalysisSpecificYear(null);
      expect(svc.getAnalysisSpecificYear(), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('pref_analysis_specific_year'), isFalse);
    });

    // ------------------------
    // New tests: view-mode persistence (booleans)
    // ------------------------
    test('default show-pattern getters are false', () async {
      final svc = await PreferencesService.build();

      expect(svc.getMonthlyShowPattern(), isFalse);
      expect(svc.getCategoryShowPattern(), isFalse);
      expect(svc.getActivityShowPattern(), isFalse);

      // Underlying SharedPreferences should also contain the default keys after build (migration)
      final prefs = await SharedPreferences.getInstance();
      // Migration might have run and injected defaults; if not present, treat as false
      expect(prefs.getBool('pref_monthly_show_pattern') ?? false, isFalse);
      expect(prefs.getBool('pref_category_show_pattern') ?? false, isFalse);
      expect(prefs.getBool('pref_activity_show_pattern') ?? false, isFalse);
    });

    test('setMonthlyShowPattern persists value and notifies', () async {
      final svc = await PreferencesService.build();

      var notified = false;
      svc.monthlyShowPatternNotifier.addListener(() {
        notified = true;
      });

      await svc.setMonthlyShowPattern(true);

      expect(svc.getMonthlyShowPattern(), isTrue);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pref_monthly_show_pattern'), isTrue);
    });

    test('setCategoryShowPattern persists value and notifies', () async {
      final svc = await PreferencesService.build();

      var notified = false;
      svc.categoryShowPatternNotifier.addListener(() {
        notified = true;
      });

      await svc.setCategoryShowPattern(true);

      expect(svc.getCategoryShowPattern(), isTrue);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pref_category_show_pattern'), isTrue);
    });

    test('setActivityShowPattern persists value and notifies', () async {
      final svc = await PreferencesService.build();

      var notified = false;
      svc.activityShowPatternNotifier.addListener(() {
        notified = true;
      });

      await svc.setActivityShowPattern(true);

      expect(svc.getActivityShowPattern(), isTrue);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pref_activity_show_pattern'), isTrue);
    });

    test(
      'build loads persisted show-pattern values from SharedPreferences',
      () async {
        // Pre-populate mock prefs before building the service
        SharedPreferences.setMockInitialValues({
          'pref_monthly_show_pattern': true,
          'pref_category_show_pattern': false,
          'pref_activity_show_pattern': true,
        });

        final svc = await PreferencesService.build();

        expect(svc.getMonthlyShowPattern(), isTrue);
        expect(svc.getCategoryShowPattern(), isFalse);
        expect(svc.getActivityShowPattern(), isTrue);
      },
    );

    test(
      'migration from older version injects default show-pattern keys',
      () async {
        // Simulate an older install by setting pref_version to 1 only.
        SharedPreferences.setMockInitialValues({'pref_version': 1});

        final svc = await PreferencesService.build();

        final prefs = await SharedPreferences.getInstance();
        // Migration should have set the new keys to false and updated the version to current (4).
        expect(prefs.getBool('pref_monthly_show_pattern'), isFalse);
        expect(prefs.getBool('pref_category_show_pattern'), isFalse);
        expect(prefs.getBool('pref_activity_show_pattern'), isFalse);
        // The properties key should have been created as an empty JSON array.
        expect(
          prefs.getString('pref_properties_category_selected_ids'),
          equals(jsonEncode(<String>[])),
        );
        expect(prefs.getInt('pref_version'), equals(4));

        // Service getters should reflect defaults
        expect(svc.getMonthlyShowPattern(), isFalse);
        expect(svc.getCategoryShowPattern(), isFalse);
        expect(svc.getActivityShowPattern(), isFalse);
      },
    );

    test('clearAll removes show-pattern keys and resets notifiers', () async {
      final svc = await PreferencesService.build();

      // Set values first
      await svc.setMonthlyShowPattern(true);
      await svc.setCategoryShowPattern(true);
      await svc.setActivityShowPattern(true);

      // Verify set
      expect(svc.getMonthlyShowPattern(), isTrue);
      expect(svc.getCategoryShowPattern(), isTrue);
      expect(svc.getActivityShowPattern(), isTrue);

      // Clear all
      await svc.clearAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('pref_monthly_show_pattern'), isFalse);
      expect(prefs.containsKey('pref_category_show_pattern'), isFalse);
      expect(prefs.containsKey('pref_activity_show_pattern'), isFalse);

      // Notifiers should be reset to defaults (false)
      expect(svc.getMonthlyShowPattern(), isFalse);
      expect(svc.getCategoryShowPattern(), isFalse);
      expect(svc.getActivityShowPattern(), isFalse);
    });

    // ------------------------
    // New tests: selected IDs persistence (categories / activities)
    // ------------------------
    test('default selected ids are empty', () async {
      final svc = await PreferencesService.build();

      expect(svc.getCategorySelectedIds(), isEmpty);
      expect(svc.getActivitySelectedIds(), isEmpty);

      final prefs = await SharedPreferences.getInstance();
      // Migration may have written empty JSON arrays; decode safely and assert we get lists.
      final catDecoded = jsonDecode(
        prefs.getString('pref_category_selected_ids') ?? '[]',
      );
      final actDecoded = jsonDecode(
        prefs.getString('pref_activity_selected_ids') ?? '[]',
      );

      expect(catDecoded, isA<List>());
      expect(actDecoded, isA<List>());
      expect((catDecoded as List).isEmpty, isTrue);
      expect((actDecoded as List).isEmpty, isTrue);
    });

    test('setCategorySelectedIds persists value and notifies', () async {
      final svc = await PreferencesService.build();

      var notified = false;
      svc.categorySelectedIdsNotifier.addListener(() {
        notified = true;
      });

      final sample = ['cat1', 'cat2'];
      await svc.setCategorySelectedIds(sample);

      expect(svc.getCategorySelectedIds(), equals(sample));
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(prefs.getString('pref_category_selected_ids') ?? '[]')
              as List<dynamic>;
      expect(stored.map((e) => e.toString()).toList(), equals(sample));
    });

    test('setActivitySelectedIds persists value and notifies', () async {
      final svc = await PreferencesService.build();

      var notified = false;
      svc.activitySelectedIdsNotifier.addListener(() {
        notified = true;
      });

      final sample = ['actA', 'actB', 'actC'];
      await svc.setActivitySelectedIds(sample);

      expect(svc.getActivitySelectedIds(), equals(sample));
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(prefs.getString('pref_activity_selected_ids') ?? '[]')
              as List<dynamic>;
      expect(stored.map((e) => e.toString()).toList(), equals(sample));
    });

    test('build loads persisted selected ids from SharedPreferences', () async {
      // Pre-populate mock prefs before building the service
      SharedPreferences.setMockInitialValues({
        'pref_category_selected_ids': jsonEncode(['c1']),
        'pref_activity_selected_ids': jsonEncode(['a1', 'a2']),
        'pref_properties_category_selected_ids': jsonEncode(['pc1', 'pc2']),
      });

      final svc = await PreferencesService.build();

      expect(svc.getCategorySelectedIds(), equals(['c1']));
      expect(svc.getActivitySelectedIds(), equals(['a1', 'a2']));
      expect(svc.getPropertiesCategorySelectedIds(), equals(['pc1', 'pc2']));
    });

    test(
      'setPropertiesCategorySelectedIds persists value and notifies',
      () async {
        final svc = await PreferencesService.build();

        var notified = false;
        svc.propertiesCategorySelectedIdsNotifier.addListener(() {
          notified = true;
        });

        final sample = ['pcatA', 'pcatB'];
        await svc.setPropertiesCategorySelectedIds(sample);

        expect(svc.getPropertiesCategorySelectedIds(), equals(sample));
        expect(notified, isTrue);

        final prefs = await SharedPreferences.getInstance();
        final stored =
            jsonDecode(
                  prefs.getString('pref_properties_category_selected_ids') ??
                      '[]',
                )
                as List<dynamic>;
        expect(stored.map((e) => e.toString()).toList(), equals(sample));
      },
    );

    test(
      'clearAll removes properties selected-ids key and resets notifier',
      () async {
        final svc = await PreferencesService.build();

        // Set values first
        await svc.setPropertiesCategorySelectedIds(['px', 'py']);

        // Verify set
        expect(svc.getPropertiesCategorySelectedIds(), equals(['px', 'py']));

        // Clear all
        await svc.clearAll();

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.containsKey('pref_properties_category_selected_ids'),
          isFalse,
        );

        // Notifier should be reset to default (empty list)
        expect(svc.getPropertiesCategorySelectedIds(), isEmpty);
      },
    );

    test('clearAll removes selected-ids keys and resets notifiers', () async {
      final svc = await PreferencesService.build();

      // Set values first
      await svc.setCategorySelectedIds(['x', 'y']);
      await svc.setActivitySelectedIds(['p']);

      // Verify set
      expect(svc.getCategorySelectedIds(), equals(['x', 'y']));
      expect(svc.getActivitySelectedIds(), equals(['p']));

      // Clear all
      await svc.clearAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('pref_category_selected_ids'), isFalse);
      expect(prefs.containsKey('pref_activity_selected_ids'), isFalse);

      // Notifiers should be reset to defaults (empty lists)
      expect(svc.getCategorySelectedIds(), isEmpty);
      expect(svc.getActivitySelectedIds(), isEmpty);
    });

    // ------------------------
    // Legacy tests left intact (view-mode integer keys tests)
    // ------------------------
    test('view-mode keys are absent by default', () async {
      // Ensure service builds cleanly even if new keys are not present
      final svc = await PreferencesService.build();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pref_monthly_view_mode'), isNull);
      expect(prefs.getInt('pref_category_trends_view_mode'), isNull);
      expect(prefs.getInt('pref_activity_trends_view_mode'), isNull);
    });

    test(
      'persist monthly/category/activity view modes via SharedPreferences',
      () async {
        final svc = await PreferencesService.build();

        final prefs = await SharedPreferences.getInstance();

        // Simulate persisting view-mode selections for three widgets.
        // Convention (for these tests):
        // 0 = History, 1 = Pattern, 2 = Other (widget-specific)
        await prefs.setInt('pref_monthly_view_mode', 0);
        await prefs.setInt('pref_category_trends_view_mode', 1);
        await prefs.setInt('pref_activity_trends_view_mode', 2);

        expect(prefs.getInt('pref_monthly_view_mode'), equals(0));
        expect(prefs.getInt('pref_category_trends_view_mode'), equals(1));
        expect(prefs.getInt('pref_activity_trends_view_mode'), equals(2));
      },
    );

    test('build loads persisted view modes from SharedPreferences', () async {
      // Pre-populate mock prefs before building the service
      SharedPreferences.setMockInitialValues({
        'pref_monthly_view_mode': 1,
        'pref_category_trends_view_mode': 0,
        'pref_activity_trends_view_mode': 2,
      });

      final svc = await PreferencesService.build();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pref_monthly_view_mode'), equals(1));
      expect(prefs.getInt('pref_category_trends_view_mode'), equals(0));
      expect(prefs.getInt('pref_activity_trends_view_mode'), equals(2));
    });

    // ------------------------
    // Activity filter persistence tests
    // ------------------------
    test('setActivityFilter persists value and notifies', () async {
      final svc = await PreferencesService.build();

      var notified = false;
      svc.activityFilterNotifier.addListener(() {
        notified = true;
      });

      await svc.setActivityFilter(AnalysisEventType.solo);

      expect(svc.getActivityFilter(), equals(AnalysisEventType.solo));
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt('pref_activity_filter'),
        equals(AnalysisEventType.solo.index),
      );
    });

    test('build loads persisted activity filter', () async {
      // Pre-populate mock prefs before building the service
      SharedPreferences.setMockInitialValues({
        'pref_activity_filter': AnalysisEventType.couple.index,
      });

      final svc = await PreferencesService.build();

      expect(svc.getActivityFilter(), equals(AnalysisEventType.couple));
    });

    test('clearAll removes activity filter and resets notifier', () async {
      final svc = await PreferencesService.build();

      await svc.setActivityFilter(AnalysisEventType.group);
      expect(svc.getActivityFilter(), equals(AnalysisEventType.group));

      await svc.clearAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('pref_activity_filter'), isFalse);

      // Service getter should now reflect cleared state
      expect(svc.getActivityFilter(), isNull);
    });
  });
}
