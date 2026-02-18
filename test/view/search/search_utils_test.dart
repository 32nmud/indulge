import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/view/search/utils/search_utils.dart';
import 'package:indulge/data/models.dart';

void main() {
  group('filterSexualEvents', () {
    // Helpers to build model objects more concisely
    Reference ref(String id, String resourceType) =>
        Reference(reference: id, resourceType: resourceType);

    ActivityCount activityCount(String activityId) => ActivityCount(
      activityReference: ref(activityId, 'SexualActivity'),
      count: 1,
      version: 2,
    );

    ActivityParticipant participant(
      String participantId, {
      List<ActivityCount> counts = const [],
    }) => ActivityParticipant(
      participant: ref(participantId, 'Person'),
      activityCounts: counts,
    );

    EventActivity activity(
      String categoryId,
      List<ActivityParticipant> parts,
    ) => EventActivity(
      category: ref(categoryId, 'SexualActivityCategory'),
      participants: parts,
    );

    SexualEvent event(
      String id,
      DateTime date, {
      List<EventActivity> activities = const [],
      String? notes,
    }) => SexualEvent(id: id, date: date, activities: activities, notes: notes);

    test('date range filter is inclusive of start and end', () {
      final eStart = event(
        'e-start',
        DateTime(2024, 1, 1),
        activities: [activity('cat', [])],
      );
      final eMid = event(
        'e-mid',
        DateTime(2024, 1, 4),
        activities: [activity('cat', [])],
      );
      final eAfter = event(
        'e-after',
        DateTime(2024, 1, 5),
        activities: [activity('cat', [])],
      );

      final all = [eStart, eMid, eAfter];

      final range = DateTimeRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 4),
      );

      final filtered = filterSexualEvents(all, dateRange: range);

      // Should include start and mid but exclude the after date
      expect(filtered.map((e) => e.id).toSet(), equals({'e-mid', 'e-start'}));
    });

    test('notes filter is case-insensitive and matches substrings', () {
      final e1 = event(
        'n-1',
        DateTime(2024, 2, 1),
        notes: 'This is a Hello World note',
        activities: [activity('cat', [])],
      );
      final e2 = event(
        'n-2',
        DateTime(2024, 2, 2),
        notes: 'unrelated',
        activities: [activity('cat', [])],
      );

      final filtered = filterSexualEvents([e1, e2], notesQuery: 'hello');

      expect(filtered.length, 1);
      expect(filtered.first.id, 'n-1');
    });

    test('eventType Solo/Couple/Group logic respects myselfId', () {
      // Solo: only myself present
      final solo = event(
        'solo',
        DateTime(2024, 3, 1),
        activities: [
          activity('cat', [participant('me')]),
        ],
      );

      // Couple: one non-myself partner present
      final couple = event(
        'couple',
        DateTime(2024, 3, 2),
        activities: [
          activity('cat', [participant('me'), participant('p1')]),
        ],
      );

      // Group: two or more non-myself partners present
      final group = event(
        'group',
        DateTime(2024, 3, 3),
        activities: [
          activity('cat', [
            participant('me'),
            participant('p1'),
            participant('p2'),
          ]),
        ],
      );

      final all = [solo, couple, group];

      final soloFiltered = filterSexualEvents(
        all,
        eventType: 'Solo',
        myselfId: 'me',
      );
      expect(soloFiltered.map((e) => e.id).toSet(), equals({'solo'}));

      final coupleFiltered = filterSexualEvents(
        all,
        eventType: 'Couple',
        myselfId: 'me',
      );
      expect(coupleFiltered.map((e) => e.id).toSet(), equals({'couple'}));

      final groupFiltered = filterSexualEvents(
        all,
        eventType: 'Group',
        myselfId: 'me',
      );
      expect(groupFiltered.map((e) => e.id).toSet(), equals({'group'}));
    });

    test('partner filter requires at least one matching partner', () {
      final e1 = event(
        'p-a',
        DateTime(2024, 4, 1),
        activities: [
          activity('cat', [participant('alice')]),
        ],
      );
      final e2 = event(
        'p-b',
        DateTime(2024, 4, 2),
        activities: [
          activity('cat', [participant('bob')]),
        ],
      );
      final all = [e1, e2];

      final filtered = filterSexualEvents(all, partnerIds: {'bob'});
      expect(filtered.length, 1);
      expect(filtered.first.id, 'p-b');
    });

    test(
      'category filter requires at least one matching activity category',
      () {
        final e1 = event(
          'c-1',
          DateTime(2024, 5, 1),
          activities: [
            activity('cat-a', [participant('x')]),
          ],
        );
        final e2 = event(
          'c-2',
          DateTime(2024, 5, 2),
          activities: [
            activity('cat-b', [participant('y')]),
          ],
        );

        final filtered = filterSexualEvents([e1, e2], categoryIds: {'cat-b'});
        expect(filtered.length, 1);
        expect(filtered.first.id, 'c-2');
      },
    );

    test('activity composite key filter matches categoryId:activityId', () {
      // Create an event where an activity in category 'cat1' has a participant
      // with an activity count pointing to 'act1'
      final e = event(
        'a-1',
        DateTime(2024, 6, 1),
        activities: [
          activity('cat1', [
            participant('u1', counts: [activityCount('act1')]),
          ]),
        ],
      );

      // Non-matching composite key should exclude
      final none = filterSexualEvents([e], activityKeys: {'cat1:other'});
      expect(none, isEmpty);

      // Matching key should include
      final match = filterSexualEvents([e], activityKeys: {'cat1:act1'});
      expect(match.length, 1);
      expect(match.first.id, 'a-1');
    });

    test('results are sorted by date descending (most recent first)', () {
      final older = event(
        'old',
        DateTime(2023, 1, 1),
        activities: [activity('cat', [])],
      );
      final newer = event(
        'new',
        DateTime(2024, 1, 1),
        activities: [activity('cat', [])],
      );

      final all = [older, newer];

      final filtered = filterSexualEvents(all);
      expect(filtered.length, 2);
      expect(filtered[0].id, 'new');
      expect(filtered[1].id, 'old');
    });

    test('combination of filters works together', () {
      // Complex event that should match multiple filters
      final e = event(
        'combo',
        DateTime(2024, 7, 1),
        notes: 'A special encounter',
        activities: [
          activity('catX', [
            participant('me', counts: [activityCount('actX')]),
            participant('pA'),
          ]),
        ],
      );

      final filtered = filterSexualEvents(
        [e],
        dateRange: DateTimeRange(
          start: DateTime(2024, 7, 1),
          end: DateTime(2024, 7, 1),
        ),
        notesQuery: 'special',
        eventType: 'Couple', // one non-myself partner (pA)
        partnerIds: {'pA'},
        categoryIds: {'catX'},
        activityKeys: {'catX:actX'},
        myselfId: 'me',
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, 'combo');
    });

    test('handles events with empty activities', () {
      final noAct = event('noact', DateTime(2024, 8, 1), activities: []);
      final all = [noAct];

      // With no filters, event with empty activities should still be returned
      final filtered = filterSexualEvents(all);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'noact');

      // But category filter should exclude it
      final filteredByCat = filterSexualEvents(all, categoryIds: {'any'});
      expect(filteredByCat, isEmpty);
    });

    test('activity filter handles empty activityReference values', () {
      // activityCount with empty activityReference.reference
      final badActivityCount = ActivityCount(
        activityReference: Reference(
          reference: '',
          resourceType: 'SexualActivity',
        ),
        count: 1,
        version: 2,
      );

      final e = event(
        'empty-activity-ref',
        DateTime(2024, 9, 1),
        activities: [
          activity('catZ', [
            participant('u1', counts: [badActivityCount]),
          ]),
        ],
      );

      // Searching for composite 'catZ:' (category with empty activity id) should match
      final match = filterSexualEvents([e], activityKeys: {'catZ:'});
      expect(match.length, 1);
      expect(match.first.id, 'empty-activity-ref');

      // Non-matching composite should not include it
      final none = filterSexualEvents([e], activityKeys: {'catZ:actX'});
      expect(none, isEmpty);
    });

    test('partner filter ignores participants with empty references', () {
      // participant with empty reference
      final emptyParticipant = ActivityParticipant(
        participant: Reference(reference: '', resourceType: 'Person'),
        activityCounts: [],
      );

      final e = event(
        'empty-participant',
        DateTime(2024, 10, 1),
        activities: [
          activity('cat', [emptyParticipant]),
        ],
      );

      // Filtering by any non-empty partner id should not match
      final filtered = filterSexualEvents([e], partnerIds: {'alice'});
      expect(filtered, isEmpty);
    });

    test('notesQuery treating whitespace only as empty (no-op)', () {
      final e = event(
        'ws',
        DateTime(2024, 11, 1),
        notes: 'Has content',
        activities: [activity('cat', [])],
      );

      final filtered = filterSexualEvents([e], notesQuery: '   ');
      // Whitespace-only query should be treated as empty and not filter out the event
      expect(filtered.length, 1);
      expect(filtered.first.id, 'ws');
    });
  });
}
