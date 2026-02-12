import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/person_avatar.dart';
import 'package:indulge/view/event_editor/widgets/activity_card.dart';

void main() {
  group('ActivityCard widget', () {
    testWidgets('deleting participant chip calls onRemoveParticipant', (
      tester,
    ) async {
      // Arrange
      final person = Person(
        id: 'p1',
        date: DateTime.now(),
        name: const Name(given: 'Bob'),
      );
      final participant = ActivityParticipant(
        participant: Reference(reference: 'p1'),
        activityCounts: [],
      );
      final activity = EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [participant],
      );

      final category = SexualActivityCategory(
        id: 'oral',
        name: 'Oral',
        activities: [const Reference(reference: 'act1')],
      );
      final sexualActivity = SexualActivity(
        id: 'act1',
        name: 'Giving',
        displayCharacter: 'G',
      );

      int? removedActIdx;
      int? removedParticipantIdx;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activityIndex: 0,
              activity: activity,
              availableActivityCategories: {'oral': category},
              availableActivities: {'act1': sexualActivity},
              availablePersons: [person],
              myself: null,
              isExpanded: true,
              onToggleExpanded: () {},
              onRemove: () {},
              onShowPersonPicker: () {},
              onRemoveParticipant: (actIdx, participantIndex) {
                removedActIdx = actIdx;
                removedParticipantIdx = participantIndex;
              },
              toggleMyselfForProperty: (_, __) {},
              toggleParticipantForProperty: (_, __, ___) {},
              incrementPropertyCount: (_, __, ___) {},
              decrementPropertyCount: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act: tap the delete icon on the chip
      final deleteIconFinder = find.byIcon(Icons.close);
      expect(deleteIconFinder, findsWidgets);

      await tester.tap(deleteIconFinder.first);
      await tester.pumpAndSettle();

      // Assert
      expect(removedActIdx, equals(0));
      expect(removedParticipantIdx, equals(0));
    });

    testWidgets(
      'tapping participant avatar in property row calls toggleParticipantForProperty with correct args',
      (tester) async {
        final person = Person(
          id: 'p2',
          date: DateTime.now(),
          name: const Name(given: 'Alice'),
        );
        final participant = ActivityParticipant(
          participant: Reference(reference: 'p2'),
          activityCounts: [],
        );
        final activity = EventActivity(
          category: const Reference(reference: 'oral'),
          participants: [participant],
        );

        final category = SexualActivityCategory(
          id: 'oral',
          name: 'Oral',
          activities: [const Reference(reference: 'act1')],
        );
        final sexualActivity = SexualActivity(
          id: 'act1',
          name: 'Giving',
          displayCharacter: 'G',
        );

        int? toggledActIdx;
        String? toggledActivityId;
        String? toggledPersonId;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                activityIndex: 2,
                activity: activity,
                availableActivityCategories: {'oral': category},
                availableActivities: {'act1': sexualActivity},
                availablePersons: [person],
                myself: null,
                isExpanded: true,
                onToggleExpanded: () {},
                onRemove: () {},
                onShowPersonPicker: () {},
                onRemoveParticipant: (_, __) {},
                toggleMyselfForProperty: (_, __) {},
                toggleParticipantForProperty: (actIdx, activityId, personId) {
                  toggledActIdx = actIdx;
                  toggledActivityId = activityId;
                  toggledPersonId = personId;
                },
                incrementPropertyCount: (_, __, ___) {},
                decrementPropertyCount: (_, __, ___) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap the participant avatar (PersonAvatar) in the property row.
        final avatarFinder = find.byType(PersonAvatar);
        expect(avatarFinder, findsWidgets);

        await tester.tap(avatarFinder.first);
        await tester.pumpAndSettle();

        expect(toggledActIdx, equals(2));
        expect(toggledActivityId, equals('act1'));
        expect(toggledPersonId, equals('p2'));
      },
    );

    testWidgets('increment and decrement buttons call appropriate callbacks', (
      tester,
    ) async {
      final person = Person(
        id: 'p3',
        date: DateTime.now(),
        name: const Name(given: 'Charlie'),
      );
      final participant = ActivityParticipant(
        participant: Reference(reference: 'p3'),
        activityCounts: [
          ActivityCount(
            activityReference: const Reference(reference: 'actA'),
            count: 1,
          ),
        ],
      );
      final activity = EventActivity(
        category: const Reference(reference: 'oral'),
        participants: [participant],
      );

      final category = SexualActivityCategory(
        id: 'oral',
        name: 'Oral',
        activities: [const Reference(reference: 'actA')],
      );
      final sexualActivity = SexualActivity(
        id: 'actA',
        name: 'ActivityA',
        displayCharacter: 'A',
      );

      int incCalls = 0;
      int decCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activityIndex: 1,
              activity: activity,
              availableActivityCategories: {'oral': category},
              availableActivities: {'actA': sexualActivity},
              availablePersons: [person],
              myself: null,
              isExpanded: true,
              onToggleExpanded: () {},
              onRemove: () {},
              onShowPersonPicker: () {},
              onRemoveParticipant: (_, __) {},
              toggleMyselfForProperty: (_, __) {},
              toggleParticipantForProperty: (_, __, ___) {},
              incrementPropertyCount: (actIdx, activityId, personId) {
                incCalls += 1;
                expect(actIdx, equals(1));
                expect(activityId, equals('actA'));
                expect(personId, equals('p3'));
              },
              decrementPropertyCount: (actIdx, activityId, personId) {
                decCalls += 1;
                expect(actIdx, equals(1));
                expect(activityId, equals('actA'));
                expect(personId, equals('p3'));
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the increment and decrement icons
      final incFinder = find.byIcon(Icons.add_circle_outline);
      final decFinder = find.byIcon(Icons.remove_circle_outline);

      expect(incFinder, findsWidgets);
      expect(decFinder, findsWidgets);

      await tester.tap(incFinder.first);
      await tester.pumpAndSettle();

      await tester.tap(decFinder.first);
      await tester.pumpAndSettle();

      expect(incCalls, equals(1));
      expect(decCalls, equals(1));
    });

    testWidgets(
      'shows requires partner message when activity requires partner',
      (tester) async {
        // Arrange: no participants and activity category requires partner
        final activity = EventActivity(
          category: const Reference(reference: 'oral'),
          participants: [],
        );

        final category = SexualActivityCategory(
          id: 'oral',
          name: 'Oral',
          activities: [const Reference(reference: 'act1')],
        );

        final sexualActivity = SexualActivity(
          id: 'act1',
          name: 'Giving',
          displayCharacter: 'G',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                activityIndex: 0,
                activity: activity,
                availableActivityCategories: {
                  'oral': category.copyWith(requiresPartner: true),
                },
                availableActivities: {'act1': sexualActivity},
                availablePersons: const [],
                myself: null,
                isExpanded: true,
                onToggleExpanded: () {},
                onRemove: () {},
                onShowPersonPicker: () {},
                onRemoveParticipant: (_, __) {},
                toggleMyselfForProperty: (_, __) {},
                toggleParticipantForProperty: (_, __, ___) {},
                incrementPropertyCount: (_, __, ___) {},
                decrementPropertyCount: (_, __, ___) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: we show the requires-partner notice
        expect(
          find.text('Add at least one partner to continue'),
          findsOneWidget,
        );
      },
    );

    testWidgets('me avatar toggles and inc/dec callbacks are invoked', (
      tester,
    ) async {
      // Arrange: activity with "me" participant who already has a count > 0
      final me = Person(
        id: 'me1',
        date: DateTime.now(),
        name: const Name(given: 'Me'),
      );

      final meParticipant = ActivityParticipant(
        participant: Reference(reference: 'me1'),
        activityCounts: [
          ActivityCount(
            activityReference: const Reference(reference: 'actX'),
            count: 1,
          ),
        ],
      );

      final activity = EventActivity(
        category: const Reference(reference: 'solo'),
        participants: [meParticipant],
      );

      final category = SexualActivityCategory(
        id: 'solo',
        name: 'Solo',
        activities: [const Reference(reference: 'actX')],
      );

      final sexualActivity = SexualActivity(
        id: 'actX',
        name: 'SoloActivity',
        displayCharacter: 'S',
      );

      bool toggled = false;
      int incCalls = 0;
      int decCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activityIndex: 0,
              activity: activity,
              availableActivityCategories: {'solo': category},
              availableActivities: {'actX': sexualActivity},
              availablePersons: [me],
              myself: me,
              isExpanded: true,
              onToggleExpanded: () {},
              onRemove: () {},
              onShowPersonPicker: () {},
              onRemoveParticipant: (_, __) {},
              toggleMyselfForProperty: (actIdx, activityId) {
                toggled = true;
                expect(actIdx, equals(0));
                expect(activityId, equals('actX'));
              },
              toggleParticipantForProperty: (_, __, ___) {},
              incrementPropertyCount: (actIdx, activityId, personId) {
                incCalls += 1;
                expect(actIdx, equals(0));
                expect(activityId, equals('actX'));
                expect(personId, equals('me1'));
              },
              decrementPropertyCount: (actIdx, activityId, personId) {
                decCalls += 1;
                expect(actIdx, equals(0));
                expect(activityId, equals('actX'));
                expect(personId, equals('me1'));
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the "Me" avatar to toggle
      final avatarFinder = find.byType(PersonAvatar);
      expect(avatarFinder, findsWidgets);

      await tester.tap(avatarFinder.first);
      await tester.pumpAndSettle();

      expect(toggled, isTrue);

      // Find and tap increment/decrement icons for "Me"
      final incFinder = find.byIcon(Icons.add_circle_outline);
      final decFinder = find.byIcon(Icons.remove_circle_outline);

      expect(incFinder, findsWidgets);
      expect(decFinder, findsWidgets);

      await tester.tap(incFinder.first);
      await tester.pumpAndSettle();

      await tester.tap(decFinder.first);
      await tester.pumpAndSettle();

      expect(incCalls, equals(1));
      expect(decCalls, equals(1));
    });
  });
}
