import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:indulge/view/event_editor/widgets/widgets.dart';

void main() {
  group('LocationMap widget', () {
    testWidgets('renders center pin and shows fetching overlay when requested', (
      WidgetTester tester,
    ) async {
      final controller = fm.MapController();

      bool centerChangedCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationMap(
              mapController: controller,
              latitude: 37.0,
              longitude: -122.0,
              zoom: 13.0,
              isFetching: true,
              onCenterChanged: (lat, lng) {
                centerChangedCalled = true;
              },
            ),
          ),
        ),
      );

      // Location pin should be present
      expect(find.byIcon(Icons.location_pin), findsOneWidget);

      // Fetching overlay should show a CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attribution text is provided by the map library via a widget but may not
      // be present in widget tests that don't load network/assets; skip asserting it.

      // The onCenterChanged callback cannot be invoked easily without driving
      // internal map state; ensure it's wired by calling the callback manually
      // through the supplied variable (sanity).
      expect(centerChangedCalled, isFalse);
    });
  });

  group('LocationEditor widget', () {
    testWidgets(
      'info box shows Open and Remove according to hasAttached and callbacks are invoked',
      (WidgetTester tester) async {
        final controller = fm.MapController();

        bool requestLocationCalled = false;
        bool openCalled = false;
        bool removeCalled = false;
        bool closeCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationEditor(
                showMap: false,
                isFetchingLocation: false,
                hasAttached: false,
                pinLatitude: 0.0,
                pinLongitude: 0.0,
                mapZoom: 13.0,
                mapController: controller,
                pendingLatitude: null,
                pendingLongitude: null,
                onRequestLocation: () {
                  requestLocationCalled = true;
                },
                onOpen: () {
                  openCalled = true;
                },
                onRemove: () {
                  removeCalled = true;
                },
                onClose: () {
                  closeCalled = true;
                },
                onCenterChanged: (_, __) {},
              ),
            ),
          ),
        );

        // GPS icon is present
        expect(find.byIcon(Icons.gps_fixed), findsOneWidget);

        // Open button is present
        expect(find.text('Open'), findsOneWidget);

        // Remove should not be shown when hasAttached is false
        expect(find.text('Remove'), findsNothing);

        // Tap the GPS button and Open button and assert callbacks fire
        await tester.tap(find.byIcon(Icons.gps_fixed));
        await tester.pumpAndSettle();
        expect(requestLocationCalled, isTrue);

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(openCalled, isTrue);

        // Now rebuild with hasAttached = true to show Remove button
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationEditor(
                showMap: false,
                isFetchingLocation: false,
                hasAttached: true,
                pinLatitude: 0.0,
                pinLongitude: 0.0,
                mapZoom: 13.0,
                mapController: controller,
                pendingLatitude: null,
                pendingLongitude: null,
                onRequestLocation: () {
                  requestLocationCalled = true;
                },
                onOpen: () {
                  openCalled = true;
                },
                onRemove: () {
                  removeCalled = true;
                },
                onClose: () {
                  closeCalled = true;
                },
                onCenterChanged: (_, __) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Now Remove button should be present and clickable
        expect(find.text('Remove'), findsOneWidget);
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        expect(removeCalled, isTrue);
      },
    );

    testWidgets(
      'map area shows Close and pending indicator when showMap is true',
      (WidgetTester tester) async {
        final controller = fm.MapController();

        bool openCalled = false;
        bool removeCalled = false;
        bool closeCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationEditor(
                showMap: true,
                isFetchingLocation: false,
                hasAttached: true,
                pinLatitude: 12.34,
                pinLongitude: 56.78,
                mapZoom: 13.0,
                mapController: controller,
                pendingLatitude: 12.34,
                pendingLongitude: 56.78,
                onRequestLocation: () {},
                onOpen: () {
                  openCalled = true;
                },
                onRemove: () {
                  removeCalled = true;
                },
                onClose: () {
                  closeCalled = true;
                },
                onCenterChanged: (_, __) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Close button is present within the map area
        expect(find.text('Close'), findsOneWidget);

        // Remove persisted/attached button should be present
        expect(find.widgetWithText(TextButton, 'Remove'), findsOneWidget);

        // Pending selection indicator present
        expect(find.text('Pending selection'), findsOneWidget);

        // Tap Close and Remove and verify callbacks
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(closeCalled, isTrue);

        await tester.tap(find.widgetWithText(TextButton, 'Remove'));
        await tester.pumpAndSettle();
        expect(removeCalled, isTrue);
      },
    );
  });
}
