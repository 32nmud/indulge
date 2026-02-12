/*
  indulge/test/view/analysis/widgets/monthly_activity_chart_test.dart

  Widget tests for MonthlyActivityChart and ActivityBreakdownPage to verify
  activity filter persistence and synchronization via PreferencesService.
*/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indulge/view/analysis/widgets/overview/monthly_activity_chart.dart';
import 'package:indulge/view/analysis/widgets/activity_breakdown/activity_breakdown_page.dart';
import 'package:indulge/services/preferences_service.dart';
import 'package:indulge/view/analysis/models/analysis_data.dart';
import 'package:indulge/data/models.dart';

void main() {
  group(
    'MonthlyActivityChart & ActivityBreakdownPage - activity filter persistence',
    () {
      setUp(() async {
        // Reset mock SharedPreferences before each test.
        SharedPreferences.setMockInitialValues({});
      });

      // Helper to construct a minimal AnalysisData instance suitable for these widgets.
      AnalysisData makeAnalysisData({
        List<SexualEvent> events = const [],
        Map<String, SexualActivityCategory> activityCategories = const {},
        Map<String, SexualActivity> sexualActivities = const {},
        Map<String, int> activityCountsThisYear = const {},
        Map<String, int> monthlyCounts = const {},
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
          sexualActivities: sexualActivities,
          sexualActivityPartnerCounts: const {},
          categoryPartnerCountsThisYear: const {},
          sexualActivityPartnerCountsThisYear: const {},
          categoryActivityPartnerCountsThisYear: const {},
          dailyCounts: const {},
          dayOfWeekCounts: const {},
          monthlyCounts: monthlyCounts,
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
        required String categoryId,
        List<String> partnerIds = const [],
      }) {
        final participants = <ActivityParticipant>[];

        participants.add(
          ActivityParticipant(
            participant: const Reference(reference: 'me'),
            activityCounts: const [],
          ),
        );

        for (final pid in partnerIds) {
          participants.add(
            ActivityParticipant(
              participant: Reference(reference: pid),
              activityCounts: const [],
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

      testWidgets(
        'MonthlyActivityChart reads persisted activity filter and selects chip',
        (tester) async {
          // Persist the 'Solo' filter before building the service / widget.
          SharedPreferences.setMockInitialValues({
            'pref_activity_filter': AnalysisEventType.solo.index,
          });

          final prefsService = await PreferencesService.build();

          // Minimal analysis data - monthly chart just needs some events to exist.
          final now = DateTime.now();
          final event = makeEvent(
            date: now.subtract(const Duration(days: 3)),
            categoryId: 'catX',
          );

          final analysisData = makeAnalysisData(
            events: [event],
            activityCategories: {
              'catX': const SexualActivityCategory(id: 'catX', name: 'Cat X'),
            },
            activityCountsThisYear: {'catX': 1},
            monthlyCounts: {'2023-01': 1},
          );

          await tester.pumpWidget(
            Provider<PreferencesService>.value(
              value: prefsService,
              child: MaterialApp(
                home: Scaffold(body: MonthlyActivityChart(data: analysisData)),
              ),
            ),
          );

          // Allow post-frame init to run and settle.
          await tester.pumpAndSettle();

          // The 'Solo' FilterChip should be selected as per persisted preference.
          final soloChipFinder = find.widgetWithText(FilterChip, 'Solo');
          expect(soloChipFinder, findsOneWidget);

          final FilterChip soloChipWidget = tester.widget<FilterChip>(
            soloChipFinder,
          );
          expect(soloChipWidget.selected, isTrue);
        },
      );

      testWidgets(
        'ActivityBreakdownPage onTypeChanged persists selection via PreferencesService',
        (tester) async {
          // Start with no persisted selection
          SharedPreferences.setMockInitialValues({});

          final prefsService = await PreferencesService.build();

          final analysisData = makeAnalysisData(
            events: const [],
            activityCategories: {
              'a1': const SexualActivityCategory(id: 'a1', name: 'Act 1'),
            },
            activityCountsThisYear: {'a1': 1},
            monthlyCounts: {'2023-01': 1},
          );

          // Build the ActivityBreakdownPage and pass an onTypeChanged that persists via the provided service.
          await tester.pumpWidget(
            Provider<PreferencesService>.value(
              value: prefsService,
              child: MaterialApp(
                home: Scaffold(
                  body: ActivityBreakdownPage(
                    data: analysisData,
                    selectedType: null,
                    onTypeChanged: (type) {
                      // Persist selection when user picks a chip.
                      // onTypeChanged is synchronous; call the async setter and ignore the Future.
                      prefsService.setActivityFilter(type);
                    },
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Tap the 'Couple' chip to simulate user selection.
          final coupleChipFinder = find.widgetWithText(FilterChip, 'Couple');
          expect(coupleChipFinder, findsOneWidget);

          await tester.tap(coupleChipFinder);
          await tester.pumpAndSettle();

          // Underlying SharedPreferences should contain the persisted index for 'couple'
          final prefs = await SharedPreferences.getInstance();
          expect(
            prefs.getInt('pref_activity_filter'),
            equals(AnalysisEventType.couple.index),
          );

          // The service getter should reflect the persisted value
          expect(
            prefsService.getActivityFilter(),
            equals(AnalysisEventType.couple),
          );
        },
      );
    },
  );
}
