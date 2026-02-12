/*
  indulge/test/view/analysis/widgets/property_trends_chart_test.dart

  Widget tests for PropertyTrendsChart: verify it reads persisted selected
  activities and reacts to PreferencesService changes.
*/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indulge/view/analysis/widgets/activity_breakdown/property_trends_chart.dart';
import 'package:indulge/services/preferences_service.dart';
import 'package:indulge/view/analysis/models/analysis_data.dart';
import 'package:indulge/data/models.dart';

void main() {
  group('PropertyTrendsChart widget', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    /// Helper to create a minimal AnalysisData instance with the fields the
    /// widget expects. Provides the sexual activities and activityCountsThisYear
    /// which the widget uses to build chips and charts.
    AnalysisData makeAnalysisData({
      required List<SexualEvent> events,
      required Map<String, SexualActivity> sexualActivities,
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
        activityCategories: const {},
        longestStreak: 0,
        currentStreak: 0,
        personCounts: const {},
        personEventCounts: const {},
        personEvents: const {},
        personPropertyCounts: const {},
        sexualActivityCountsTotal: const {},
        sexualActivities: sexualActivities,
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

    SexualEvent makeEvent({
      required DateTime date,
      required String activityId,
      List<String> partnerIds = const [],
      List<String> propertyIds = const [],
    }) {
      final participants = <ActivityParticipant>[];

      // Add "me"
      participants.add(
        ActivityParticipant(
          participant: const Reference(reference: 'me'),
          activityCounts: [
            for (final pid in propertyIds)
              ActivityCount(
                activityReference: Reference(reference: pid),
                count: 1,
              ),
          ],
        ),
      );

      // Add partners
      for (final pid in partnerIds) {
        participants.add(
          ActivityParticipant(
            participant: Reference(reference: pid),
            activityCounts: propertyIds
                .map(
                  (p) => ActivityCount(
                    activityReference: Reference(reference: p),
                    count: 1,
                  ),
                )
                .toList(),
          ),
        );
      }

      return SexualEvent(
        id: 'evt-${date.millisecondsSinceEpoch}-$activityId',
        date: date,
        activities: [
          EventActivity(
            category: Reference(reference: activityId),
            participants: participants,
          ),
        ],
      );
    }

    testWidgets(
      'reads persisted selected activities and hides the "Select at least one activity" prompt',
      (tester) async {
        // Persist a selection for property 'p1'
        SharedPreferences.setMockInitialValues({
          'pref_activity_selected_ids': jsonEncode(['p1']),
        });

        final prefsService = await PreferencesService.build();

        final now = DateTime.now();
        final ev1 = makeEvent(
          date: now.subtract(const Duration(days: 5)),
          activityId: 'catA',
          propertyIds: ['p1'],
        );
        final ev2 = makeEvent(
          date: now.subtract(const Duration(days: 15)),
          activityId: 'catA',
          propertyIds: ['p2'],
        );

        final sexualActivities = <String, SexualActivity>{
          'p1': const SexualActivity(id: 'p1', name: 'Prop One'),
          'p2': const SexualActivity(id: 'p2', name: 'Prop Two'),
        };

        final analysisData = makeAnalysisData(
          events: [ev1, ev2],
          sexualActivities: sexualActivities,
          activityCountsThisYear: {'catA': 2},
        );

        await tester.pumpWidget(
          Provider<PreferencesService>.value(
            value: prefsService,
            child: MaterialApp(
              home: Scaffold(
                body: PropertyTrendsChart(
                  data: analysisData,
                  showTypeFilter: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // The widget should show chips for available properties
        expect(find.text('Prop One'), findsOneWidget);
        expect(find.text('Prop Two'), findsOneWidget);

        // Because persisted selection contains 'p1', the prompt should not show
        expect(find.text('Select at least one activity'), findsNothing);
      },
    );

    testWidgets(
      'reacts to persisted selection changes via PreferencesService notifier',
      (tester) async {
        // Start with 'p1' selected
        SharedPreferences.setMockInitialValues({
          'pref_activity_selected_ids': jsonEncode(['p1']),
        });

        final prefsService = await PreferencesService.build();

        final now = DateTime.now();
        final ev1 = makeEvent(
          date: now.subtract(const Duration(days: 5)),
          activityId: 'catA',
          propertyIds: ['p1'],
        );
        final ev2 = makeEvent(
          date: now.subtract(const Duration(days: 15)),
          activityId: 'catA',
          propertyIds: ['p2'],
        );

        final sexualActivities = <String, SexualActivity>{
          'p1': const SexualActivity(id: 'p1', name: 'Prop One'),
          'p2': const SexualActivity(id: 'p2', name: 'Prop Two'),
        };

        final analysisData = makeAnalysisData(
          events: [ev1, ev2],
          sexualActivities: sexualActivities,
          activityCountsThisYear: {'catA': 2},
        );

        await tester.pumpWidget(
          Provider<PreferencesService>.value(
            value: prefsService,
            child: MaterialApp(
              home: Scaffold(
                body: PropertyTrendsChart(
                  data: analysisData,
                  showTypeFilter: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially, prompt is hidden because p1 was selected
        expect(find.text('Select at least one activity'), findsNothing);

        // Clear selection via the service
        await prefsService.setActivitySelectedIds([]);
        await tester.pumpAndSettle();

        // Now the prompt should appear
        expect(find.text('Select at least one activity'), findsOneWidget);

        // Set selection to p2 and verify prompt disappears and Prop Two is visible
        await prefsService.setActivitySelectedIds(['p2']);
        await tester.pumpAndSettle();

        expect(find.text('Select at least one activity'), findsNothing);
        expect(find.text('Prop Two'), findsOneWidget);
      },
    );
  });
}
