import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';

// Tests for the exclude-filter logic used inside
// _CoOccurrenceSectionState._getPairs. Because that method is private to the
// widget, we replicate the exact computation here so that we can verify it
// in isolation without needing a Flutter widget tree.

// ── Helpers ────────────────────────────────────────────────────────────────

/// Builds a pair key the same way the widget does: sorted IDs joined by '|'.
String _pairKey(String a, String b) {
  final ids = [a, b]..sort();
  return '${ids[0]}|${ids[1]}';
}

/// Replicates the category-pair computation from _getPairs(true).
///
/// [events]          – events to inspect.
/// [excludedIds]     – category IDs excluded from pair counting.
///
/// Returns a sorted-descending list of (pairKey → count) entries.
List<MapEntry<String, int>> _getCategoryPairs(
  List<SexualEvent> events,
  Set<String> excludedIds,
) {
  final pairCounts = <String, int>{};

  for (final event in events) {
    final ids = <String>{};
    for (final activity in event.activities) {
      final id = activity.category.reference;
      if (!excludedIds.contains(id)) ids.add(id);
    }

    final idList = ids.toList()..sort();
    for (int i = 0; i < idList.length; i++) {
      for (int j = i + 1; j < idList.length; j++) {
        final key = _pairKey(idList[i], idList[j]);
        pairCounts[key] = (pairCounts[key] ?? 0) + 1;
      }
    }
  }

  return pairCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
}

/// Replicates the activity-pair computation from _getPairs(false).
///
/// [events]             – events to inspect.
/// [excludedKeys]       – composite keys (catId:actName) excluded from pair counting.
///
/// Returns a sorted-descending list of (pairKey → count) entries.
List<MapEntry<String, int>> _getActivityPairs(
  List<SexualEvent> events,
  Set<String> excludedKeys,
) {
  final pairCounts = <String, int>{};

  for (final event in events) {
    final ids = <String>{};
    for (final activity in event.activities) {
      for (final participant in activity.participants) {
        for (final count in participant.activityCounts) {
          final catRef = count.categoryReference.reference;
          final actName = count.activityName;
          final key = '$catRef:$actName';
          if (!excludedKeys.contains(key)) ids.add(key);
        }
      }
    }

    final idList = ids.toList()..sort();
    for (int i = 0; i < idList.length; i++) {
      for (int j = i + 1; j < idList.length; j++) {
        final key = _pairKey(idList[i], idList[j]);
        pairCounts[key] = (pairCounts[key] ?? 0) + 1;
      }
    }
  }

  return pairCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
}

// ── Fixture builders ──────────────────────────────────────────────────────

