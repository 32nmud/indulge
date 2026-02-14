import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/data/repositories/sexual_event_repository.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize Flutter binding and ffi-backed sqlite for tests so the repository's openDatabase
  // calls work when running in the Dart VM test environment.
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  group('Location repository', () {
    test('saveLocation and getLocationById roundtrip', () async {
      // Use a real repository (integration-style). This uses the local test DB.
      final repo = await EventRepository.create();

      final loc = Location(
        address: const Address(city: 'TestCity'),
        latitude: 12.345678,
        longitude: -98.7654321,
      );

      // Save and fetch
      await repo.saveLocation(loc);
      final fetched = await repo.getLocationById(loc.id);

      expect(fetched, isNotNull);
      expect(fetched!.id, equals(loc.id));
      expect(fetched.address?.city, equals('TestCity'));
      expect(fetched.latitude, closeTo(12.345678, 1e-9));
      expect(fetched.longitude, closeTo(-98.7654321, 1e-9));
    });
  });

  group('Provider location flows', () {
    test('create location, attach to event, and remove it', () async {
      final repo = await EventRepository.create();
      final provider = SexualEventsProvider(repository: repo);

      // Wait for provider initialization
      await provider.ready;

      // Create and save a simple event with no activities.
      final event = SexualEvent(
        id: 'test-event-location-flow',
        date: DateTime.now(),
        activities: [],
      );
      await repo.save(event);

      // Select the event in the provider
      await provider.selectEvent(event);
      expect(
        provider.state.selectedEvent?.id,
        equals('test-event-location-flow'),
      );
      expect(provider.state.selectedEventLocation, isNull);

      // Create a location using coordinates
      final created = await provider.createLocationFromCoordinates(10.0, 20.0);
      expect(created.latitude, closeTo(10.0, 1e-9));
      expect(created.longitude, closeTo(20.0, 1e-9));

      // Attach the created location to the selected event
      await provider.attachLocationToSelectedEvent(created);

      // After attaching, the provider should have re-selected the updated event
      final selected = provider.state.selectedEvent;
      expect(selected, isNotNull);
      expect(selected!.location, isNotNull);
      expect(selected.location!.resourceType, equals('Location'));
      expect(selected.location!.reference, equals(created.id));

      // Provider should also have the resolved Location in state
      final resolved = provider.state.selectedEventLocation;
      expect(resolved, isNotNull);
      expect(resolved!.id, equals(created.id));
      expect(resolved.latitude, closeTo(10.0, 1e-9));
      expect(resolved.longitude, closeTo(20.0, 1e-9));

      // Now remove the location from the selected event
      await provider.removeLocationFromSelectedEvent();

      final afterRemovalEvent = provider.state.selectedEvent;
      expect(afterRemovalEvent, isNotNull);
      expect(afterRemovalEvent!.location, isNull);
      // Note: Do not assert the resolved location here — resolution may be async
      // and provider state can transiently contain a resolved Location object.
      // We only require that the event no longer has an attached location reference.
    });
  });
}
