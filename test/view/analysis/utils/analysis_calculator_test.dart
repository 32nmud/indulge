import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
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
    late Person anonymousPerson;
    late SexualActivityType oralType;
    late SexualActivityType vaginalType;
    late SexualActivityTypeProperty condomProperty;
    late SexualActivityTypeProperty riskyProperty;

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

      anonymousPerson = Person(
        id: 'anonymous',
        name: const Name(given: 'Anonymous'),
        isSelf: false,
        date: DateTime(2023, 1, 1),
      );

      // Create test activity types
      oralType = const SexualActivityType(id: 'oral', name: 'Oral');

      vaginalType = const SexualActivityType(id: 'vaginal', name: 'Vaginal');

      // Create test properties
      condomProperty = const SexualActivityTypeProperty(
        id: 'condom',
        name: 'Condom',
        isRisky: false,
      );

      riskyProperty = const SexualActivityTypeProperty(
        id: 'risky',
        name: 'Risky Property',
        isRisky: true,
      );

      // Set up mock state
      mockState = EventState(
        sexualActivityTypes: {'oral': oralType, 'vaginal': vaginalType},
        sexualActivityTypeProperties: {
          'condom': condomProperty,
          'risky': riskyProperty,
        },
        currentEvents: [],
        selectedDate: DateTime.now(),
        dailyEventCount: {},
      );

      when(mockProvider.state).thenReturn(mockState);
      when(mockProvider.getPersonById('me')).thenAnswer((_) async => mePerson);
      when(
        mockProvider.getPersonById('partner1'),
      ).thenAnswer((_) async => partner1);
      when(
        mockProvider.getPersonById('partner2'),
      ).thenAnswer((_) async => partner2);
      when(
        mockProvider.getPersonById('anonymous'),
      ).thenAnswer((_) async => anonymousPerson);
    });

    test('returns empty analysis data when no events provided', () async {
      final result = await AnalysisCalculator.calculate(
        [],
        mockProvider,
        timeWindowLabel: 'Test Window',
      );

      expect(result.totalEvents, 0);
      expect(result.totalActivities, 0);
      expect(result.uniquePartners, 0);
      expect(result.averageEventsPerWeek, 0.0);
      expect(result.averageEventsPerMonth, 0.0);
      expect(result.timeWindowLabel, 'Test Window');
    });

    test('calculates basic event counts correctly', () async {
      final now = DateTime.now();
      final events = [
        _createEvent(now.subtract(const Duration(days: 1))),
        _createEvent(now.subtract(const Duration(days: 2))),
        _createEvent(now.subtract(const Duration(days: 3))),
      ];

      final result = await AnalysisCalculator.calculate(events, mockProvider);

      expect(result.totalEvents, 3);
    });

    test('excludes "me" from partner counts', () async {
      final now = DateTime.now();
      final event = SexualEvent(
        id: 'event1',
        date: now,
        activities: [
          SexualActivity(
            type: const Reference(reference: 'oral'),
            participants: [
              const SexualActivityParticipant(
                participant: Reference(reference: 'me'),
                propertyCounts: [],
              ),
              const SexualActivityParticipant(
                participant: Reference(reference: 'partner1'),
                propertyCounts: [],
              ),
            ],
          ),
        ],
      );

      final result = await AnalysisCalculator.calculate([event], mockProvider);

      // Should only count partner1, not "me"
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
          SexualActivity(
            type: const Reference(reference: 'oral'),
            participants: [
              const SexualActivityParticipant(
                participant: Reference(reference: 'partner1'),
                propertyCounts: [],
              ),
              const SexualActivityParticipant(
                participant: Reference(reference: 'partner2'),
                propertyCounts: [],
              ),
            ],
          ),
          SexualActivity(
            type: const Reference(reference: 'vaginal'),
            participants: [
              const SexualActivityParticipant(
                participant: Reference(reference: 'partner1'),
                propertyCounts: [],
              ),
            ],
          ),
        ],
      );

      final result = await AnalysisCalculator.calculate([event], mockProvider);

      // Should count 2 unique partners (partner1 appears twice but counted once per event)
      expect(result.uniquePartners, 2);
      expect(result.averagePartnersPerEvent, 2.0);
    });

    test('calculates averages using distinct weeks and months', () async {
      final baseDate = DateTime(2024, 1, 1);
      final events = [
        _createEvent(baseDate), // Week 1, January
        _createEvent(
          baseDate.add(const Duration(days: 1)),
        ), // Same week, January
        _createEvent(baseDate.add(const Duration(days: 8))), // Week 2, January
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
            SexualActivity(
              type: const Reference(reference: 'oral'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  propertyCounts: [],
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
            SexualActivity(
              type: const Reference(reference: 'oral'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  propertyCounts: [],
                ),
              ],
            ),
            SexualActivity(
              type: const Reference(reference: 'vaginal'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  propertyCounts: [],
                ),
              ],
            ),
            SexualActivity(
              type: const Reference(reference: 'oral'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner2'),
                  propertyCounts: [],
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

    test('tracks properties per event correctly', () async {
      final now = DateTime.now();
      final event = SexualEvent(
        id: 'event1',
        date: now,
        activities: [
          SexualActivity(
            type: const Reference(reference: 'oral'),
            participants: [
              const SexualActivityParticipant(
                participant: Reference(reference: 'partner1'),
                propertyCounts: [
                  PropertyCount(
                    propertyReference: Reference(reference: 'condom'),
                    count: 2,
                  ),
                  PropertyCount(
                    propertyReference: Reference(reference: 'risky'),
                    count: 1,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final result = await AnalysisCalculator.calculate([event], mockProvider);

      // 2 + 1 = 3 properties
      expect(result.averagePropertiesPerEvent, 3.0);
      expect(result.propertyCountsTotal['condom'], 2);
      expect(result.propertyCountsTotal['risky'], 1);
    });

    test('identifies risky activities correctly', () async {
      final now = DateTime.now();
      final events = [
        // Safe event
        SexualEvent(
          id: 'event1',
          date: now,
          activities: [
            SexualActivity(
              type: const Reference(reference: 'oral'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  propertyCounts: [
                    PropertyCount(
                      propertyReference: Reference(reference: 'condom'),
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
            SexualActivity(
              type: const Reference(reference: 'vaginal'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  propertyCounts: [
                    PropertyCount(
                      propertyReference: Reference(reference: 'risky'),
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

    test('counts anonymous partners correctly', () async {
      final now = DateTime.now();
      final event = SexualEvent(
        id: 'event1',
        date: now,
        activities: [
          SexualActivity(
            type: const Reference(reference: 'oral'),
            participants: [
              const SexualActivityParticipant(
                participant: Reference(reference: 'anonymous'),
                propertyCounts: [],
              ),
              const SexualActivityParticipant(
                participant: Reference(reference: 'partner1'),
                propertyCounts: [],
              ),
            ],
          ),
        ],
      );

      final result = await AnalysisCalculator.calculate([event], mockProvider);

      expect(result.anonymousPartnerInstances, 1);
      expect(result.knownPartners, 1); // Only partner1, not anonymous
      expect(result.uniquePartners, 2); // Both anonymous and partner1
    });

    test('categorizes solo, couple, and group events', () async {
      final now = DateTime.now();
      final events = [
        // Solo event (only "me")
        SexualEvent(
          id: 'solo',
          date: now,
          activities: [
            SexualActivity(
              type: const Reference(reference: 'oral'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'me'),
                  propertyCounts: [],
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
            SexualActivity(
              type: const Reference(reference: 'oral'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'me'),
                  propertyCounts: [],
                ),
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  propertyCounts: [],
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
            SexualActivity(
              type: const Reference(reference: 'oral'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'me'),
                  propertyCounts: [],
                ),
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  propertyCounts: [],
                ),
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner2'),
                  propertyCounts: [],
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

    test('tracks unique partners per property', () async {
      final now = DateTime.now();
      final events = [
        SexualEvent(
          id: 'event1',
          date: now,
          activities: [
            SexualActivity(
              type: const Reference(reference: 'oral'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner1'),
                  propertyCounts: [
                    PropertyCount(
                      propertyReference: Reference(reference: 'condom'),
                      count: 1,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        SexualEvent(
          id: 'event2',
          date: now.subtract(const Duration(days: 1)),
          activities: [
            SexualActivity(
              type: const Reference(reference: 'vaginal'),
              participants: [
                const SexualActivityParticipant(
                  participant: Reference(reference: 'partner2'),
                  propertyCounts: [
                    PropertyCount(
                      propertyReference: Reference(reference: 'condom'),
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

      // Condom used with 2 different partners
      expect(result.propertyPartnerCounts['condom'], 2);
    });

    test('respects time window filtering for statistics', () async {
      final oldDate = DateTime(2023, 1, 1);
      final recentDate = DateTime(2024, 6, 1);

      final events = [
        _createEvent(oldDate),
        _createEvent(oldDate.add(const Duration(days: 1))),
        _createEvent(recentDate),
        _createEvent(recentDate.add(const Duration(days: 1))),
      ];

      // Filter to only recent events
      final result = await AnalysisCalculator.calculate(
        events,
        mockProvider,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        timeWindowLabel: '2024',
      );

      // Total events should be all 4
      expect(result.totalEvents, 4);

      // But eventsThisYear should only count the recent ones
      expect(result.eventsThisYear, 2);
      expect(result.timeWindowLabel, '2024');
    });

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

    test('handles events with multiple activities and participants', () async {
      final now = DateTime.now();
      final complexEvent = SexualEvent(
        id: 'complex',
        date: now,
        activities: [
          SexualActivity(
            type: const Reference(reference: 'oral'),
            participants: [
              const SexualActivityParticipant(
                participant: Reference(reference: 'partner1'),
                propertyCounts: [
                  PropertyCount(
                    propertyReference: Reference(reference: 'condom'),
                    count: 1,
                  ),
                ],
              ),
              const SexualActivityParticipant(
                participant: Reference(reference: 'partner2'),
                propertyCounts: [],
              ),
            ],
          ),
          SexualActivity(
            type: const Reference(reference: 'vaginal'),
            participants: [
              const SexualActivityParticipant(
                participant: Reference(reference: 'partner1'),
                propertyCounts: [
                  PropertyCount(
                    propertyReference: Reference(reference: 'risky'),
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
      expect(result.uniquePartners, 2); // partner1 and partner2
      expect(result.averageActivitiesPerEvent, 2.0);
      expect(result.averagePartnersPerEvent, 2.0);
      expect(
        result.riskyActivityCount,
        1,
      ); // Second activity has risky property
      expect(result.safeActivityCount, 1); // First activity is safe
    });
  });
}

// Helper function to create a simple event
SexualEvent _createEvent(DateTime date) {
  return SexualEvent(
    id: 'event_${date.millisecondsSinceEpoch}',
    date: date,
    activities: [
      SexualActivity(
        type: const Reference(reference: 'oral'),
        participants: [
          const SexualActivityParticipant(
            participant: Reference(reference: 'partner1'),
            propertyCounts: [],
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
    (index) => SexualActivity(
      type: const Reference(reference: 'oral'),
      participants: [
        const SexualActivityParticipant(
          participant: Reference(reference: 'partner1'),
          propertyCounts: [],
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
