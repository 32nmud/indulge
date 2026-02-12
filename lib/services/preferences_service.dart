/*
  preferences_service.dart

  A small SharedPreferences-backed preferences service used to persist:
  - selected period preset (Month / Week / Year / Custom)
  - custom first/second DateTimeRange endpoints (ISO strings)
  - selected activity filter (AnalysisEventType)

  The service exposes synchronous getters (after initialization) and async setters.
  It also exposes ValueNotifiers so UI code can listen for preference changes.
*/

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indulge/view/analysis/widgets/period_comparison/period_comparison_section.dart';
import 'package:indulge/view/analysis/models/analysis_data.dart';

class PreferencesService {
  // Keys used in SharedPreferences
  static const String _kPreferencesVersion = 'pref_version';
  static const String _kPeriodPreset = 'pref_period_preset';
  static const String _kCustomFirst = 'pref_custom_first';
  static const String _kCustomSecond = 'pref_custom_second';
  static const String _kActivityFilter = 'pref_activity_filter';
  static const String _kAnalysisTimeWindow = 'pref_analysis_time_window';
  static const String _kAnalysisSpecificYear = 'pref_analysis_specific_year';

  // View-mode keys (bools): true => Pattern view, false => History view
  static const String _kMonthlyShowPattern = 'pref_monthly_show_pattern';
  static const String _kCategoryShowPattern = 'pref_category_show_pattern';
  static const String _kActivityShowPattern = 'pref_activity_show_pattern';

  // Selected IDs (JSON-encoded lists) - used to persist user-selected
  // category and activity IDs for trends widgets, and a separate key for the
  // properties-by-activity section so each widget can persist its own selection.
  static const String _kCategorySelectedIds = 'pref_category_selected_ids';
  static const String _kPropertiesCategorySelectedIds =
      'pref_properties_category_selected_ids';
  static const String _kPartnerPropertiesCategorySelectedIds =
      'pref_partner_properties_category_selected_ids';
  static const String _kActivitySelectedIds = 'pref_activity_selected_ids';

  // Current preferences version. Increment when stored keys/shape change.
  static const int _currentPreferencesVersion = 4;

  // Default values
  static const PeriodPreset _defaultPreset = PeriodPreset.lastMonthVsThisMonth;

  final SharedPreferences _prefs;

  // ValueNotifiers to allow listening to preference changes in UI
  final ValueNotifier<PeriodPreset> periodPresetNotifier;
  final ValueNotifier<DateTime?> customFirstNotifier;
  final ValueNotifier<DateTime?> customSecondNotifier;
  final ValueNotifier<AnalysisEventType?> activityFilterNotifier;

  /// Numeric index representing the analysis time window selection:
  /// should map to the app's `TimeWindow` enum indices (parent is responsible for mapping).
  final ValueNotifier<int?> analysisTimeWindowNotifier;

  /// Specific year to use when the analysis time window is `specificYear`.
  /// Stored as an integer year (e.g., 2023). May be null if no specific year is set.
  final ValueNotifier<int?> analysisSpecificYearNotifier;

  // View-mode notifiers for widgets that support history vs pattern views.
  // `true` -> show pattern (average by day-of-week), `false` -> show history (counts by month)
  final ValueNotifier<bool> monthlyShowPatternNotifier;
  final ValueNotifier<bool> categoryShowPatternNotifier;
  final ValueNotifier<bool> activityShowPatternNotifier;

  // Persisted selected IDs (lists). These hold the user's selected category
  // and activity IDs for the trends widgets and are stored as JSON arrays in prefs.
  final ValueNotifier<List<String>> categorySelectedIdsNotifier;
  final ValueNotifier<List<String>> propertiesCategorySelectedIdsNotifier;
  final ValueNotifier<List<String>>
  partnerPropertiesCategorySelectedIdsNotifier;
  final ValueNotifier<List<String>> activitySelectedIdsNotifier;

