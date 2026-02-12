import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indulge/view/analysis/widgets/activity_breakdown/properties_by_activity_section.dart';
import 'package:indulge/services/preferences_service.dart';
import 'package:indulge/view/analysis/models/analysis_data.dart';
import 'package:indulge/data/models.dart';

void main() {
  group('PropertiesByActivitySection widget', () {
    setUp(() async {
      // Clear mock SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'reads persisted selected categories and filters displayed activities accordingly, then syncs on preference changes',
      (tester) async {
        // Pre-populate mock SharedPreferences with a persisted selection
        SharedPreferences.setMockInitialValues({
          'pref_category_selected_ids': jsonEncode(['a1']),
        });

        // Build the PreferencesService (reads from the mock SharedPreferences)
        final prefsService = await PreferencesService.build();

        // Create minimal AnalysisData with two activity categories and counts.
        // Many fields are required by the constructor; provide sensible defaults.
        final activityCountsThisYear = <String, int>{'a1': 5, 'a2': 3};

        final activityCategories = <String, SexualActivityCategory>{
          'a1': const SexualActivityCategory(id: 'a1', name: 'Act1'),
          'a2': const SexualActivityCategory(id: 'a2', name: 'Act2'),
        };

        // Small helper to create an empty AnalysisData with the fields the widget needs.
        final emptyPeriod = PeriodComparison.calculate(0, 0);

        final analysisData = AnalysisData(
          totalEvents: 0,
          totalActivities: 0,
          uniquePartners: 0,
          riskyActivityCount: 0,
          safeActivityCount: 0,
          eventsThisMonth: 0,
          eventsThisYear: 0,
          uniquePartnersThisMonth: 0,
          uniquePartnersThisYear: 0,
          soloEventsThisYear: 0,
          coupleEventsThisYear: 0,
          groupEventsThisYear: 0,
          soloEventsTotal: 0,
          nonSoloEventsTotal: 0,
          soloActivityCounts: const {},
          soloSexualActivityCounts: const {},
          soloActivityCountsThisYear: const {},
          soloSexualActivityCountsThisYear: const {},
          activityCountsByType: const {},
          sexualActivityCountsByType: const {},
          monthlyCountsByType: const {},
          dayOfWeekCountsByType: const {},
          averageDayOfWeekCountsByType: const {},
          eventCountsByType: const {},
          eventsByType: const {},
          knownPartners: 0,
          anonymousPartnerInstances: 0,
          busiestDay: null,
          busiestDayEventCount: 0,
          busiestEvent: null,
          busiestEventActivityCount: 0,
          activityCounts: const {},
          activityCountsThisYear: activityCountsThisYear,
          activityCategories: activityCategories,
          longestStreak: 0,
          currentStreak: 0,
          personCounts: const {},
          personEventCounts: const {},
          personEvents: const {},
          personPropertyCounts: const {},
          sexualActivityCountsTotal: const {},
          sexualActivities: const {},
          sexualActivityPartnerCounts: const {},
          categoryPartnerCountsThisYear: const {},
          sexualActivityPartnerCountsThisYear: const {},
          categoryActivityPartnerCountsThisYear: const {},
          dailyCounts: const {},
          dayOfWeekCounts: const {},
          monthlyCounts: const {},
          daysSinceLastRiskyActivity: 0,
          daysSinceLastActivity: 0,
          thisWeekVsLastWeek: emptyPeriod,
          thisMonthVsLastMonth: emptyPeriod,
          averageEventsPerWeek: 0.0,
          averageEventsPerMonth: 0.0,
          averageActivitiesPerWeek: 0.0,
          averageActivitiesPerMonth: 0.0,
          averagePartnersPerEvent: 0.0,
          averageActivitiesPerEvent: 0.0,
          averageSexualActivitiesPerEvent: 0.0,
          averageEventsPerDayOfWeek: const {},
          topActivityPairs: const [],
          topCategoryPairs: const [],
          startDate: null,
          endDate: null,
          events: const [],
        );

        // Build widget tree with the PreferencesService provided
        await tester.pumpWidget(
          Provider<PreferencesService>.value(
            value: prefsService,
            child: MaterialApp(
              home: Scaffold(
                body: PropertiesByActivitySection(
                  data: analysisData,
                  filterType: null,
                ),
              ),
            ),
          ),
        );

        // Allow any async init code to complete and the widget to build
        await tester.pumpAndSettle();

        // Because persisted selection contains only 'a1', the widget should
        // filter to show only the activity corresponding to 'a1' (Act1).
        expect(find.text('Act1'), findsOneWidget);
        expect(find.text('Act2'), findsNothing);

        // Now change the persisted selection via PreferencesService and ensure
        // the widget updates (it listens to the notifier).
        await prefsService.setCategorySelectedIds(['a2']);

        // Pump to reflect notifier-triggered UI changes
        await tester.pumpAndSettle();

        // Now 'Act2' should be visible and 'Act1' should not
        expect(find.text('Act2'), findsOneWidget);
        expect(find.text('Act1'), findsNothing);
      },
    );

    testWidgets(
      'choosing a selection programmatically and clearing it updates the UI',
      (tester) async {
        // Start with no persisted selection
        SharedPreferences.setMockInitialValues({});

        final prefsService = await PreferencesService.build();

        final activityCountsThisYear = <String, int>{'a1': 4, 'a2': 2};

        final activityCategories = <String, SexualActivityCategory>{
          'a1': const SexualActivityCategory(id: 'a1', name: 'Act1'),
          'a2': const SexualActivityCategory(id: 'a2', name: 'Act2'),
        };

        final emptyPeriod = PeriodComparison.calculate(0, 0);

        final analysisData = AnalysisData(
          totalEvents: 0,
          totalActivities: 0,
          uniquePartners: 0,
          riskyActivityCount: 0,
          safeActivityCount: 0,
          eventsThisMonth: 0,
          eventsThisYear: 0,
          uniquePartnersThisMonth: 0,
          uniquePartnersThisYear: 0,
          soloEventsThisYear: 0,
          coupleEventsThisYear: 0,
          groupEventsThisYear: 0,
          soloEventsTotal: 0,
          nonSoloEventsTotal: 0,
          soloActivityCounts: const {},
          soloSexualActivityCounts: const {},
          soloActivityCountsThisYear: const {},
          soloSexualActivityCountsThisYear: const {},
          activityCountsByType: const {},
          sexualActivityCountsByType: const {},
          monthlyCountsByType: const {},
          dayOfWeekCountsByType: const {},
          averageDayOfWeekCountsByType: const {},
          eventCountsByType: const {},
          eventsByType: const {},
          knownPartners: 0,
          anonymousPartnerInstances: 0,
          busiestDay: null,
          busiestDayEventCount: 0,
          busiestEvent: null,
          busiestEventActivityCount: 0,
          activityCounts: const {},
          activityCountsThisYear: activityCountsThisYear,
          activityCategories: activityCategories,
          longestStreak: 0,
          currentStreak: 0,
          personCounts: const {},
          personEventCounts: const {},
          personEvents: const {},
          personPropertyCounts: const {},
          sexualActivityCountsTotal: const {},
          sexualActivities: const {},
          sexualActivityPartnerCounts: const {},
          categoryPartnerCountsThisYear: const {},
          sexualActivityPartnerCountsThisYear: const {},
          categoryActivityPartnerCountsThisYear: const {},
          dailyCounts: const {},
          dayOfWeekCounts: const {},
          monthlyCounts: const {},
          daysSinceLastRiskyActivity: 0,
          daysSinceLastActivity: 0,
          thisWeekVsLastWeek: emptyPeriod,
          thisMonthVsLastMonth: emptyPeriod,
          averageEventsPerWeek: 0.0,
          averageEventsPerMonth: 0.0,
          averageActivitiesPerWeek: 0.0,
          averageActivitiesPerMonth: 0.0,
          averagePartnersPerEvent: 0.0,
          averageActivitiesPerEvent: 0.0,
          averageSexualActivitiesPerEvent: 0.0,
          averageEventsPerDayOfWeek: const {},
          topActivityPairs: const [],
          topCategoryPairs: const [],
          startDate: null,
          endDate: null,
          events: const [],
        );

        await tester.pumpWidget(
          Provider<PreferencesService>.value(
            value: prefsService,
            child: MaterialApp(
              home: Scaffold(
                body: PropertiesByActivitySection(
                  data: analysisData,
                  filterType: null,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially, no filter is applied; both activities should be present.
        expect(find.text('Act1'), findsOneWidget);
        expect(find.text('Act2'), findsOneWidget);

        // Programmatically set the selection to only 'a1'
        await prefsService.setCategorySelectedIds(['a1']);
        await tester.pumpAndSettle();

        expect(find.text('Act1'), findsOneWidget);
        expect(find.text('Act2'), findsNothing);

        // Clear selection
        await prefsService.setCategorySelectedIds([]);
        await tester.pumpAndSettle();

        // Both activities visible again
        expect(find.text('Act1'), findsOneWidget);
        expect(find.text('Act2'), findsOneWidget);
      },
    );
  });
}
