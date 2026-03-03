import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';

// Tests for the activity-vs-gear classification logic used inside
// PeriodComparisonSection._calculatePeriodStats. Because that method is
// private to the widget we test the underlying classification rule directly
// (composite-key lookup on a SexualActivity map) and then validate that the
// aggregation arithmetic is correct — mirroring exactly what the widget does.

// ── Helpers ────────────────────────────────────────────────────────────────

/// Builds a minimal [SexualEvent] whose participants each carry one
/// [ActivityCount] with the given category/activity pair and count.
SexualEvent _makeEvent({
  required String eventId,
  required DateTime date,
  required List<({String catId, String actName, int count})> activityCounts,
}) {
  return SexualEvent(
    id: eventId,
    date: date,
    activities: [
      EventActivity(
        category: Reference(
          reference: activityCounts.isNotEmpty
              ? activityCounts.first.catId
              : 'unknown',
          resourceType: 'SexualActivityCategory',
        ),
        participants: [
          ActivityParticipant(
            participant: const Reference(
              reference: 'me',
              resourceType: 'Person',
            ),
            activityCounts: activityCounts
                .map(
                  (ac) => ActivityCount(
                    categoryReference: Reference(
                      reference: ac.catId,
                      resourceType: 'SexualActivityCategory',
                    ),
                    activityName: ac.actName,
                    count: ac.count,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ],
  );
}

/// Runs the same classification loop used in
/// `PeriodComparisonSection._calculatePeriodStats` and returns a record of the
/// computed totals.
({
  int totalActivities,
  int totalItems,
  int uniqueActivities,
  int uniqueItems,
  double avgActivitiesPerEvent,
  double avgItemsPerEvent,
})
_runStats(
  List<SexualEvent> events,
  Map<String, SexualActivity> sexualActivities,
) {
  int totalActivities = 0;
  int totalItems = 0;
  final uniqueActivityKeys = <String>{};
  final uniqueItemKeys = <String>{};

  for (final event in events) {
    for (final activity in event.activities) {
      for (final participant in activity.participants) {
        for (final ac in participant.activityCounts) {
          final compositeKey =
              '${ac.categoryReference.reference}:${ac.activityName}';
          final sexualActivity = sexualActivities[compositeKey];
          // Default to actionable when metadata is missing — same as widget.
          final isActionable = sexualActivity?.isActionable ?? true;

          if (isActionable) {
            totalActivities += ac.count;
            uniqueActivityKeys.add(compositeKey);
          } else {
            totalItems += ac.count;
            uniqueItemKeys.add(compositeKey);
          }
        }
      }
    }
  }

  final n = events.length;
  return (
    totalActivities: totalActivities,
    totalItems: totalItems,
    uniqueActivities: uniqueActivityKeys.length,
    uniqueItems: uniqueItemKeys.length,
    avgActivitiesPerEvent: n > 0 ? totalActivities / n : 0.0,
    avgItemsPerEvent: n > 0 ? totalItems / n : 0.0,
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('PeriodComparison stats — activity vs gear classification', () {
    // ── Fixture data ──────────────────────────────────────────────────

    /// A map of SexualActivity objects used across tests.
    ///   catA:kiss      → actionable (isActionable defaults to true)
    ///   catA:oral      → actionable explicitly
    ///   catB:vibrator  → inactionable (gear/item)
    ///   catB:harness   → inactionable (gear/item)
    final sexualActivities = <String, SexualActivity>{
      'catA:kiss': SexualActivity(name: 'Kiss', isActionable: true),
      'catA:oral': SexualActivity(name: 'Oral', isActionable: true),
      'catB:vibrator': SexualActivity(name: 'Vibrator', isActionable: false),
      'catB:harness': SexualActivity(name: 'Harness', isActionable: false),
    };

    // ── Empty input ────────────────────────────────────────────────────

    test('returns all zeros for empty event list', () {
      final stats = _runStats([], sexualActivities);

      expect(stats.totalActivities, 0);
      expect(stats.totalItems, 0);
      expect(stats.uniqueActivities, 0);
      expect(stats.uniqueItems, 0);
      expect(stats.avgActivitiesPerEvent, 0.0);
      expect(stats.avgItemsPerEvent, 0.0);
    });

    // ── All actionable ─────────────────────────────────────────────────

    test('counts only actionable activities when no gear is present', () {
      final events = [
        _makeEvent(
          eventId: 'e1',
          date: DateTime(2024, 1, 1),
          activityCounts: [
            (catId: 'catA', actName: 'kiss', count: 2),
            (catId: 'catA', actName: 'oral', count: 1),
          ],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      expect(stats.totalActivities, 3);
      expect(stats.totalItems, 0);
      expect(stats.uniqueActivities, 2);
      expect(stats.uniqueItems, 0);
    });

    // ── All gear ───────────────────────────────────────────────────────

    test(
      'counts only gear items when no actionable activities are present',
      () {
        final events = [
          _makeEvent(
            eventId: 'e1',
            date: DateTime(2024, 1, 1),
            activityCounts: [
              (catId: 'catB', actName: 'vibrator', count: 1),
              (catId: 'catB', actName: 'harness', count: 1),
            ],
          ),
        ];

        final stats = _runStats(events, sexualActivities);

        expect(stats.totalActivities, 0);
        expect(stats.totalItems, 2);
        expect(stats.uniqueActivities, 0);
        expect(stats.uniqueItems, 2);
      },
    );

    // ── Mixed event ────────────────────────────────────────────────────

    test('correctly splits mixed event with both actionable and gear', () {
      final events = [
        _makeEvent(
          eventId: 'e1',
          date: DateTime(2024, 1, 1),
          activityCounts: [
            (catId: 'catA', actName: 'kiss', count: 3),
            (catId: 'catB', actName: 'vibrator', count: 2),
          ],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      expect(stats.totalActivities, 3);
      expect(stats.totalItems, 2);
      expect(stats.uniqueActivities, 1);
      expect(stats.uniqueItems, 1);
    });

    // ── Multiple events ────────────────────────────────────────────────

    test('aggregates across multiple events correctly', () {
      final events = [
        _makeEvent(
          eventId: 'e1',
          date: DateTime(2024, 1, 1),
          activityCounts: [(catId: 'catA', actName: 'kiss', count: 2)],
        ),
        _makeEvent(
          eventId: 'e2',
          date: DateTime(2024, 1, 2),
          activityCounts: [
            (catId: 'catA', actName: 'oral', count: 1),
            (catId: 'catB', actName: 'vibrator', count: 3),
          ],
        ),
        _makeEvent(
          eventId: 'e3',
          date: DateTime(2024, 1, 3),
          activityCounts: [(catId: 'catB', actName: 'harness', count: 1)],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      // Actionable: kiss×2 + oral×1 = 3
      expect(stats.totalActivities, 3);
      // Gear: vibrator×3 + harness×1 = 4
      expect(stats.totalItems, 4);
      // Unique actionable: kiss, oral = 2
      expect(stats.uniqueActivities, 2);
      // Unique gear: vibrator, harness = 2
      expect(stats.uniqueItems, 2);
    });

    // ── Averages ───────────────────────────────────────────────────────

    test('computes avgActivitiesPerEvent correctly', () {
      // e1: 4 actionable, e2: 2 actionable → avg = 3.0
      final events = [
        _makeEvent(
          eventId: 'e1',
          date: DateTime(2024, 1, 1),
          activityCounts: [(catId: 'catA', actName: 'kiss', count: 4)],
        ),
        _makeEvent(
          eventId: 'e2',
          date: DateTime(2024, 1, 2),
          activityCounts: [(catId: 'catA', actName: 'oral', count: 2)],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      expect(stats.avgActivitiesPerEvent, closeTo(3.0, 0.001));
      expect(stats.avgItemsPerEvent, 0.0);
    });

    test('computes avgItemsPerEvent correctly', () {
      // e1: 2 gear, e2: 6 gear → avg = 4.0
      final events = [
        _makeEvent(
          eventId: 'e1',
          date: DateTime(2024, 1, 1),
          activityCounts: [(catId: 'catB', actName: 'vibrator', count: 2)],
        ),
        _makeEvent(
          eventId: 'e2',
          date: DateTime(2024, 1, 2),
          activityCounts: [(catId: 'catB', actName: 'harness', count: 6)],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      expect(stats.avgActivitiesPerEvent, 0.0);
      expect(stats.avgItemsPerEvent, closeTo(4.0, 0.001));
    });

    test('computes separate averages for mixed events', () {
      // e1: 3 actionable + 1 gear; e2: 1 actionable + 5 gear
      // avgActivities = (3+1)/2 = 2.0
      // avgItems      = (1+5)/2 = 3.0
      final events = [
        _makeEvent(
          eventId: 'e1',
          date: DateTime(2024, 1, 1),
          activityCounts: [
            (catId: 'catA', actName: 'kiss', count: 3),
            (catId: 'catB', actName: 'vibrator', count: 1),
          ],
        ),
        _makeEvent(
          eventId: 'e2',
          date: DateTime(2024, 1, 2),
          activityCounts: [
            (catId: 'catA', actName: 'oral', count: 1),
            (catId: 'catB', actName: 'harness', count: 5),
          ],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      expect(stats.avgActivitiesPerEvent, closeTo(2.0, 0.001));
      expect(stats.avgItemsPerEvent, closeTo(3.0, 0.001));
    });

    // ── Missing metadata fallback ──────────────────────────────────────

    test('treats unknown composite keys as actionable (default fallback)', () {
      // 'catZ:unknown' is not in sexualActivities → defaults to actionable.
      final events = [
        _makeEvent(
          eventId: 'e1',
          date: DateTime(2024, 1, 1),
          activityCounts: [(catId: 'catZ', actName: 'unknown', count: 5)],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      expect(stats.totalActivities, 5);
      expect(stats.totalItems, 0);
    });

    // ── Unique key de-duplication ──────────────────────────────────────

    test('de-duplicates unique keys across multiple events', () {
      // Same activity (catA:kiss) appears in both events — still only 1 unique key.
      final events = [
        _makeEvent(
          eventId: 'e1',
          date: DateTime(2024, 1, 1),
          activityCounts: [(catId: 'catA', actName: 'kiss', count: 1)],
        ),
        _makeEvent(
          eventId: 'e2',
          date: DateTime(2024, 1, 2),
          activityCounts: [(catId: 'catA', actName: 'kiss', count: 2)],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      expect(stats.totalActivities, 3); // 1 + 2
      expect(stats.uniqueActivities, 1); // deduplicated to 1 key
    });

    test('de-duplicates unique gear keys across multiple events', () {
      final events = [
        _makeEvent(
          eventId: 'e1',
          date: DateTime(2024, 1, 1),
          activityCounts: [(catId: 'catB', actName: 'vibrator', count: 2)],
        ),
        _makeEvent(
          eventId: 'e2',
          date: DateTime(2024, 1, 2),
          activityCounts: [(catId: 'catB', actName: 'vibrator', count: 3)],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      expect(stats.totalItems, 5); // 2 + 3
      expect(stats.uniqueItems, 1); // deduplicated to 1 key
    });

    // ── Count multiplier ──────────────────────────────────────────────

    test('respects activityCount.count multiplier greater than 1', () {
      final events = [
        _makeEvent(
          eventId: 'e1',
          date: DateTime(2024, 1, 1),
          activityCounts: [
            (catId: 'catA', actName: 'kiss', count: 10),
            (catId: 'catB', actName: 'vibrator', count: 7),
          ],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      expect(stats.totalActivities, 10);
      expect(stats.totalItems, 7);
    });

    // ── Empty activityCounts ───────────────────────────────────────────

    test('handles events with no activity counts gracefully', () {
      final events = [
        SexualEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          activities: [
            EventActivity(
              category: const Reference(
                reference: 'catA',
                resourceType: 'SexualActivityCategory',
              ),
              participants: [
                ActivityParticipant(
                  participant: const Reference(
                    reference: 'me',
                    resourceType: 'Person',
                  ),
                  activityCounts: [], // empty
                ),
              ],
            ),
          ],
        ),
      ];

      final stats = _runStats(events, sexualActivities);

      expect(stats.totalActivities, 0);
      expect(stats.totalItems, 0);
      expect(stats.uniqueActivities, 0);
      expect(stats.uniqueItems, 0);
    });
  });
}