  PreferencesService._(
    this._prefs,
    this.periodPresetNotifier,
    this.customFirstNotifier,
    this.customSecondNotifier,
    this.activityFilterNotifier,
    this.analysisTimeWindowNotifier,
    this.analysisSpecificYearNotifier,
    this.monthlyShowPatternNotifier,
    this.categoryShowPatternNotifier,
    this.activityShowPatternNotifier,
    this.categorySelectedIdsNotifier,
    this.propertiesCategorySelectedIdsNotifier,
    this.partnerPropertiesCategorySelectedIdsNotifier,
    this.activitySelectedIdsNotifier,
  );

  /// Asynchronously build the singleton service.
  /// Call this once (for example, during app initialization) and reuse the returned instance.
  static Future<PreferencesService> build() async {
    final prefs = await SharedPreferences.getInstance();

    // Migration: ensure stored preferences are upgraded to the current shape.
    final storedVersion = prefs.getInt(_kPreferencesVersion) ?? 0;
    if (storedVersion < _currentPreferencesVersion) {
      await _migratePreferences(
        prefs,
        storedVersion,
        _currentPreferencesVersion,
      );
      // Persist new version after migration
      await prefs.setInt(_kPreferencesVersion, _currentPreferencesVersion);
    }

    // Load saved values
    final presetIndex = prefs.getInt(_kPeriodPreset);
    final preset =
        (presetIndex != null &&
            presetIndex >= 0 &&
            presetIndex < PeriodPreset.values.length)
        ? PeriodPreset.values[presetIndex]
        : _defaultPreset;

    final customFirstIso = prefs.getString(_kCustomFirst);
    final customSecondIso = prefs.getString(_kCustomSecond);

    DateTime? customFirst;
    DateTime? customSecond;
    try {
      customFirst = customFirstIso != null
          ? DateTime.parse(customFirstIso)
          : null;
    } catch (_) {
      customFirst = null;
    }
    try {
      customSecond = customSecondIso != null
          ? DateTime.parse(customSecondIso)
          : null;
    } catch (_) {
      customSecond = null;
    }

    final activityFilterIndex = prefs.getInt(_kActivityFilter);
    AnalysisEventType? activityFilter;
    if (activityFilterIndex != null &&
        activityFilterIndex >= 0 &&
        activityFilterIndex < AnalysisEventType.values.length) {
      activityFilter = AnalysisEventType.values[activityFilterIndex];
    } else {
      activityFilter = null;
    }

    // Analysis time window index (stored as integer). Parent widgets map this index
    // to their TimeWindow enum if needed.
    final analysisWindowIndex = prefs.getInt(_kAnalysisTimeWindow);
    final int? analysisWindow = (analysisWindowIndex != null)
        ? analysisWindowIndex
        : null;
    // Specific year for the 'specificYear' time window (stored as integer year)
    final specificYearIndex = prefs.getInt(_kAnalysisSpecificYear);
    final int? analysisSpecificYear = (specificYearIndex != null)
        ? specificYearIndex
        : null;

    // Load view-mode booleans (default to false -> history view)
    final monthlyPattern = prefs.getBool(_kMonthlyShowPattern) ?? false;
    final categoryPattern = prefs.getBool(_kCategoryShowPattern) ?? false;
    final activityPattern = prefs.getBool(_kActivityShowPattern) ?? false;

    // Load selected IDs (JSON-encoded lists). Use a safe parser that falls back
    // to an empty list on parse errors.
    List<String> _parseStringList(String? jsonStr) {
      if (jsonStr == null) return <String>[];
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        return <String>[];
      }
    }

    final categorySelectedJson = prefs.getString(_kCategorySelectedIds);
    final propertiesCategorySelectedJson = prefs.getString(
      _kPropertiesCategorySelectedIds,
    );
    final partnerPropertiesCategorySelectedJson = prefs.getString(
      _kPartnerPropertiesCategorySelectedIds,
    );
    final activitySelectedJson = prefs.getString(_kActivitySelectedIds);
    final categorySelected = _parseStringList(categorySelectedJson);
    final propertiesCategorySelected = _parseStringList(
      propertiesCategorySelectedJson,
    );
    final partnerPropertiesCategorySelected = _parseStringList(
      partnerPropertiesCategorySelectedJson,
    );
    final activitySelected = _parseStringList(activitySelectedJson);