/// Creates a SexualEvent where each [categoryId] becomes a separate
/// EventActivity. Each activity gets one participant ('me') whose
/// activityCounts are derived from [activityKeys] (each formatted as
/// 'catId:actName').
SexualEvent _makeEvent({
  required String id,
  required DateTime date,
  List<String> categoryIds = const [],
  List<String> activityKeys = const [],
}) {
  final activities = <EventActivity>[];

  for (final catId in categoryIds) {
    activities.add(
      EventActivity(
        category: Reference(
          reference: catId,
          resourceType: 'SexualActivityCategory',
        ),
        participants: [
          ActivityParticipant(
            participant: const Reference(
              reference: 'me',
              resourceType: 'Person',
            ),
            activityCounts: activityKeys.map((key) {
              final parts = key.split(':');
              return ActivityCount(
                categoryReference: Reference(
                  reference: parts[0],
                  resourceType: 'SexualActivityCategory',
                ),
                activityName: parts.sublist(1).join(':'),
                count: 1,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  return SexualEvent(id: id, date: date, activities: activities);
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('Co-occurrence exclude filter — category pairs', () {
    test('no exclusions: all category pairs are counted', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA', 'catB', 'catC'],
        ),
      ];

      final pairs = _getCategoryPairs(events, {});

      // 3 categories → 3 choose 2 = 3 pairs
      expect(pairs.length, 3);
    });

    test('excluding one category removes all pairs that involve it', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA', 'catB', 'catC'],
        ),
      ];

      // Exclude catC — only catA+catB pair should remain.
      final pairs = _getCategoryPairs(events, {'catC'});

      expect(pairs.length, 1);
      expect(pairs.first.key, _pairKey('catA', 'catB'));
    });

    test('excluding multiple categories reduces pairs accordingly', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA', 'catB', 'catC', 'catD'],
        ),
      ];

      // Exclude catC and catD — only catA+catB remains.
      final pairs = _getCategoryPairs(events, {'catC', 'catD'});

      expect(pairs.length, 1);
      expect(pairs.first.key, _pairKey('catA', 'catB'));
    });

    test('excluding all categories produces no pairs', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA', 'catB'],
        ),
      ];

      final pairs = _getCategoryPairs(events, {'catA', 'catB'});

      expect(pairs, isEmpty);
    });

    test('excluding a category that is not present has no effect', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA', 'catB'],
        ),
      ];

      // catZ doesn't appear in the events.
      final pairs = _getCategoryPairs(events, {'catZ'});

      expect(pairs.length, 1);
      expect(pairs.first.key, _pairKey('catA', 'catB'));
    });

    test(
      'pair count is correct across multiple events with exclusion active',
      () {
        final events = [
          _makeEvent(
            id: 'e1',
            date: DateTime(2024, 1, 1),
            categoryIds: ['catA', 'catB', 'catC'],
          ),
          _makeEvent(
            id: 'e2',
            date: DateTime(2024, 1, 2),
            categoryIds: ['catA', 'catB', 'catC'],
          ),
          _makeEvent(
            id: 'e3',
            date: DateTime(2024, 1, 3),
            categoryIds: ['catA', 'catB'],
          ),
        ];

        // Exclude catC. Remaining pairs: catA+catB (count=3).
        final pairs = _getCategoryPairs(events, {'catC'});

        expect(pairs.length, 1);
        expect(pairs.first.key, _pairKey('catA', 'catB'));
        expect(pairs.first.value, 3);
      },
    );

    test(
      'exclusion reduces count but does not remove pair if still present',
      () {
        // catA+catB co-occurs 3 times; catA+catC co-occurs 2 times.
        // Excluding catC removes the catA+catC pair but not catA+catB.
        final events = [
          _makeEvent(
            id: 'e1',
            date: DateTime(2024, 1, 1),
            categoryIds: ['catA', 'catB', 'catC'],
          ),
          _makeEvent(
            id: 'e2',
            date: DateTime(2024, 1, 2),
            categoryIds: ['catA', 'catB', 'catC'],
          ),
          _makeEvent(
            id: 'e3',
            date: DateTime(2024, 1, 3),
            categoryIds: ['catA', 'catB'],
          ),
        ];

        final pairs = _getCategoryPairs(events, {'catC'});

        expect(pairs.length, 1);
        expect(pairs.first.value, 3); // catA+catB still appears 3 times
      },
    );

    test('empty event list returns no pairs regardless of exclusions', () {
      final pairs = _getCategoryPairs([], {'catA', 'catB'});
      expect(pairs, isEmpty);
    });

    test(
      'single category per event produces no pairs even without exclusion',
      () {
        final events = [
          _makeEvent(
            id: 'e1',
            date: DateTime(2024, 1, 1),
            categoryIds: ['catA'],
          ),
          _makeEvent(
            id: 'e2',
            date: DateTime(2024, 1, 2),
            categoryIds: ['catB'],
          ),
        ];

        final pairs = _getCategoryPairs(events, {});

        expect(pairs, isEmpty);
      },
    );
  });

  group('Co-occurrence exclude filter — activity pairs', () {
    test('no exclusions: all activity pairs are counted', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA'],
          activityKeys: ['catA:kiss', 'catA:oral', 'catA:caress'],
        ),
      ];

      final pairs = _getActivityPairs(events, {});

      // 3 activities → 3 choose 2 = 3 pairs
      expect(pairs.length, 3);
    });

    test('excluding one activity removes all pairs involving it', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA'],
          activityKeys: ['catA:kiss', 'catA:oral', 'catA:caress'],
        ),
      ];

      // Exclude catA:caress — only catA:kiss + catA:oral remains.
      final pairs = _getActivityPairs(events, {'catA:caress'});

      expect(pairs.length, 1);
      expect(pairs.first.key, _pairKey('catA:kiss', 'catA:oral'));
    });

    test('excluding multiple activity keys reduces pairs correctly', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA'],
          activityKeys: ['catA:a', 'catA:b', 'catA:c', 'catA:d'],
        ),
      ];

      // Exclude catA:c and catA:d → only catA:a+catA:b remains.
      final pairs = _getActivityPairs(events, {'catA:c', 'catA:d'});

      expect(pairs.length, 1);
      expect(pairs.first.key, _pairKey('catA:a', 'catA:b'));
    });

    test('excluding all activity keys produces no pairs', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA'],
          activityKeys: ['catA:kiss', 'catA:oral'],
        ),
      ];

      final pairs = _getActivityPairs(events, {'catA:kiss', 'catA:oral'});

      expect(pairs, isEmpty);
    });

    test('pair counts across multiple events with exclusion', () {
      // e1 and e2 both have catA:kiss + catA:oral + catB:vibrator.
      // Excluding catB:vibrator → only catA:kiss+catA:oral pair, count=2.
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA', 'catB'],
          activityKeys: ['catA:kiss', 'catA:oral', 'catB:vibrator'],
        ),
        _makeEvent(
          id: 'e2',
          date: DateTime(2024, 1, 2),
          categoryIds: ['catA', 'catB'],
          activityKeys: ['catA:kiss', 'catA:oral', 'catB:vibrator'],
        ),
      ];

      final pairs = _getActivityPairs(events, {'catB:vibrator'});

      expect(pairs.length, 1);
      expect(pairs.first.key, _pairKey('catA:kiss', 'catA:oral'));
      expect(pairs.first.value, 2);
    });

    test('pairs sorted descending by count', () {
      // catA:kiss + catA:oral appears twice; catA:kiss + catA:caress appears once.
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA'],
          activityKeys: ['catA:kiss', 'catA:oral', 'catA:caress'],
        ),
        _makeEvent(
          id: 'e2',
          date: DateTime(2024, 1, 2),
          categoryIds: ['catA'],
          activityKeys: ['catA:kiss', 'catA:oral'],
        ),
      ];

      final pairs = _getActivityPairs(events, {});

      expect(pairs.first.value, greaterThanOrEqualTo(pairs.last.value));
    });

    test('excluding a key not present in events has no effect', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA'],
          activityKeys: ['catA:kiss', 'catA:oral'],
        ),
      ];

      final pairs = _getActivityPairs(events, {'catZ:nonexistent'});

      expect(pairs.length, 1);
      expect(pairs.first.key, _pairKey('catA:kiss', 'catA:oral'));
    });

    test('empty event list returns no pairs', () {
      final pairs = _getActivityPairs([], {'catA:kiss'});
      expect(pairs, isEmpty);
    });

    test('single activity per event produces no pairs', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA'],
          activityKeys: ['catA:kiss'],
        ),
      ];

      final pairs = _getActivityPairs(events, {});

      expect(pairs, isEmpty);
    });

    test('de-duplicates activity IDs within a single event before pairing', () {
      // Even if activityKeys has duplicate catA:kiss entries, the Set inside
      // _getPairs de-duplicates them so no self-pairs are created.
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2024, 1, 1),
          categoryIds: ['catA'],
          activityKeys: ['catA:kiss', 'catA:kiss', 'catA:oral'],
        ),
      ];

      final pairs = _getActivityPairs(events, {});

      // Only 1 pair: catA:kiss + catA:oral (duplicate kiss is deduplicated)
      expect(pairs.length, 1);
      expect(pairs.first.key, _pairKey('catA:kiss', 'catA:oral'));
      expect(pairs.first.value, 1);
    });
  });
}
