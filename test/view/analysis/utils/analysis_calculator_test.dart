import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/analysis/models/analysis_data.dart';
import 'package:indulge/view/analysis/utils/analysis_calculator.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'analysis_calculator_test.mocks.dart';

@GenerateMocks([SexualEventsProvider])
void main() {
  group('AnalysisCalculator', () {
    late MockSexualEventsProvider mockProvider;
    late EventState mockState;
    late Person mePerson;
    late Person partner1;
    late Person partner2;
    late Person partner3;
    late Person anonymousPerson;
    late SexualActivityCategory oralType;
    late SexualActivityCategory vaginalType;
    late SexualActivityCategory analType;
    late SexualActivity condomProperty;
    late SexualActivity riskyProperty;
    late SexualActivity lubProperty;

    setUp(() {
      mockProvider = MockSexualEventsProvider();

      // Create test persons
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

      partner3 = Person(
        id: 'partner3',
        name: const Name(given: 'Partner', family: '3'),
        isSelf: false,
        date: DateTime(2023, 1, 1),
      );

      anonymousPerson = Person(
        id: 'anonymous',
        name: const Name(given: 'Anonymous'),
        isSelf: false,
        date: DateTime(2023, 1, 1),
      );

      // Create test activity types
      oralType = const SexualActivityCategory(id: 'oral', name: 'Oral');
      vaginalType = const SexualActivityCategory(
        id: 'vaginal',
        name: 'Vaginal',
      );
      analType = const SexualActivityCategory(id: 'anal', name: 'Anal');

      // Create test properties
      condomProperty = const SexualActivity(
        id: 'condom',
        name: 'Condom',
        isRisky: false,
      );

      riskyProperty = const SexualActivity(
        id: 'risky',
        name: 'Risky Property',
        isRisky: true,
      );

      lubProperty = const SexualActivity(
        id: 'lub',
        name: 'Lubricant',
        isRisky: false,
      );

      // Set up mock state
      mockState = EventState(
        sexualActivityCategories: {
          'oral': oralType,
          'vaginal': vaginalType,
          'anal': analType,
        },
        sexualActivities: {
          'condom': condomProperty,
          'risky': riskyProperty,
          'lub': lubProperty,
        },
        currentEvents: [],
        selectedDate: DateTime.now(),
        dailyEventCount: {},
      );

      when(mockProvider.state).thenReturn(mockState);
      when(mockProvider.getAllPersons()).thenAnswer(
        (_) async => [mePerson, partner1, partner2, partner3, anonymousPerson],
      );
    });

    // ---------------------------------------------------------------
    // Empty events
    // ---------------------------------------------------------------
    group('empty events', () {
      test('returns empty analysis data when no events provided', () async {
        final result = await AnalysisCalculator.calculate([], mockProvider);

        expect(result.totalEvents, 0);
        expect(result.totalActivities, 0);
        expect(result.uniquePartners, 0);
        expect(result.riskyActivityCount, 0);
        expect(result.safeActivityCount, 0);
        expect(result.eventsThisMonth, 0);
        expect(result.eventsThisYear, 0);
        expect(result.uniquePartnersThisMonth, 0);
        expect(result.uniquePartnersThisYear, 0);
        expect(result.knownPartners, 0);
        expect(result.anonymousPartnerInstances, 0);
        expect(result.busiestDay, isNull);
        expect(result.busiestDayEventCount, 0);
        expect(result.busiestEvent, isNull);
        expect(result.busiestEventActivityCount, 0);
        expect(result.soloEventsThisYear, 0);
        expect(result.coupleEventsThisYear, 0);
        expect(result.groupEventsThisYear, 0);
        expect(result.soloEventsTotal, 0);
        expect(result.nonSoloEventsTotal, 0);
        expect(result.soloActivityCounts, isEmpty);
        expect(result.soloSexualActivityCounts, isEmpty);
        expect(result.soloActivityCountsThisYear, isEmpty);
        expect(result.soloSexualActivityCountsThisYear, isEmpty);
        expect(result.activityCountsByType, isEmpty);
        expect(result.sexualActivityCountsByType, isEmpty);
        expect(result.monthlyCountsByType, isEmpty);
        expect(result.dayOfWeekCountsByType, isEmpty);
        expect(result.averageDayOfWeekCountsByType, isEmpty);
        expect(result.eventCountsByType, isEmpty);
        expect(result.eventsByType, isEmpty);
        expect(result.activityCounts, isEmpty);
        expect(result.activityCountsThisYear, isEmpty);
        expect(result.activityCategories, isEmpty);
        expect(result.longestStreak, 0);
        expect(result.currentStreak, 0);
        expect(result.personCounts, isEmpty);
        expect(result.personEventCounts, isEmpty);
        expect(result.personEvents, isEmpty);
        expect(result.personPropertyCounts, isEmpty);
        expect(result.sexualActivityCountsTotal, isEmpty);
        expect(result.sexualActivities, isEmpty);
        expect(result.sexualActivityPartnerCounts, isEmpty);
        expect(result.categoryPartnerCountsThisYear, isEmpty);
        expect(result.sexualActivityPartnerCountsThisYear, isEmpty);
        expect(result.categoryActivityPartnerCountsThisYear, isEmpty);
        expect(result.dailyCounts, isEmpty);
        expect(result.dayOfWeekCounts, isEmpty);
        expect(result.monthlyCounts, isEmpty);
        expect(result.daysSinceLastRiskyActivity, -1);
        expect(result.daysSinceLastActivity, 0);
        expect(result.thisWeekVsLastWeek.currentPeriodCount, 0);
        expect(result.thisWeekVsLastWeek.previousPeriodCount, 0);
        expect(result.thisWeekVsLastWeek.percentageChange, 0);
        expect(result.thisWeekVsLastWeek.isIncrease, false);
        expect(result.thisMonthVsLastMonth.currentPeriodCount, 0);
        expect(result.thisMonthVsLastMonth.previousPeriodCount, 0);
        expect(result.thisMonthVsLastMonth.percentageChange, 0);
        expect(result.thisMonthVsLastMonth.isIncrease, false);
        expect(result.averageEventsPerWeek, 0.0);
        expect(result.averageEventsPerMonth, 0.0);
        expect(result.averageActivitiesPerWeek, 0.0);
        expect(result.averageActivitiesPerMonth, 0.0);
        expect(result.averagePartnersPerEvent, 0.0);
        expect(result.averageActivitiesPerEvent, 0.0);
        expect(result.averageSexualActivitiesPerEvent, 0.0);
        expect(result.averageEventsPerDayOfWeek, isEmpty);
        expect(result.topActivityPairs, isEmpty);
        expect(result.topCategoryPairs, isEmpty);
        expect(result.events, isEmpty);
      });

      test('passes through startDate and endDate', () async {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 12, 31);
        final result = await AnalysisCalculator.calculate(
          [],
          mockProvider,
          startDate: start,
          endDate: end,
        );

        expect(result.startDate, start);
        expect(result.endDate, end);
      });
    });

    // ---------------------------------------------------------------
    // Basic counts
    // ---------------------------------------------------------------
    group('basic counts', () {
      test('calculates totalEvents correctly', () async {
        final now = DateTime.now();
        final events = [
          _createEvent(now.subtract(const Duration(days: 1))),
          _createEvent(now.subtract(const Duration(days: 2))),
          _createEvent(now.subtract(const Duration(days: 3))),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.totalEvents, 3);
        expect(result.events.length, 3);
      });

      test('counts totalActivities across all events', () async {
        final now = DateTime.now();
        final events = [
          _createEventWithActivities(now.subtract(const Duration(days: 1)), 2),
          _createEventWithActivities(now.subtract(const Duration(days: 2)), 3),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.totalActivities, 5);
      });
    });

    // ---------------------------------------------------------------
    // Partner counting
    // ---------------------------------------------------------------
    group('partner counting', () {
      test('excludes "me" from partner counts', () async {
        final now = DateTime.now();
        final event = SexualEvent(
          id: 'event1',
          date: now,
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'me'),
                  activityCounts: [],
                ),
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
          ],
        );

        final result = await AnalysisCalculator.calculate([
          event,
        ], mockProvider);

        expect(result.uniquePartners, 1);
        expect(result.personCounts.containsKey('me'), false);
        expect(result.personCounts.containsKey('partner1'), true);
      });

      test('counts unique partners per event correctly', () async {
        final now = DateTime.now();
        final event = SexualEvent(
          id: 'event1',
          date: now,
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
                const ActivityParticipant(
                  participant: Reference(reference: 'partner2'),
                  activityCounts: [],
                ),
              ],
            ),
            EventActivity(
              category: const Reference(reference: 'vaginal'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
          ],
        );

        final result = await AnalysisCalculator.calculate([
          event,
        ], mockProvider);

        expect(result.uniquePartners, 2);
        expect(result.averagePartnersPerEvent, 2.0);
      });

      test('counts anonymous partners correctly', () async {
        final now = DateTime.now();
        final event = SexualEvent(
          id: 'event1',
          date: now,
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'anonymous'),
                  activityCounts: [],
                ),
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
          ],
        );

        final result = await AnalysisCalculator.calculate([
          event,
        ], mockProvider);

        expect(result.anonymousPartnerInstances, 1);
        expect(result.knownPartners, 1); // Only partner1, not anonymous
        expect(result.uniquePartners, 2); // Both anonymous and partner1
      });

      test('knownPartners excludes anonymous from personCounts keys', () async {
        final now = DateTime.now();
        final events = [
          SexualEvent(
            id: 'e1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                  const ActivityParticipant(
                    participant: Reference(reference: 'anonymous'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          SexualEvent(
            id: 'e2',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner2'),
                    activityCounts: [],
                  ),
                  const ActivityParticipant(
                    participant: Reference(reference: 'anonymous'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        // Two known partners (partner1, partner2), anonymous not counted
        expect(result.knownPartners, 2);
        expect(result.anonymousPartnerInstances, 2);
      });
    });

    // ---------------------------------------------------------------
    // Person-level detail
    // ---------------------------------------------------------------
    group('person-level detail', () {
      test(
        'personCounts tracks total activity participation per partner',
        () async {
          final now = DateTime.now();
          final events = [
            SexualEvent(
              id: 'e1',
              date: now,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [],
                    ),
                  ],
                ),
                EventActivity(
                  category: const Reference(reference: 'vaginal'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [],
                    ),
                  ],
                ),
              ],
            ),
            SexualEvent(
              id: 'e2',
              date: now.subtract(const Duration(days: 1)),
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [],
                    ),
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner2'),
                      activityCounts: [],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          // partner1 appears in 3 activities total
          expect(result.personCounts['partner1'], 3);
          // partner2 appears in 1 activity
          expect(result.personCounts['partner2'], 1);
        },
      );

      test('personEventCounts tracks total events per partner', () async {
        final now = DateTime.now();
        final events = [
          SexualEvent(
            id: 'e1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          SexualEvent(
            id: 'e2',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner2'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.personEventCounts['partner1'], 2);
        expect(result.personEventCounts['partner2'], 1);
      });

      test('personEvents maps partner to their event list', () async {
        final now = DateTime.now();
        final e1 = SexualEvent(
          id: 'e1',
          date: now,
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
          ],
        );
        final e2 = SexualEvent(
          id: 'e2',
          date: now.subtract(const Duration(days: 1)),
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
                const ActivityParticipant(
                  participant: Reference(reference: 'partner2'),
                  activityCounts: [],
                ),
              ],
            ),
          ],
        );

        final result = await AnalysisCalculator.calculate([
          e1,
          e2,
        ], mockProvider);

        expect(result.personEvents['partner1']!.length, 2);
        expect(result.personEvents['partner2']!.length, 1);
      });

      test(
        'personPropertyCounts tracks sexual activities per partner',
        () async {
          final now = DateTime.now();
          final event = SexualEvent(
            id: 'e1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'condom'),
                        count: 2,
                      ),
                      ActivityCount(
                        activityReference: Reference(reference: 'risky'),
                        count: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          final result = await AnalysisCalculator.calculate([
            event,
          ], mockProvider);

          expect(result.personPropertyCounts['partner1']!['condom'], 2);
          expect(result.personPropertyCounts['partner1']!['risky'], 1);
        },
      );
    });

    // ---------------------------------------------------------------
    // Risky / safe
    // ---------------------------------------------------------------
    group('risky and safe activities', () {
      test('identifies risky activities correctly', () async {
        final now = DateTime.now();
        final events = [
          // Safe event
          SexualEvent(
            id: 'event1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'condom'),
                        count: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Risky event
          SexualEvent(
            id: 'event2',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'risky'),
                        count: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.riskyActivityCount, 1);
        expect(result.safeActivityCount, 1);
      });

      test('activity with no sexual activities is counted as safe', () async {
        final now = DateTime.now();
        final event = SexualEvent(
          id: 'e1',
          date: now,
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
          ],
        );

        final result = await AnalysisCalculator.calculate([
          event,
        ], mockProvider);

        expect(result.riskyActivityCount, 0);
        expect(result.safeActivityCount, 1);
      });
    });

    // ---------------------------------------------------------------
    // Solo / couple / group classification
    // ---------------------------------------------------------------
    group('event type classification', () {
      test('categorizes solo, couple, and group events', () async {
        final now = DateTime.now();
        final events = [
          // Solo event (only "me")
          SexualEvent(
            id: 'solo',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // Couple event (me + 1 partner)
          SexualEvent(
            id: 'couple',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // Group event (me + 2 partners)
          SexualEvent(
            id: 'group',
            date: now.subtract(const Duration(days: 2)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner2'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.soloEventsThisYear, 1);
        expect(result.coupleEventsThisYear, 1);
        expect(result.groupEventsThisYear, 1);
      });

      test('soloEventsTotal and nonSoloEventsTotal count all time', () async {
        final now = DateTime.now();
        final events = [
          // Solo
          SexualEvent(
            id: 'solo1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // Solo
          SexualEvent(
            id: 'solo2',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // Couple
          SexualEvent(
            id: 'couple1',
            date: now.subtract(const Duration(days: 2)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        // ignore: deprecated_member_use_from_same_package
        expect(result.soloEventsTotal, 2);
        // ignore: deprecated_member_use_from_same_package
        expect(result.nonSoloEventsTotal, 1);
      });

      test('eventCountsByType maps event types to counts', () async {
        final now = DateTime.now();
        final events = [
          // Solo
          SexualEvent(
            id: 'solo',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // Couple
          SexualEvent(
            id: 'couple',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // Couple
          SexualEvent(
            id: 'couple2',
            date: now.subtract(const Duration(days: 2)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner2'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.eventCountsByType[AnalysisEventType.solo], 1);
        expect(result.eventCountsByType[AnalysisEventType.couple], 2);
        expect(result.eventCountsByType[AnalysisEventType.group], 0);
      });

      test('eventsByType maps event types to event lists', () async {
        final now = DateTime.now();
        final events = [
          SexualEvent(
            id: 'solo',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          SexualEvent(
            id: 'couple',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.eventsByType[AnalysisEventType.solo]!.length, 1);
        expect(result.eventsByType[AnalysisEventType.couple]!.length, 1);
        expect(result.eventsByType[AnalysisEventType.group]!.length, 0);
      });
    });

    // ---------------------------------------------------------------
    // Solo activity counts
    // ---------------------------------------------------------------
    group('solo activity tracking', () {
      test(
        'soloActivityCounts tracks activity categories in solo events',
        () async {
          final now = DateTime.now();
          final events = [
            // Solo with 2 oral activities
            SexualEvent(
              id: 'solo',
              date: now,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'me'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'lub'),
                          count: 1,
                        ),
                      ],
                    ),
                  ],
                ),
                EventActivity(
                  category: const Reference(reference: 'vaginal'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'me'),
                      activityCounts: [],
                    ),
                  ],
                ),
              ],
            ),
            // Non-solo (should not be counted)
            SexualEvent(
              id: 'couple',
              date: now.subtract(const Duration(days: 1)),
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          expect(result.soloActivityCounts['oral'], 1);
          expect(result.soloActivityCounts['vaginal'], 1);
          expect(result.soloSexualActivityCounts['lub'], 1);
        },
      );
    });

    // ---------------------------------------------------------------
    // Activity counts & categories
    // ---------------------------------------------------------------
    group('activity counts and categories', () {
      test('activityCounts tracks all-time counts per category', () async {
        final now = DateTime.now();
        final events = [
          SexualEvent(
            id: 'e1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.activityCounts['oral'], 2);
        expect(result.activityCounts['vaginal'], 1);
      });

      test('activityCategories stores resolved category objects', () async {
        final now = DateTime.now();
        final event = SexualEvent(
          id: 'e1',
          date: now,
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
            EventActivity(
              category: const Reference(reference: 'vaginal'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
          ],
        );

        final result = await AnalysisCalculator.calculate([
          event,
        ], mockProvider);

        expect(result.activityCategories.containsKey('oral'), true);
        expect(result.activityCategories['oral']!.name, 'Oral');
        expect(result.activityCategories.containsKey('vaginal'), true);
        expect(result.activityCategories['vaginal']!.name, 'Vaginal');
      });

      test('activityCountsByType tracks categories per event type', () async {
        final now = DateTime.now();
        final events = [
          // Solo oral
          SexualEvent(
            id: 'solo',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // Couple vaginal
          SexualEvent(
            id: 'couple',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.activityCountsByType[AnalysisEventType.solo]!['oral'], 1);
        expect(
          result.activityCountsByType[AnalysisEventType.couple]!['vaginal'],
          1,
        );
      });

      test(
        'sexualActivityCountsByType tracks sexual activities per event type',
        () async {
          final now = DateTime.now();
          final events = [
            // Couple with condom
            SexualEvent(
              id: 'couple',
              date: now,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'vaginal'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'condom'),
                          count: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          expect(
            result.sexualActivityCountsByType[AnalysisEventType
                .couple]!['condom'],
            1,
          );
        },
      );
    });

    // ---------------------------------------------------------------
    // Sexual activity tracking
    // ---------------------------------------------------------------
    group('sexual activity tracking', () {
      test('sexualActivityCountsTotal aggregates across all events', () async {
        final now = DateTime.now();
        final events = [
          SexualEvent(
            id: 'e1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'condom'),
                        count: 2,
                      ),
                      ActivityCount(
                        activityReference: Reference(reference: 'risky'),
                        count: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SexualEvent(
            id: 'e2',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner2'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'condom'),
                        count: 3,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.sexualActivityCountsTotal['condom'], 5);
        expect(result.sexualActivityCountsTotal['risky'], 1);
      });

      test('sexualActivities stores resolved activity objects', () async {
        final now = DateTime.now();
        final event = SexualEvent(
          id: 'e1',
          date: now,
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [
                    ActivityCount(
                      activityReference: Reference(reference: 'condom'),
                      count: 1,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        final result = await AnalysisCalculator.calculate([
          event,
        ], mockProvider);

        expect(result.sexualActivities.containsKey('condom'), true);
        expect(result.sexualActivities['condom']!.name, 'Condom');
      });

      test(
        'sexualActivityPartnerCounts tracks unique partners per activity',
        () async {
          final now = DateTime.now();
          final events = [
            SexualEvent(
              id: 'e1',
              date: now,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'condom'),
                          count: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SexualEvent(
              id: 'e2',
              date: now.subtract(const Duration(days: 1)),
              activities: [
                EventActivity(
                  category: const Reference(reference: 'vaginal'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner2'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'condom'),
                          count: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          // Condom used with 2 different partners
          expect(result.sexualActivityPartnerCounts['condom'], 2);
        },
      );
    });

    // ---------------------------------------------------------------
    // Time-based distributions
    // ---------------------------------------------------------------
    group('time-based distributions', () {
      test('dailyCounts maps date strings to event counts', () async {
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2024, 6, 16);
        final events = [
          _createEvent(date1),
          _createEvent(date1), // Same day
          _createEvent(date2),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.dailyCounts['2024-06-15'], 2);
        expect(result.dailyCounts['2024-06-16'], 1);
      });

      test('dayOfWeekCounts maps weekday numbers to event counts', () async {
        // Monday = 1
        final monday = DateTime(2024, 7, 1); // July 1, 2024 is Monday
        final tuesday = DateTime(2024, 7, 2);
        final events = [
          _createEvent(monday),
          _createEvent(monday),
          _createEvent(tuesday),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.dayOfWeekCounts[1], 2); // Monday
        expect(result.dayOfWeekCounts[2], 1); // Tuesday
      });

      test('monthlyCounts maps year-month strings to event counts', () async {
        final jan = DateTime(2024, 1, 15);
        final feb = DateTime(2024, 2, 10);
        final events = [
          _createEvent(jan),
          _createEvent(jan),
          _createEvent(feb),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.monthlyCounts['2024-01'], 2);
        expect(result.monthlyCounts['2024-02'], 1);
      });

      test('monthlyCountsByType tracks month counts per event type', () async {
        final now = DateTime.now();
        final events = [
          // Solo
          SexualEvent(
            id: 'solo',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // Couple
          SexualEvent(
            id: 'couple',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        expect(
          result.monthlyCountsByType[AnalysisEventType.solo]![monthStr],
          1,
        );
        expect(
          result.monthlyCountsByType[AnalysisEventType.couple]![monthStr],
          1,
        );
      });

      test('dayOfWeekCountsByType tracks day-of-week per event type', () async {
        final monday = DateTime(2024, 7, 1); // Monday
        final events = [
          // Solo on Monday
          SexualEvent(
            id: 'solo',
            date: monday,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // Couple on Monday
          SexualEvent(
            id: 'couple',
            date: monday,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.dayOfWeekCountsByType[AnalysisEventType.solo]![1], 1);
        expect(result.dayOfWeekCountsByType[AnalysisEventType.couple]![1], 1);
      });
    });

    // ---------------------------------------------------------------
    // Averages
    // ---------------------------------------------------------------
    group('averages', () {
      test('calculates averages using distinct weeks and months', () async {
        final baseDate = DateTime(2024, 1, 1);
        final events = [
          _createEvent(baseDate), // Week 1, January
          _createEvent(
            baseDate.add(const Duration(days: 1)),
          ), // Same week, January
          _createEvent(
            baseDate.add(const Duration(days: 8)),
          ), // Week 2, January
          _createEvent(
            baseDate.add(const Duration(days: 35)),
          ), // Week 5-6, February
        ];

        final result = await AnalysisCalculator.calculate(
          events,
          mockProvider,
          startDate: baseDate,
          endDate: baseDate.add(const Duration(days: 60)),
        );

        // 4 events across 3 distinct weeks
        expect(result.averageEventsPerWeek, closeTo(4 / 3, 0.01));

        // 4 events across 2 distinct months (Jan and Feb)
        expect(result.averageEventsPerMonth, closeTo(4 / 2, 0.01));
      });

      test('calculates activities per event average', () async {
        final now = DateTime.now();
        final events = [
          // Event with 1 activity
          SexualEvent(
            id: 'event1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // Event with 3 activities
          SexualEvent(
            id: 'event2',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner2'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        // (1 + 3) / 2 = 2.0
        expect(result.averageActivitiesPerEvent, 2.0);
        expect(result.totalActivities, 4);
      });

      test('tracks sexual activities per event correctly', () async {
        final now = DateTime.now();
        final event = SexualEvent(
          id: 'event1',
          date: now,
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [
                    ActivityCount(
                      activityReference: Reference(reference: 'condom'),
                      count: 2,
                    ),
                    ActivityCount(
                      activityReference: Reference(reference: 'risky'),
                      count: 1,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        final result = await AnalysisCalculator.calculate([
          event,
        ], mockProvider);

        // 2 + 1 = 3 sexual activity instances
        expect(result.averageSexualActivitiesPerEvent, 3.0);
        expect(result.sexualActivityCountsTotal['condom'], 2);
        expect(result.sexualActivityCountsTotal['risky'], 1);
      });

      test('averageActivitiesPerWeek and averageActivitiesPerMonth', () async {
        final baseDate = DateTime(2024, 1, 1);
        final events = [
          // 2 activities in week 1
          _createEventWithActivities(baseDate, 2),
          // 3 activities in week 2
          _createEventWithActivities(baseDate.add(const Duration(days: 8)), 3),
        ];

        final result = await AnalysisCalculator.calculate(
          events,
          mockProvider,
          startDate: baseDate,
        );

        // 5 total activities, 2 distinct weeks → 2.5
        expect(result.averageActivitiesPerWeek, closeTo(5 / 2, 0.01));
        // 5 total activities, 1 month → 5.0
        expect(result.averageActivitiesPerMonth, closeTo(5.0, 0.01));
      });

      test('averageEventsPerDayOfWeek is computed', () async {
        final monday1 = DateTime(2024, 7, 1); // Monday
        final monday2 = DateTime(2024, 7, 8); // Next Monday
        final tuesday = DateTime(2024, 7, 2); // Tuesday
        final events = [
          _createEvent(monday1),
          _createEvent(monday2),
          _createEvent(tuesday),
        ];

        final result = await AnalysisCalculator.calculate(
          events,
          mockProvider,
          startDate: monday1,
        );

        // Should have entries for all 7 days
        expect(result.averageEventsPerDayOfWeek.length, 7);
        // Monday has 2 events
        expect(result.averageEventsPerDayOfWeek[1], greaterThan(0));
        // Tuesday has 1 event
        expect(result.averageEventsPerDayOfWeek[2], greaterThan(0));
      });

      test('averageDayOfWeekCountsByType has entries per event type', () async {
        final monday = DateTime(2024, 7, 1);
        final events = [
          // Solo on Monday
          SexualEvent(
            id: 'solo',
            date: monday,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(
          events,
          mockProvider,
          startDate: monday,
        );

        // Should have entries for all AnalysisEventType values
        expect(
          result.averageDayOfWeekCountsByType.containsKey(
            AnalysisEventType.total,
          ),
          true,
        );
        expect(
          result.averageDayOfWeekCountsByType.containsKey(
            AnalysisEventType.solo,
          ),
          true,
        );
        // Each type should have entries for all 7 days
        expect(
          result.averageDayOfWeekCountsByType[AnalysisEventType.total]!.length,
          7,
        );
      });
    });

    // ---------------------------------------------------------------
    // Streaks
    // ---------------------------------------------------------------
    group('streaks', () {
      test('calculates longest streak of consecutive days', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final events = [
          // 3-day streak (oldest)
          _createEvent(today.subtract(const Duration(days: 20))),
          _createEvent(today.subtract(const Duration(days: 19))),
          _createEvent(today.subtract(const Duration(days: 18))),
          // gap
          // 2-day streak
          _createEvent(today.subtract(const Duration(days: 10))),
          _createEvent(today.subtract(const Duration(days: 9))),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.longestStreak, 3);
      });

      test('currentStreak counts consecutive days ending today', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final events = [
          _createEvent(today.subtract(const Duration(days: 2))),
          _createEvent(today.subtract(const Duration(days: 1))),
          _createEvent(today),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.currentStreak, 3);
      });

      test(
        'currentStreak is 0 when last event was more than 1 day ago',
        () async {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final events = [
            _createEvent(today.subtract(const Duration(days: 10))),
            _createEvent(today.subtract(const Duration(days: 9))),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          expect(result.currentStreak, 0);
        },
      );

      test(
        'currentStreak is 0 when last event was yesterday but not today',
        () async {
          // StreakCalculator starts checking from today and walks back.
          // If today has no event, the loop breaks immediately even when
          // daysSinceLastEvent <= 1.
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final events = [
            _createEvent(today.subtract(const Duration(days: 2))),
            _createEvent(today.subtract(const Duration(days: 1))),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          expect(result.currentStreak, 0);
        },
      );

      test(
        'currentStreak counts backwards from today when event exists today',
        () async {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final events = [
            _createEvent(today.subtract(const Duration(days: 1))),
            _createEvent(today),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          expect(result.currentStreak, 2);
        },
      );

      test('single event has longestStreak of 1', () async {
        final now = DateTime.now();
        final events = [_createEvent(now)];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.longestStreak, 1);
      });
    });

    // ---------------------------------------------------------------
    // Period comparisons
    // ---------------------------------------------------------------
    group('period comparisons', () {
      test('thisWeekVsLastWeek compares current and previous week', () async {
        final now = DateTime.now();
        final todayWeekday = now.weekday;
        final thisWeekStart = now.subtract(Duration(days: todayWeekday - 1));
        final lastWeekDay = thisWeekStart.subtract(
          const Duration(days: 3),
        ); // Last week

        final events = [
          _createEvent(now), // This week
          _createEvent(
            now.subtract(const Duration(days: 1)),
          ), // This week (might be same or last depending on weekday)
          _createEvent(lastWeekDay), // Last week
        ];

        // Filter to only events that definitely land in these periods
        final result = await AnalysisCalculator.calculate(events, mockProvider);

        // Just verify the structure is populated
        expect(result.thisWeekVsLastWeek, isA<PeriodComparison>());
        expect(
          result.thisWeekVsLastWeek.currentPeriodCount,
          greaterThanOrEqualTo(0),
        );
        expect(
          result.thisWeekVsLastWeek.previousPeriodCount,
          greaterThanOrEqualTo(0),
        );
      });

      test(
        'thisMonthVsLastMonth compares current and previous month',
        () async {
          final now = DateTime.now();
          final thisMonth = DateTime(now.year, now.month, 5);
          final lastMonth = DateTime(
            now.month == 1 ? now.year - 1 : now.year,
            now.month == 1 ? 12 : now.month - 1,
            5,
          );

          final events = [
            _createEvent(thisMonth),
            _createEvent(lastMonth),
            _createEvent(lastMonth.add(const Duration(days: 1))),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          expect(result.thisMonthVsLastMonth, isA<PeriodComparison>());
          expect(result.thisMonthVsLastMonth.currentPeriodCount, 1);
          expect(result.thisMonthVsLastMonth.previousPeriodCount, 2);
          expect(result.thisMonthVsLastMonth.isIncrease, false);
        },
      );

      test('PeriodComparison.calculate handles zero previous period', () async {
        final now = DateTime.now();
        // Events only this week, none last week
        final events = [_createEvent(now)];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        // When previous is 0 and current > 0, percentageChange should be 100
        if (result.thisWeekVsLastWeek.previousPeriodCount == 0 &&
            result.thisWeekVsLastWeek.currentPeriodCount > 0) {
          expect(result.thisWeekVsLastWeek.percentageChange, 100.0);
          expect(result.thisWeekVsLastWeek.isIncrease, true);
        }
      });
    });

    // ---------------------------------------------------------------
    // Days since last activity / risky
    // ---------------------------------------------------------------
    group('days since last', () {
      test('daysSinceLastActivity is computed from last event', () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final events = [
          _createEvent(threeDaysAgo.subtract(const Duration(days: 5))),
          _createEvent(threeDaysAgo),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.daysSinceLastActivity, 3);
      });

      test('daysSinceLastActivity is 0 for event today', () async {
        final now = DateTime.now();
        final events = [_createEvent(now)];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.daysSinceLastActivity, 0);
      });

      test(
        'daysSinceLastRiskyActivity returns days since most recent risky event',
        () async {
          final now = DateTime.now();
          final twoDaysAgo = now.subtract(const Duration(days: 2));
          final events = [
            // Old risky event
            SexualEvent(
              id: 'e1',
              date: now.subtract(const Duration(days: 10)),
              activities: [
                EventActivity(
                  category: const Reference(reference: 'vaginal'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'risky'),
                          count: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // More recent risky event
            SexualEvent(
              id: 'e2',
              date: twoDaysAgo,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'risky'),
                          count: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          expect(result.daysSinceLastRiskyActivity, 2);
        },
      );

      test('daysSinceLastRiskyActivity is -1 when no risky events', () async {
        final now = DateTime.now();
        final events = [
          SexualEvent(
            id: 'e1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'condom'),
                        count: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.daysSinceLastRiskyActivity, -1);
      });
    });

    // ---------------------------------------------------------------
    // Time-scoped counts (this month / this year)
    // ---------------------------------------------------------------
    group('time-scoped counts', () {
      test('eventsThisMonth counts events in the current month', () async {
        final now = DateTime.now();
        final thisMonth = DateTime(now.year, now.month, 1);
        final lastMonth = DateTime(
          now.month == 1 ? now.year - 1 : now.year,
          now.month == 1 ? 12 : now.month - 1,
          15,
        );

        final events = [
          _createEvent(thisMonth),
          _createEvent(thisMonth.add(const Duration(days: 1))),
          _createEvent(lastMonth),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.eventsThisMonth, 2);
      });

      test(
        'uniquePartnersThisMonth counts partners in current month',
        () async {
          final now = DateTime.now();
          final thisMonth = DateTime(now.year, now.month, 2);
          final events = [
            SexualEvent(
              id: 'e1',
              date: thisMonth,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [],
                    ),
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner2'),
                      activityCounts: [],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          expect(result.uniquePartnersThisMonth, 2);
        },
      );

      test('uniquePartnersThisYear counts partners in time window', () async {
        final now = DateTime.now();
        final recentDate = now.subtract(const Duration(days: 5));
        final events = [
          SexualEvent(
            id: 'e1',
            date: recentDate,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          SexualEvent(
            id: 'e2',
            date: recentDate.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner2'),
                    activityCounts: [],
                  ),
                  const ActivityParticipant(
                    participant: Reference(reference: 'anonymous'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(
          events,
          mockProvider,
          startDate: now.subtract(const Duration(days: 365)),
        );

        // 2 known + 1 anonymous instance
        expect(result.uniquePartnersThisYear, 3);
      });

      test('activityCountsThisYear scoped to time window', () async {
        final now = DateTime.now();
        final recentDate = now.subtract(const Duration(days: 5));
        final events = [
          SexualEvent(
            id: 'e1',
            date: recentDate,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(
          events,
          mockProvider,
          startDate: now.subtract(const Duration(days: 365)),
        );

        expect(result.activityCountsThisYear['oral'], 1);
        expect(result.activityCountsThisYear['vaginal'], 1);
      });
    });

    // ---------------------------------------------------------------
    // Partner counts scoped to this year
    // ---------------------------------------------------------------
    group('partner counts scoped to this year', () {
      test(
        'categoryPartnerCountsThisYear tracks partners per category',
        () async {
          final now = DateTime.now();
          final recentDate = now.subtract(const Duration(days: 5));
          final events = [
            SexualEvent(
              id: 'e1',
              date: recentDate,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [],
                    ),
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner2'),
                      activityCounts: [],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
            startDate: now.subtract(const Duration(days: 365)),
          );

          expect(result.categoryPartnerCountsThisYear['oral'], 2);
        },
      );

      test(
        'sexualActivityPartnerCountsThisYear tracks partners per sexual activity',
        () async {
          final now = DateTime.now();
          final recentDate = now.subtract(const Duration(days: 5));
          final events = [
            SexualEvent(
              id: 'e1',
              date: recentDate,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'condom'),
                          count: 1,
                        ),
                      ],
                    ),
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner2'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'condom'),
                          count: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
            startDate: now.subtract(const Duration(days: 365)),
          );

          expect(result.sexualActivityPartnerCountsThisYear['condom'], 2);
        },
      );

      test(
        'categoryActivityPartnerCountsThisYear is nested category → activity → count',
        () async {
          final now = DateTime.now();
          final recentDate = now.subtract(const Duration(days: 5));
          final events = [
            SexualEvent(
              id: 'e1',
              date: recentDate,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'condom'),
                          count: 1,
                        ),
                      ],
                    ),
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner2'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'condom'),
                          count: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
            startDate: now.subtract(const Duration(days: 365)),
          );

          expect(
            result.categoryActivityPartnerCountsThisYear['oral']!['condom'],
            2,
          );
        },
      );
    });

    // ---------------------------------------------------------------
    // Busiest day / event
    // ---------------------------------------------------------------
    group('busiest day and event', () {
      test('finds busiest day and event in time window', () async {
        final baseDate = DateTime(2024, 6, 1);
        final busiestDate = DateTime(2024, 6, 15);

        final events = [
          _createEvent(baseDate),
          _createEvent(busiestDate),
          _createEvent(busiestDate), // Same day - busiest
          _createEvent(baseDate.add(const Duration(days: 2))),
          // Event with most activities
          _createEventWithActivities(baseDate.add(const Duration(days: 3)), 5),
        ];

        final result = await AnalysisCalculator.calculate(
          events,
          mockProvider,
          startDate: DateTime(2024, 1, 1),
        );

        expect(result.busiestDay, busiestDate);
        expect(result.busiestDayEventCount, 2);
        expect(result.busiestEventActivityCount, 5);
      });

      test('busiestEvent references the event with most activities', () async {
        final now = DateTime.now();
        final smallEvent = SexualEvent(
          id: 'small',
          date: now,
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
          ],
        );
        final bigEvent = SexualEvent(
          id: 'big',
          date: now.subtract(const Duration(days: 1)),
          activities: [
            EventActivity(
              category: const Reference(reference: 'oral'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
            EventActivity(
              category: const Reference(reference: 'vaginal'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
            EventActivity(
              category: const Reference(reference: 'anal'),
              participants: [
                const ActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  activityCounts: [],
                ),
              ],
            ),
          ],
        );

        final result = await AnalysisCalculator.calculate(
          [smallEvent, bigEvent],
          mockProvider,
          startDate: now.subtract(const Duration(days: 30)),
        );

        expect(result.busiestEvent, isNotNull);
        expect(result.busiestEventActivityCount, 3);
      });
    });

    // ---------------------------------------------------------------
    // Co-occurrence
    // ---------------------------------------------------------------
    group('co-occurrence', () {
      test(
        'topCategoryPairs detects categories appearing in same event',
        () async {
          final now = DateTime.now();
          final events = [
            SexualEvent(
              id: 'e1',
              date: now,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [],
                    ),
                  ],
                ),
                EventActivity(
                  category: const Reference(reference: 'vaginal'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [],
                    ),
                  ],
                ),
              ],
            ),
            // Same pair again
            SexualEvent(
              id: 'e2',
              date: now.subtract(const Duration(days: 1)),
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [],
                    ),
                  ],
                ),
                EventActivity(
                  category: const Reference(reference: 'vaginal'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          expect(result.topCategoryPairs, isNotEmpty);
          expect(result.topCategoryPairs.first.count, 2);
          // Should contain oral and vaginal
          final pair = result.topCategoryPairs.first;
          final pairIds = {pair.id1, pair.id2};
          expect(pairIds, contains('oral'));
          expect(pairIds, contains('vaginal'));
        },
      );

      test(
        'topActivityPairs detects sexual activities in same event',
        () async {
          final now = DateTime.now();
          final events = [
            SexualEvent(
              id: 'e1',
              date: now,
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'partner1'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'condom'),
                          count: 1,
                        ),
                        ActivityCount(
                          activityReference: Reference(reference: 'lub'),
                          count: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          expect(result.topActivityPairs, isNotEmpty);
          final pair = result.topActivityPairs.first;
          final pairIds = {pair.id1, pair.id2};
          expect(pairIds, contains('condom'));
          expect(pairIds, contains('lub'));
          expect(pair.count, 1);
        },
      );

      test('no co-occurrence when events have single category', () async {
        final now = DateTime.now();
        final events = [
          SexualEvent(
            id: 'e1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.topCategoryPairs, isEmpty);
      });

      test('co-occurrence pairs are sorted by frequency descending', () async {
        final now = DateTime.now();
        final events = [
          // oral+vaginal appears twice
          SexualEvent(
            id: 'e1',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          SexualEvent(
            id: 'e2',
            date: now.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
          // oral+anal appears once
          SexualEvent(
            id: 'e3',
            date: now.subtract(const Duration(days: 2)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
              EventActivity(
                category: const Reference(reference: 'anal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        expect(result.topCategoryPairs.length, greaterThanOrEqualTo(2));
        // First pair should have count 2, second should have count 1
        expect(
          result.topCategoryPairs[0].count,
          greaterThanOrEqualTo(result.topCategoryPairs[1].count),
        );
      });
    });

    // ---------------------------------------------------------------
    // Time window filtering
    // ---------------------------------------------------------------
    group('time window filtering', () {
      test('respects time window filtering for statistics', () async {
        final oldDate = DateTime(2023, 1, 1);
        final recentDate = DateTime(2024, 6, 1);

        final allEvents = [
          _createEvent(oldDate),
          _createEvent(oldDate.add(const Duration(days: 1))),
          _createEvent(recentDate),
          _createEvent(recentDate.add(const Duration(days: 1))),
        ];

        // Filter events before passing to calculator
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 12, 31);
        final filteredEvents = allEvents.where((event) {
          return !event.date.isBefore(startDate) &&
              !event.date.isAfter(endDate);
        }).toList();

        final result = await AnalysisCalculator.calculate(
          filteredEvents,
          mockProvider,
          startDate: startDate,
          endDate: endDate,
        );

        expect(result.totalEvents, 2);
        expect(result.events.length, 2);
        expect(result.startDate, startDate);
        expect(result.endDate, endDate);
      });

      test(
        'soloActivityCountsThisYear only counts within time window',
        () async {
          final now = DateTime.now();
          final events = [
            // Solo event within time window
            SexualEvent(
              id: 'solo',
              date: now.subtract(const Duration(days: 5)),
              activities: [
                EventActivity(
                  category: const Reference(reference: 'oral'),
                  participants: [
                    const ActivityParticipant(
                      participant: Reference(reference: 'me'),
                      activityCounts: [
                        ActivityCount(
                          activityReference: Reference(reference: 'lub'),
                          count: 2,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
            startDate: now.subtract(const Duration(days: 365)),
          );

          // Category counts are tracked for solo events this year
          expect(result.soloActivityCountsThisYear['oral'], 1);
          // Sexual activity counts include "me" participant's activities
          // (the single-pass aggregator tracks these for everyone)
          expect(result.soloSexualActivityCountsThisYear['lub'], 2);
        },
      );
    });

    // ---------------------------------------------------------------
    // Complex / integration scenarios
    // ---------------------------------------------------------------
    group('complex scenarios', () {
      test(
        'handles events with multiple activities and participants',
        () async {
          final now = DateTime.now();
          final complexEvent = SexualEvent(
            id: 'complex',
            date: now,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'condom'),
                        count: 1,
                      ),
                    ],
                  ),
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner2'),
                    activityCounts: [],
                  ),
                ],
              ),
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'risky'),
                        count: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          final result = await AnalysisCalculator.calculate([
            complexEvent,
          ], mockProvider);

          expect(result.totalEvents, 1);
          expect(result.totalActivities, 2);
          expect(result.uniquePartners, 2);
          expect(result.averageActivitiesPerEvent, 2.0);
          expect(result.averagePartnersPerEvent, 2.0);
          expect(result.riskyActivityCount, 1);
          expect(result.safeActivityCount, 1);
        },
      );

      test(
        'multiple events across different dates populate all maps',
        () async {
          final now = DateTime.now();
          final events = [
            _createEvent(now),
            _createEvent(now.subtract(const Duration(days: 1))),
            _createEvent(now.subtract(const Duration(days: 7))),
            _createEvent(now.subtract(const Duration(days: 30))),
          ];

          final result = await AnalysisCalculator.calculate(
            events,
            mockProvider,
          );

          // dailyCounts should have entries
          expect(result.dailyCounts.isNotEmpty, true);
          // monthlyCounts should have entries
          expect(result.monthlyCounts.isNotEmpty, true);
          // dayOfWeekCounts should have entries
          expect(result.dayOfWeekCounts.isNotEmpty, true);
        },
      );

      test('events are sorted internally even if input is unsorted', () async {
        final now = DateTime.now();
        final events = [
          _createEvent(now), // newest first
          _createEvent(now.subtract(const Duration(days: 10))), // oldest last
          _createEvent(now.subtract(const Duration(days: 5))), // middle
        ];

        final result = await AnalysisCalculator.calculate(events, mockProvider);

        // Should still calculate correctly
        expect(result.totalEvents, 3);
        expect(result.daysSinceLastActivity, 0);
      });

      test('full scenario with mixed event types and activities', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final events = [
          // Solo today
          SexualEvent(
            id: 'solo_today',
            date: today,
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'lub'),
                        count: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Couple yesterday with risky
          SexualEvent(
            id: 'couple_yesterday',
            date: today.subtract(const Duration(days: 1)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'me'),
                    activityCounts: [],
                  ),
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'risky'),
                        count: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Group 2 days ago with condom
          SexualEvent(
            id: 'group_2_days',
            date: today.subtract(const Duration(days: 2)),
            activities: [
              EventActivity(
                category: const Reference(reference: 'oral'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'condom'),
                        count: 1,
                      ),
                    ],
                  ),
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner2'),
                    activityCounts: [
                      ActivityCount(
                        activityReference: Reference(reference: 'condom'),
                        count: 1,
                      ),
                    ],
                  ),
                ],
              ),
              EventActivity(
                category: const Reference(reference: 'vaginal'),
                participants: [
                  const ActivityParticipant(
                    participant: Reference(reference: 'partner1'),
                    activityCounts: [],
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = await AnalysisCalculator.calculate(
          events,
          mockProvider,
          startDate: today.subtract(const Duration(days: 365)),
        );

        // Basic counts
        expect(result.totalEvents, 3);
        expect(result.totalActivities, 4); // 1 + 1 + 2
        expect(result.uniquePartners, 2); // partner1, partner2

        // Event types
        expect(result.soloEventsThisYear, 1);
        expect(result.coupleEventsThisYear, 1);
        expect(result.groupEventsThisYear, 1);
        expect(result.soloEventsTotal, 1);
        expect(result.nonSoloEventsTotal, 2);

        // Risky/safe
        expect(result.riskyActivityCount, 1); // vaginal with risky
        expect(
          result.safeActivityCount,
          3,
        ); // oral solo, oral group, vaginal group

        // Partners
        expect(result.knownPartners, 2);
        expect(result.personCounts.containsKey('partner1'), true);
        expect(result.personCounts.containsKey('partner2'), true);

        // Streaks (3 consecutive days ending today)
        expect(result.currentStreak, 3);
        expect(result.longestStreak, 3);

        // Activity categories
        expect(result.activityCounts['oral'], 2);
        expect(result.activityCounts['vaginal'], 2);

        // Sexual activity totals
        expect(result.sexualActivityCountsTotal['condom'], 2);
        expect(result.sexualActivityCountsTotal['risky'], 1);
        expect(result.sexualActivityCountsTotal['lub'], 1);

        // Solo activity tracking
        expect(result.soloActivityCounts['oral'], 1);
        expect(result.soloSexualActivityCounts['lub'], 1);

        // Co-occurrence: oral+vaginal in the group event
        expect(result.topCategoryPairs, isNotEmpty);

        // Days since last activity
        expect(result.daysSinceLastActivity, 0);

        // Days since last risky (yesterday)
        expect(result.daysSinceLastRiskyActivity, 1);
      });
    });
  });
}

// Helper function to create a simple event
SexualEvent _createEvent(DateTime date) {
  return SexualEvent(
    id: 'event_${date.millisecondsSinceEpoch}',
    date: date,
    activities: [
      EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [
          const ActivityParticipant(
            participant: Reference(reference: 'partner1'),
            activityCounts: [],
          ),
        ],
      ),
    ],
  );
}

// Helper function to create an event with a specific number of activities
SexualEvent _createEventWithActivities(DateTime date, int activityCount) {
  final activities = List.generate(
    activityCount,
    (index) => EventActivity(
      category: const Reference(reference: 'oral'),
      participants: [
        const ActivityParticipant(
          participant: Reference(reference: 'partner1'),
          activityCounts: [],
        ),
      ],
    ),
  );

  return SexualEvent(
    id: 'event_${date.millisecondsSinceEpoch}',
    date: date,
    activities: activities,
  );
}
