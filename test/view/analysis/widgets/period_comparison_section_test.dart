import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/analysis/models/analysis_data.dart';
import 'package:indulge/view/analysis/utils/analysis_calculator.dart';
import 'package:indulge/view/analysis/widgets/period_comparison/period_comparison_section.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import '../utils/analysis_calculator_test.mocks.dart';

void main() {
  group('PeriodComparisonSection', () {
    late MockSexualEventsProvider mockProvider;
    late EventState mockState;
    late Person mePerson;
    late Person partner1;
    late Person partner2;
    late SexualActivityCategory oralType;
    late SexualActivity activityProp;

    setUp(() {
      mockProvider = MockSexualEventsProvider();

      mePerson = Person(
        id: 'me',
        name: const Name(given: 'Me'),
        isSelf: true,
        date: DateTime(2023, 1, 1),
      );

      partner1 = Person(
        id: 'partner1',
        name: const Name(given: 'Partner', family: '1'),
        isSelf: false,
        date: DateTime(2023, 1, 1),
      );

      partner2 = Person(
        id: 'partner2',
        name: const Name(given: 'Partner', family: '2'),
        isSelf: false,
        date: DateTime(2023, 1, 1),
      );

      oralType = const SexualActivityCategory(id: 'oral', name: 'Oral');
      activityProp = const SexualActivity(id: 'bj', name: 'Blowjob');

      mockState = EventState(
        sexualActivityCategories: {'oral': oralType},
        sexualActivities: {'bj': activityProp},
      );

      when(mockProvider.state).thenReturn(mockState);
      when(
        mockProvider.getAllPersons(),
      ).thenAnswer((_) async => [mePerson, partner1, partner2]);
    });

    SexualEvent createEvent({
      required DateTime date,
      List<String> partnerIds = const [],
      List<String> propertyIds = const [],
    }) {
      final participants = <ActivityParticipant>[];

      participants.add(
        ActivityParticipant(
          participant: const Reference(reference: 'me'),
          activityCounts: [],
        ),
      );

      for (final pid in partnerIds) {
        final activityCounts = <ActivityCount>[];
        for (final propId in propertyIds) {
          activityCounts.add(
            ActivityCount(
              activityReference: Reference(reference: propId),
              count: 1,
            ),
          );
        }

        participants.add(
          ActivityParticipant(
            participant: Reference(reference: pid),
            activityCounts: activityCounts,
          ),
        );
      }

      // If solo (no partners), add properties to "Me"
      if (partnerIds.isEmpty) {
        final activityCounts = <ActivityCount>[];
        for (final propId in propertyIds) {
          activityCounts.add(
            ActivityCount(
              activityReference: Reference(reference: propId),
              count: 1,
            ),
          );
        }
        participants[0] = participants[0].copyWith(
          activityCounts: activityCounts,
        );
      }

      return SexualEvent(
        id: const Uuid().v4(),
        date: date,
        activities: [
          EventActivity(
            category: const Reference(reference: 'oral'),
            participants: participants,
          ),
        ],
      );
    }

    /// Helper to build the widget under test in custom mode with explicit
    /// date ranges, which makes assertions deterministic.
    Widget buildSection(
      AnalysisData data, {
      PeriodPreset preset = PeriodPreset.custom,
      DateTimeRange? firstPeriod,
      DateTimeRange? secondPeriod,
      ValueChanged<PeriodPreset>? onPresetChanged,
      ValueChanged<DateTimeRange?>? onFirstChanged,
      ValueChanged<DateTimeRange?>? onSecondChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PeriodComparisonSection(
              data: data,
              selectedPreset: preset,
              customFirstPeriod: firstPeriod,
              customSecondPeriod: secondPeriod,
              onPresetChanged: onPresetChanged ?? (_) {},
              onCustomFirstPeriodChanged: onFirstChanged ?? (_) {},
              onCustomSecondPeriodChanged: onSecondChanged ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('correctly counts stats and excludes "Me" from participants', (
      tester,
    ) async {
      final realNow = DateTime.now();
      final recentEventDate = realNow.subtract(const Duration(days: 5));
      final olderEventDate = realNow.subtract(const Duration(days: 35));

      final eventRecentSolo = createEvent(
        date: recentEventDate,
        partnerIds: [],
        propertyIds: ['bj'],
      );

      final eventRecentCouple = createEvent(
        date: recentEventDate.subtract(const Duration(hours: 1)),
        partnerIds: ['partner1'],
        propertyIds: ['bj'],
      );

      final eventOldGroup = createEvent(
        date: olderEventDate,
        partnerIds: ['partner1', 'partner2'],
        propertyIds: ['bj'],
      );

      final recentEvents = [eventRecentSolo, eventRecentCouple, eventOldGroup];

      final recentData = await AnalysisCalculator.calculate(
        recentEvents,
        mockProvider,
      );

      // Verify data calculation before UI
      expect(recentData.events.length, 3, reason: 'Total events should be 3');

      expect(
        recentData.personCounts.containsKey('me'),
        false,
        reason: 'Me should not be in personCounts',
      );
      expect(
        recentData.personCounts.containsKey('partner1'),
        true,
        reason: 'Partner1 should be in personCounts',
      );

      expect(
        recentData.eventsByType[AnalysisEventType.solo]?.length,
        1,
        reason: 'Should have 1 solo event',
      );
      expect(
        recentData.eventsByType[AnalysisEventType.couple]?.length,
        1,
        reason: 'Should have 1 couple event',
      );
      expect(
        recentData.eventsByType[AnalysisEventType.group]?.length,
        1,
        reason: 'Should have 1 group event',
      );

      // Use custom preset with explicit date ranges so the test is
      // deterministic regardless of when it runs.
      //
      // Period 1 (baseline): covers the two recent events (solo + couple)
      // Period 2: covers the older group event
      final period1 = DateTimeRange(
        start: realNow.subtract(const Duration(days: 30)),
        end: realNow,
      );
      final period2 = DateTimeRange(
        start: realNow.subtract(const Duration(days: 61)),
        end: realNow.subtract(const Duration(days: 31)),
      );

      await tester.pumpWidget(
        buildSection(
          recentData,
          preset: PeriodPreset.custom,
          firstPeriod: period1,
          secondPeriod: period2,
        ),
      );

      // Period 1 (recent 30 days): Solo + Couple = 2 events
      // Period 2 (previous 30 days): Group = 1 event
      //
      // Stats Breakdown:
      // Events: P1=2, P2=1
      // Participants (Me excluded): P1=1 (Partner1), P2=2 (Partner1, Partner2)
      // Total Activities: P1=2, P2=1
      // Unique Activities: P1=1 (BJ), P2=1 (BJ)
      //
      // Event types:
      // P1: Solo=1, Couple=1, Group=0
      // P2: Solo=0, Couple=0, Group=1
      //
      // '2' appears: Events P1(2), Participants P2(2), Total Activities P1(2) => 3
      // '1' appears: Events P2(1), Participants P1(1), Total Activities P2(1),
      //              Unique Activities P1(1), Unique Activities P2(1),
      //              Solo P1(1), Couple P1(1), Group P2(1) => 8
      // '3' must NOT appear (would mean "Me" was included as a participant)

      expect(find.text('Events'), findsWidgets);

      expect(find.text('2'), findsNWidgets(3));
      expect(find.text('1'), findsNWidgets(8));
      expect(find.text('3'), findsNothing);

      expect(find.text('Solo'), findsWidgets);
      expect(find.text('Couple'), findsWidgets);
      expect(find.text('Group'), findsWidgets);
    });

    testWidgets('displays preset chips and custom date pickers', (
      tester,
    ) async {
      final recentData = await AnalysisCalculator.calculate([], mockProvider);

      await tester.pumpWidget(
        buildSection(recentData, preset: PeriodPreset.custom),
      );

      // All three preset chips should be visible
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // In custom mode the two period selectors should show
      expect(find.text('Period 1 (baseline)'), findsOneWidget);
      expect(find.text('Period 2'), findsOneWidget);
    });

    testWidgets('hides custom date pickers for non-custom presets', (
      tester,
    ) async {
      final recentData = await AnalysisCalculator.calculate([], mockProvider);

      await tester.pumpWidget(
        buildSection(recentData, preset: PeriodPreset.lastMonthVsThisMonth),
      );

      // Custom period selectors should NOT be present
      expect(find.text('Period 1 (baseline)'), findsNothing);
      // The generic "Period 1" / "Period 2" labels appear in the read-only
      // summary AND in the stat comparison rows, so just check they exist.
      expect(find.text('Period 1'), findsWidgets);
      expect(find.text('Period 2'), findsWidgets);
    });

    testWidgets('calls onPresetChanged when a preset chip is tapped', (
      tester,
    ) async {
      PeriodPreset? changedTo;
      final recentData = await AnalysisCalculator.calculate([], mockProvider);

      await tester.pumpWidget(
        buildSection(
          recentData,
          preset: PeriodPreset.custom,
          onPresetChanged: (p) => changedTo = p,
        ),
      );

      // Tap the "Month" preset chip
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(changedTo, PeriodPreset.lastMonthVsThisMonth);
    });

    testWidgets('shows subtitle matching the selected preset', (tester) async {
      final recentData = await AnalysisCalculator.calculate([], mockProvider);

      // Last month vs this month
      await tester.pumpWidget(
        buildSection(recentData, preset: PeriodPreset.lastMonthVsThisMonth),
      );
      expect(find.text('Last month vs this month'), findsOneWidget);

      // Last week vs this week
      await tester.pumpWidget(
        buildSection(recentData, preset: PeriodPreset.lastWeekVsThisWeek),
      );
      expect(find.text('Last week vs this week'), findsOneWidget);

      // Custom
      await tester.pumpWidget(
        buildSection(recentData, preset: PeriodPreset.custom),
      );
      expect(find.text('Pick any two date ranges'), findsOneWidget);
    });

    testWidgets('month preset shows comparison results with data', (
      tester,
    ) async {
      // Create events spanning this month and last month
      final now = DateTime.now();
      final firstOfThisMonth = DateTime(now.year, now.month, 1);
      final lastMonthDate = firstOfThisMonth.subtract(const Duration(days: 5));
      final thisMonthDate = firstOfThisMonth.add(const Duration(days: 1));

      // Guard: only run the "this month" part if we are past the 1st
      // (thisMonthDate must be <= now)
      if (thisMonthDate.isAfter(now)) return;

      final lastMonthEvent = createEvent(
        date: lastMonthDate,
        partnerIds: ['partner1'],
        propertyIds: ['bj'],
      );
      final thisMonthEvent = createEvent(
        date: thisMonthDate,
        partnerIds: ['partner2'],
        propertyIds: ['bj'],
      );

      final data = await AnalysisCalculator.calculate([
        lastMonthEvent,
        thisMonthEvent,
      ], mockProvider);

      await tester.pumpWidget(
        buildSection(data, preset: PeriodPreset.lastMonthVsThisMonth),
      );

      // Comparison results should be visible
      expect(find.text('Events'), findsWidgets);
      expect(find.text('Unique Participants'), findsOneWidget);
      expect(find.text('Total Activities'), findsOneWidget);
      expect(find.text('Unique Activities'), findsOneWidget);
      expect(find.text('Event Types'), findsOneWidget);
    });

    testWidgets('custom preset with no periods selected shows no comparison', (
      tester,
    ) async {
      final recentData = await AnalysisCalculator.calculate([], mockProvider);

      await tester.pumpWidget(
        buildSection(
          recentData,
          preset: PeriodPreset.custom,
          firstPeriod: null,
          secondPeriod: null,
        ),
      );

      // Without both periods, comparison stats should not render
      expect(find.text('Unique Participants'), findsNothing);
      expect(find.text('Total Activities'), findsNothing);
    });
  });
}
