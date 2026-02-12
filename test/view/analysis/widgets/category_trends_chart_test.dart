// indulge/test/view/analysis/widgets/category_trends_chart_test.dart
//
// Widget tests for CategoryTrendsChart: verify it reads persisted selected
// categories and reacts to changes via PreferencesService.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indulge/view/analysis/widgets/activity_breakdown/category_trends_chart.dart';
import 'package:indulge/services/preferences_service.dart';
import 'package:indulge/view/analysis/models/analysis_data.dart';
import 'package:indulge/data/models.dart';

void main() {
  group('CategoryTrendsChart widget', () {
    setUp(() async {
      // Clear mock SharedPreferences before each test.
      SharedPreferences.setMockInitialValues({});
    });

    SexualEvent createEvent({
      required DateTime date,
      required String categoryId,
      List<String> partnerIds = const [],
    }) {
      final participants = <ActivityParticipant>[];

      // Add a "me" participant (required structure)
      participants.add(
        ActivityParticipant(
          participant: const Reference(reference: 'me'),
          activityCounts: [],
        ),
      );

      // Add partner participants (if any)
      for (final pid in partnerIds) {
        participants.add(
          ActivityParticipant(
            participant: Reference(reference: pid),
            activityCounts: [],
          ),
        );
      }

      return SexualEvent(
        id: 'evt-${date.millisecondsSinceEpoch}-$categoryId',
        date: date,
        activities: [
          EventActivity(
            category: Reference(reference: categoryId),
            participants: participants,
          ),
        ],
      );
    }

    /// Helper to create a minimal AnalysisData instance with the fields the
    /// widget expects. We populate enough fields so the constructor succeeds.
    AnalysisData makeAnalysisData({
      required List<SexualEvent> events,
      required Map<String, SexualActivityCategory> activityCategories,
      required Map<String, int> activityCountsThisYear,
    }) {
      final emptyPeriod = PeriodComparison.calculate(0, 0);

      return AnalysisData(
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
        events: events,
      );
    }

    testWidgets(
      'reads persisted selected categories and shows chart (no "Select at least one category" prompt)',
      (tester) async {
        // Pre-populate mock SharedPreferences with a persisted selection for category 'cat1'.
        SharedPreferences.setMockInitialValues({
          'pref_category_selected_ids': jsonEncode(['cat1']),
        });

        // Build the preferences service (reads from the mock SharedPreferences).
        final prefsService = await PreferencesService.build();

        // Create two events, one for each category so top categories will include both.
        final now = DateTime.now();
        final event1 = createEvent(
          date: now.subtract(const Duration(days: 10)),
          categoryId: 'cat1',
        );
        final event2 = createEvent(
          date: now.subtract(const Duration(days: 20)),
          categoryId: 'cat2',
        );

        final activityCategories = <String, SexualActivityCategory>{
          'cat1': const SexualActivityCategory(id: 'cat1', name: 'Cat One'),
          'cat2': const SexualActivityCategory(id: 'cat2', name: 'Cat Two'),
        };

        final activityCountsThisYear = <String, int>{'cat1': 3, 'cat2': 2};

        final analysisData = makeAnalysisData(
          events: [event1, event2],
          activityCategories: activityCategories,
          activityCountsThisYear: activityCountsThisYear,
        );

        await tester.pumpWidget(
          Provider<PreferencesService>.value(
            value: prefsService,
            child: MaterialApp(
              home: Scaffold(
                body: CategoryTrendsChart(
                  data: analysisData,
                  showTypeFilter: false,
                ),
              ),
            ),
          ),
        );

        // Allow async init code to run and settle.
        await tester.pumpAndSettle();

        // The widget should render the category chips for both categories.
        expect(find.text('Cat One'), findsOneWidget);
        expect(find.text('Cat Two'), findsOneWidget);

        // Because the persisted selection contained 'cat1', the chart should
        // not show the "Select at least one category" message.
        expect(find.text('Select at least one category'), findsNothing);
      },
    );

    testWidgets(
      'updates when persisted selected categories change via PreferencesService notifier',
      (tester) async {
        // Start with a persisted selection containing only 'cat1'.
        SharedPreferences.setMockInitialValues({
          'pref_category_selected_ids': jsonEncode(['cat1']),
        });

        final prefsService = await PreferencesService.build();

        final now = DateTime.now();
        final event1 = createEvent(
          date: now.subtract(const Duration(days: 10)),
          categoryId: 'cat1',
        );
        final event2 = createEvent(
          date: now.subtract(const Duration(days: 20)),
          categoryId: 'cat2',
        );

        final activityCategories = <String, SexualActivityCategory>{
          'cat1': const SexualActivityCategory(id: 'cat1', name: 'Cat One'),
          'cat2': const SexualActivityCategory(id: 'cat2', name: 'Cat Two'),
        };

        final analysisData = makeAnalysisData(
          events: [event1, event2],
          activityCategories: activityCategories,
          activityCountsThisYear: {'cat1': 4, 'cat2': 1},
        );

        await tester.pumpWidget(
          Provider<PreferencesService>.value(
            value: prefsService,
            child: MaterialApp(
              home: Scaffold(
                body: CategoryTrendsChart(
                  data: analysisData,
                  showTypeFilter: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially, with persisted ['cat1'], the "Select at least one category" prompt should not be shown.
        expect(find.text('Select at least one category'), findsNothing);

        // Now clear the persisted selection via the service. Widget listens to notifier and should update.
        await prefsService.setCategorySelectedIds([]);

        // Pump to allow UI update from notifier.
        await tester.pumpAndSettle();

        // With an empty selection, the widget should now encourage the user to pick a category.
        expect(find.text('Select at least one category'), findsOneWidget);

        // Now set selection to include 'cat2' only and ensure the prompt disappears.
        await prefsService.setCategorySelectedIds(['cat2']);
        await tester.pumpAndSettle();

        expect(find.text('Select at least one category'), findsNothing);
        // Ensure Cat Two is present
        expect(find.text('Cat Two'), findsOneWidget);
      },
    );
  });
}