    return PreferencesService._(
      prefs,
      ValueNotifier<PeriodPreset>(preset),
      ValueNotifier<DateTime?>(customFirst),
      ValueNotifier<DateTime?>(customSecond),
      ValueNotifier<AnalysisEventType?>(activityFilter),
      ValueNotifier<int?>(analysisWindow),
      ValueNotifier<int?>(analysisSpecificYear),
      ValueNotifier<bool>(monthlyPattern),
      ValueNotifier<bool>(categoryPattern),
      ValueNotifier<bool>(activityPattern),
      ValueNotifier<List<String>>(categorySelected),
      ValueNotifier<List<String>>(propertiesCategorySelected),
      ValueNotifier<List<String>>(partnerPropertiesCategorySelected),
      ValueNotifier<List<String>>(activitySelected),
    );
  }

  // ------------------
  // Period preset API
  // ------------------

  PeriodPreset getPeriodPreset() => periodPresetNotifier.value;

  Future<void> setPeriodPreset(PeriodPreset preset) async {
    final success = await _prefs.setInt(_kPeriodPreset, preset.index);
    if (success) {
      periodPresetNotifier.value = preset;
    } else {
      // Still update the in-memory notifier to reflect user's intent.
      periodPresetNotifier.value = preset;
    }
  }

  // ----------------------------
  // Custom date range API (ends)
  // ----------------------------

  DateTime? getCustomFirst() => customFirstNotifier.value;
  DateTime? getCustomSecond() => customSecondNotifier.value;

  Future<void> setCustomFirst(DateTime? dt) async {
    if (dt == null) {
      await _prefs.remove(_kCustomFirst);
      customFirstNotifier.value = null;
      return;
    }
    final success = await _prefs.setString(_kCustomFirst, dt.toIso8601String());
    if (success) {
      customFirstNotifier.value = dt;
    } else {
      customFirstNotifier.value = dt;
    }
  }

  Future<void> setCustomSecond(DateTime? dt) async {
    if (dt == null) {
      await _prefs.remove(_kCustomSecond);
      customSecondNotifier.value = null;
      return;
    }
    final success = await _prefs.setString(
      _kCustomSecond,
      dt.toIso8601String(),
    );
    if (success) {
      customSecondNotifier.value = dt;
    } else {
      customSecondNotifier.value = dt;
    }
  }

  // -------------------------
  // Activity filter API
  // -------------------------

  AnalysisEventType? getActivityFilter() => activityFilterNotifier.value;

  Future<void> setActivityFilter(AnalysisEventType? type) async {
    if (type == null) {
      await _prefs.remove(_kActivityFilter);
      activityFilterNotifier.value = null;
      return;
    }
    final success = await _prefs.setInt(_kActivityFilter, type.index);
    if (success) {
      activityFilterNotifier.value = type;
    } else {
      activityFilterNotifier.value = type;
    }
  }

  // -------------------------
  // Analysis time window API
  // -------------------------
  ///
  // Stores a numeric index that maps to the app's TimeWindow enum. Keeping it
  // as an int here avoids a direct dependency on the enum type defined in
  // UI code; callers (UI) should map between the enum and index.
  int? getAnalysisTimeWindowIndex() => analysisTimeWindowNotifier.value;

  Future<void> setAnalysisTimeWindowIndex(int? index) async {
    if (index == null) {
      await _prefs.remove(_kAnalysisTimeWindow);
      analysisTimeWindowNotifier.value = null;
      return;
    }
    final success = await _prefs.setInt(_kAnalysisTimeWindow, index);
    if (success) {
      analysisTimeWindowNotifier.value = index;
    } else {
      analysisTimeWindowNotifier.value = index;
    }
  }

  // -------------------------
  // Analysis specific year API
  // -------------------------
  ///
  // Stores the specific year to use when the Analysis time window is set to
  // `specificYear`. The UI should map this integer into a DateTimeRange as needed.
  int? getAnalysisSpecificYear() => analysisSpecificYearNotifier.value;

  Future<void> setAnalysisSpecificYear(int? year) async {
    if (year == null) {
      await _prefs.remove(_kAnalysisSpecificYear);
      analysisSpecificYearNotifier.value = null;
      return;
    }
    final success = await _prefs.setInt(_kAnalysisSpecificYear, year);
    if (success) {
      analysisSpecificYearNotifier.value = year;
    } else {
      analysisSpecificYearNotifier.value = year;
    }
  }

  // -------------------------
  // View-mode APIs (history vs pattern)
  // -------------------------
  //
  // These control whether widgets render "Pattern" (average by day-of-week)
  // or "History" (counts by month). We expose both synchronous getters and
  // async setters that persist to SharedPreferences and update notifiers.

  bool getMonthlyShowPattern() => monthlyShowPatternNotifier.value;
  Future<void> setMonthlyShowPattern(bool showPattern) async {
    final success = await _prefs.setBool(_kMonthlyShowPattern, showPattern);
    if (success) {
      monthlyShowPatternNotifier.value = showPattern;
    } else {
      monthlyShowPatternNotifier.value = showPattern;
    }
  }

  bool getCategoryShowPattern() => categoryShowPatternNotifier.value;
  Future<void> setCategoryShowPattern(bool showPattern) async {
    final success = await _prefs.setBool(_kCategoryShowPattern, showPattern);
    if (success) {
      categoryShowPatternNotifier.value = showPattern;
    } else {
      categoryShowPatternNotifier.value = showPattern;
    }
  }

  bool getActivityShowPattern() => activityShowPatternNotifier.value;
  Future<void> setActivityShowPattern(bool showPattern) async {
    final success = await _prefs.setBool(_kActivityShowPattern, showPattern);
    if (success) {
      activityShowPatternNotifier.value = showPattern;
    } else {
      activityShowPatternNotifier.value = showPattern;
    }
  }

  // -------------------------
  // Selected IDs APIs
  // -------------------------
  //
  // Category selected IDs (list of string IDs stored as JSON)
  List<String> getCategorySelectedIds() =>
      List.unmodifiable(categorySelectedIdsNotifier.value);
  Future<void> setCategorySelectedIds(List<String> ids) async {
    final jsonStr = jsonEncode(ids);
    final success = await _prefs.setString(_kCategorySelectedIds, jsonStr);
    if (success) {
      categorySelectedIdsNotifier.value = List.unmodifiable(ids);
    } else {
      categorySelectedIdsNotifier.value = List.unmodifiable(ids);
    }
  }

  // Properties-section selected category IDs (separate from category trends)
  List<String> getPropertiesCategorySelectedIds() =>
      List.unmodifiable(propertiesCategorySelectedIdsNotifier.value);
  Future<void> setPropertiesCategorySelectedIds(List<String> ids) async {
    final jsonStr = jsonEncode(ids);
    final success = await _prefs.setString(
      _kPropertiesCategorySelectedIds,
      jsonStr,
    );
    if (success) {
      propertiesCategorySelectedIdsNotifier.value = List.unmodifiable(ids);
    } else {
      propertiesCategorySelectedIdsNotifier.value = List.unmodifiable(ids);
    }
  }

  // Partner-section selected category IDs (separate key so partner UI stores its own selection)
  List<String> getPartnerPropertiesCategorySelectedIds() =>
      List.unmodifiable(partnerPropertiesCategorySelectedIdsNotifier.value);
  Future<void> setPartnerPropertiesCategorySelectedIds(List<String> ids) async {
    final jsonStr = jsonEncode(ids);
    final success = await _prefs.setString(
      _kPartnerPropertiesCategorySelectedIds,
      jsonStr,
    );
    if (success) {
      partnerPropertiesCategorySelectedIdsNotifier.value = List.unmodifiable(
        ids,
      );
    } else {
      partnerPropertiesCategorySelectedIdsNotifier.value = List.unmodifiable(
        ids,
      );
    }
  }

  // Activity selected IDs
  List<String> getActivitySelectedIds() =>
      List.unmodifiable(activitySelectedIdsNotifier.value);
  Future<void> setActivitySelectedIds(List<String> ids) async {
    final jsonStr = jsonEncode(ids);
    final success = await _prefs.setString(_kActivitySelectedIds, jsonStr);
    if (success) {
      activitySelectedIdsNotifier.value = List.unmodifiable(ids);
    } else {
      activitySelectedIdsNotifier.value = List.unmodifiable(ids);
    }
  }

  // -------------------------
  // Utilities
  // -------------------------

  /// Clears persisted preferences for the keys this service manages.
  Future<void> clearAll() async {
    await _prefs.remove(_kPeriodPreset);
    await _prefs.remove(_kCustomFirst);
    await _prefs.remove(_kCustomSecond);
    await _prefs.remove(_kActivityFilter);
    await _prefs.remove(_kAnalysisTimeWindow);
    await _prefs.remove(_kAnalysisSpecificYear);
    await _prefs.remove(_kMonthlyShowPattern);
    await _prefs.remove(_kCategoryShowPattern);
    await _prefs.remove(_kActivityShowPattern);
    await _prefs.remove(_kCategorySelectedIds);
    await _prefs.remove(_kPropertiesCategorySelectedIds);
    await _prefs.remove(_kActivitySelectedIds);

    periodPresetNotifier.value = _defaultPreset;
    customFirstNotifier.value = null;
    customSecondNotifier.value = null;
    activityFilterNotifier.value = null;
    analysisTimeWindowNotifier.value = null;
    analysisSpecificYearNotifier.value = null;

    monthlyShowPatternNotifier.value = false;
    categoryShowPatternNotifier.value = false;
    activityShowPatternNotifier.value = false;

    categorySelectedIdsNotifier.value = <String>[];
    propertiesCategorySelectedIdsNotifier.value = <String>[];
    activitySelectedIdsNotifier.value = <String>[];
  }

  /// Migration hook - apply transformations from older stored preferences
  /// to the shape expected by the current version.
  static Future<void> _migratePreferences(
    SharedPreferences prefs,
    int fromVersion,
    int toVersion,
  ) async {
    // Migration runner: add small, idempotent transformations here when
    // _currentPreferencesVersion is incremented.
    //
    // Example: when bumping to version 2 we introduced per-widget boolean keys
    // (_kMonthlyShowPattern, _kCategoryShowPattern, _kActivityShowPattern).
    // Ensure those keys exist with safe defaults for older installs.
    if (fromVersion < 2) {
      // Version 2: add boolean keys for "show pattern" preferences.
      // Default to `false` (History view) if the key is not present.
      const monthlyKey = _kMonthlyShowPattern;
      const categoryKey = _kCategoryShowPattern;
      const activityKey = _kActivityShowPattern;

      if (!prefs.containsKey(monthlyKey)) {
        await prefs.setBool(monthlyKey, false);
      }
      if (!prefs.containsKey(categoryKey)) {
        await prefs.setBool(categoryKey, false);
      }
      if (!prefs.containsKey(activityKey)) {
        await prefs.setBool(activityKey, false);
      }
    }

    // Add future migrations here, guarding on fromVersion.
    if (fromVersion < 3) {
      // Version 3: introduce JSON-encoded selected-IDs keys. Default to empty arrays
      // to ensure older installs have sensible defaults.
      const categoryIdsKey = _kCategorySelectedIds;
      const activityIdsKey = _kActivitySelectedIds;

      if (!prefs.containsKey(categoryIdsKey)) {
        await prefs.setString(categoryIdsKey, jsonEncode(<String>[]));
      }
      if (!prefs.containsKey(activityIdsKey)) {
        await prefs.setString(activityIdsKey, jsonEncode(<String>[]));
      }

      // Ensure the stored preferences version reflects the migration we've just applied.
      // This helps older installs get upgraded immediately to the new version.
      await prefs.setInt(_kPreferencesVersion, _currentPreferencesVersion);
    }

    if (fromVersion < 4) {
      // Version 4: introduce a separate selected-IDs key for the properties-by-activity
      // section so it doesn't share selection state with the category trends widget.
      const propertiesCategoryKey = _kPropertiesCategorySelectedIds;
      if (!prefs.containsKey(propertiesCategoryKey)) {
        await prefs.setString(propertiesCategoryKey, jsonEncode(<String>[]));
      }

      // Update stored version to reflect this migration step.
      await prefs.setInt(_kPreferencesVersion, _currentPreferencesVersion);
    }

    return Future.value();
  }
}
