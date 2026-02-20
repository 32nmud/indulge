import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/view/common/contact_editor/contact_editor_page.dart';
import 'package:uuid/uuid.dart';
import 'utils/event_mutations.dart';
import 'widgets/widgets.dart';
import 'widgets/activity_card.dart';
import 'utils/event_validator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:indulge/services/preferences_service.dart';

class SexualEventEditorPage extends StatefulWidget {
  final SexualEvent? event;
  final DateTime? initialDate;

  const SexualEventEditorPage({super.key, this.event, this.initialDate});

  @override
  State<SexualEventEditorPage> createState() => _SexualEventEditorPageState();
}

class _SexualEventEditorPageState extends State<SexualEventEditorPage> {
  late SexualEvent _workingEvent;
  bool _isLoading = true;
  List<Person> _availablePersons = [];
  Map<String, SexualActivityCategory> _availableActivityCategories = {};
  Map<String, SexualActivity> _availableActivities = {};
  final Set<int> _expandedActivities = {};

  // --- Location UI state ---
  bool _showLocationMap = false;
  bool _isFetchingLocation = false;

  // Default pin coordinates (center of US).
  double _pinLatitude = 39.8283;
  double _pinLongitude = -98.5795;
  final fm.MapController _mapController = fm.MapController();
  double _mapZoom = 13.0;

  // Pending coordinates selected in the editor UI.
  // These are editor-local and are only persisted when Save is pressed.
  double? _pendingLocationLat;
  double? _pendingLocationLng;

  @override
  void initState() {
    super.initState();
    _initializeEvent();
  }

  void _clearPendingLocation() {
    setState(() {
      _pendingLocationLat = null;
      _pendingLocationLng = null;
    });
  }

  void _setPendingLocationFromCoords(double lat, double lng) {
    setState(() {
      _pendingLocationLat = lat;
      _pendingLocationLng = lng;
    });
  }

  void _setPin(double lat, double lng) {
    setState(() {
      _pinLatitude = lat;
      _pinLongitude = lng;
    });
    try {
      _mapController.move(ll.LatLng(lat, lng), _mapZoom);
    } catch (_) {
      // mapController may not be ready; ignore.
    }
  }

  Future<void> _initializeEvent() async {
    final provider = context.read<SexualEventsProvider>();
    await provider.ready;

    final store = context.read<EventStateStore>();
    final persons = store.state.allPersons ?? await provider.getAllPersons();
    final activityCategories = store.state.sexualActivityCategories ?? {};
    final activities = store.state.sexualActivities ?? {};

    if (widget.event != null) {
      // Editing existing event: set working event and ensure provider resolves
      // surrounding state for the same event so any resolved location is for
      // the event we're editing (not a previously-selected event).
      _workingEvent = widget.event!;

      try {
        await provider.selectEvent(_workingEvent);
      } catch (e) {
        debugPrint('Warning: failed to select event in editor: $e');
      }

      // If the event already has an attached (persisted) Location reference,
      // prefer the resolved provider location to initialize the map pin.
      if (_workingEvent.location != null &&
          store.state.selectedEvent?.id == _workingEvent.id &&
          store.state.selectedEventLocation != null) {
        final resolved = store.state.selectedEventLocation!;
        _pinLatitude = resolved.latitude;
        _pinLongitude = resolved.longitude;
        // No pending selection: this is an already-saved location.
        _clearPendingLocation();
      } else {
        // No saved location for this event; ensure no stale pending coords exist.
        _clearPendingLocation();
        // Keep default pin center (or previously configured values).
      }
    } else {
      // Creating a new event: initialize a blank working event and clear pending.
      // If the event is for today, populate with current time; otherwise use midnight.
      final initialDate = widget.initialDate ?? DateTime.now();
      final now = DateTime.now();
      final bool isSameDay =
          initialDate.year == now.year &&
          initialDate.month == now.month &&
          initialDate.day == now.day;
      final eventDate = isSameDay
          ? DateTime(now.year, now.month, now.day, now.hour, now.minute)
          : DateTime(initialDate.year, initialDate.month, initialDate.day);
      _workingEvent = SexualEvent(
        id: const Uuid().v4(),
        date: eventDate,
        activities: [],
      );
      _clearPendingLocation();
    }

    // Check if auto-add location setting is enabled
    final prefs = await PreferencesService.build();
    final shouldAutoAddLocation =
        widget.event == null && prefs.getAutoAddLocation();

    setState(() {
      _availablePersons = persons;
      _availableActivityCategories = activityCategories;
      _availableActivities = activities;
      _isLoading = false;
    });

    // After UI loads, if auto-add is enabled, show map and fetch location
    if (shouldAutoAddLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openLocationMap();
      });
    }
  }

  void _updateNotes(String notes) {
    setState(() {
      _workingEvent = _workingEvent.copyWith(notes: notes);
    });
  }

  void _updateDate(DateTime newDate) {
    setState(() {
      _workingEvent = _workingEvent.copyWith(date: newDate);
    });
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _workingEvent.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_workingEvent.date),
    );

    if (pickedTime != null) {
      final newDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _updateDate(newDateTime);
    } else {
      final newDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _workingEvent.date.hour,
        _workingEvent.date.minute,
      );
      _updateDate(newDateTime);
    }
  }

  void _addActivity(SexualActivityCategory activityCategory) {
    setState(() {
      _workingEvent = addActivity(_workingEvent, activityCategory);
      _expandedActivities.add(_workingEvent.activities.length - 1);
    });
  }

  void _removeActivity(int activityIndex) {
    setState(() {
      _workingEvent = removeActivity(_workingEvent, activityIndex);
      _expandedActivities.remove(activityIndex);
      final adjustedExpanded = <int>{};
      for (var idx in _expandedActivities) {
        if (idx > activityIndex) {
          adjustedExpanded.add(idx - 1);
        } else {
          adjustedExpanded.add(idx);
        }
      }
      _expandedActivities
        ..clear()
        ..addAll(adjustedExpanded);
    });
  }

  void _addParticipant(int activityIndex, Person person) {
    final updatedEvent = addParticipant(_workingEvent, activityIndex, person);
    if (identical(updatedEvent, _workingEvent)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${person.name.given ?? "This participant"} is already in this activity',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _workingEvent = updatedEvent;
    });
  }

  void _toggleMyselfForProperty(int activityIndex, String activityId) {
    final myself = context.read<EventStateStore>().state.myself;
    if (myself == null) return;

    setState(() {
      _workingEvent = toggleMyselfForProperty(
        _workingEvent,
        activityIndex,
        myself.id,
        activityId,
      );
    });
  }

  void _toggleParticipantForProperty(
    int activityIndex,
    String activityId,
    String personId,
  ) {
    setState(() {
      _workingEvent = toggleParticipantForProperty(
        _workingEvent,
        activityIndex,
        activityId,
        personId,
      );
    });
  }

  void _incrementPropertyCount(
    int activityIndex,
    String activityId,
    String personId,
  ) {
    setState(() {
      _workingEvent = incrementPropertyCount(
        _workingEvent,
        activityIndex,
        activityId,
        personId,
      );
    });
  }

  void _decrementPropertyCount(
    int activityIndex,
    String activityId,
    String personId,
  ) {
    setState(() {
      _workingEvent = decrementPropertyCount(
        _workingEvent,
        activityIndex,
        activityId,
        personId,
      );
    });
  }

  Future<void> _showActivityPicker() async {
    final activityCategory = await ActivityPickerDialog.show(
      context: context,
      availableCategories: _availableActivityCategories,
    );

    if (activityCategory != null) {
      _addActivity(activityCategory);
    }
  }

  Future<void> _showPersonPicker(int activityIndex) async {
    final myself = context.read<EventStateStore>().state.myself;

    final EventActivity activity = _workingEvent.activities[activityIndex];
    final activityCategory =
        _availableActivityCategories[activity.category.reference];
    final activityRequiresPartner = activityCategory?.requiresPartner ?? false;
    final existingParticipantIds = activity.participants
        .map((p) => p.participant.reference)
        .toSet();

    final result = await PersonPickerDialog.show(
      context: context,
      availablePersons: _availablePersons,
      existingParticipantIds: existingParticipantIds,
      myself: myself,
      hideMyself: activityRequiresPartner,
      onAddNew: () {},
    );

    if (result == 'ADD_NEW') {
      final newPerson = await Navigator.push<Person>(
        context,
        MaterialPageRoute(builder: (context) => const ContactEditorPage()),
      );

      if (newPerson != null) {
        final provider = context.read<SexualEventsProvider>();
        final store = context.read<EventStateStore>();
        final persons =
            store.state.allPersons ?? await provider.getAllPersons();
        setState(() {
          _availablePersons = persons;
        });
        _addParticipant(activityIndex, newPerson);
      }
    } else if (result != null && result is Person) {
      _addParticipant(activityIndex, result);
    }
  }

  bool _validateEvent() {
    final myself = context.read<EventStateStore>().state.myself;

    return EventValidator.validateEvent(
      context: context,
      event: _workingEvent,
      availableActivityCategories: _availableActivityCategories,
      myself: myself,
    );
  }

  Future<void> _saveEvent() async {
    if (!_validateEvent()) {
      return;
    }

    try {
      final provider = context.read<SexualEventsProvider>();

      // If the editor has a pending location selection, persist it first
      // and attach the resulting Location reference to the event being saved.
      if (_pendingLocationLat != null && _pendingLocationLng != null) {
        final loc = await provider.createLocationFromCoordinates(
          _pendingLocationLat!,
          _pendingLocationLng!,
        );
        _workingEvent = _workingEvent.copyWith(location: loc);
        _clearPendingLocation();
      }

      await provider.saveEvent(_workingEvent);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open the location map UI and attempt to center on the device's current
  /// location. Fall back to a resolved event location only when provider's
  /// selectedEvent matches the working event; otherwise prefer device location
  /// or default.
  Future<void> _openLocationMap() async {
    final store = context.read<EventStateStore>();

    setState(() {
      _showLocationMap = true;
      _isFetchingLocation = true;
    });

    // If the current working event has a saved location and the provider has
    // resolved it for this same event, initialize from that resolved Location.
    if (_workingEvent.location != null &&
        store.state.selectedEvent?.id == _workingEvent.id &&
        store.state.selectedEventLocation != null) {
      final resolved = store.state.selectedEventLocation!;
      _setPin(resolved.latitude, resolved.longitude);
      _setPendingLocationFromCoords(resolved.latitude, resolved.longitude);
      setState(() => _isFetchingLocation = false);
      return;
    }

    // Otherwise attempt to use device location (permissions + service checks)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services disabled — using default location.',
              ),
            ),
          );
        }
        _setPin(39.8283, -98.5795);
        _setPendingLocationFromCoords(39.8283, -98.5795);
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission denied — using default location.',
              ),
            ),
          );
        }
        _setPin(39.8283, -98.5795);
        _setPendingLocationFromCoords(39.8283, -98.5795);
        setState(() => _isFetchingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _setPin(pos.latitude, pos.longitude);
      _setPendingLocationFromCoords(pos.latitude, pos.longitude);
      setState(() => _isFetchingLocation = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to get current location — using default. ($e)',
            ),
          ),
        );
      }
      _setPin(39.8283, -98.5795);
      _setPendingLocationFromCoords(39.8283, -98.5795);
      setState(() => _isFetchingLocation = false);
    }
  }

  /// Remove any attached location from the currently selected event or clear
  /// the editor's pending selection if not persisted yet.
  Future<void> _removeAttachedLocation() async {
    final store = context.read<EventStateStore>();
    final provider = context.read<SexualEventsProvider>();

    // If the working event has a persisted Location reference, call provider
    // to remove it from the stored event (this persists the change).
    if (_workingEvent.location != null) {
      await provider.removeLocationFromSelectedEvent();

      // After provider operation, sync local working event to provider state if possible.
      final selected = store.state.selectedEvent;
      if (selected != null && selected.id == _workingEvent.id) {
        setState(() {
          _workingEvent = selected;
          _clearPendingLocation();
          _showLocationMap = false;
        });
      } else {
        // If select didn't return the event for some reason, defensively clear.
        setState(() {
          _workingEvent = _workingEvent.copyWith(location: null);
          _clearPendingLocation();
          _showLocationMap = false;
        });
      }
      return;
    }

    // If there's only a pending (unsaved) selection, clear it locally.
    if (_pendingLocationLat != null && _pendingLocationLng != null) {
      setState(() {
        _clearPendingLocation();
        _showLocationMap = false;
      });
      return;
    }

    // Nothing to remove; just close the map UI.
    setState(() {
      _showLocationMap = false;
    });
  }

  Widget _buildDateTimeSection() {
    return DateTimeSection(dateTime: _workingEvent.date, onTap: _pickDateTime);
  }

  Widget _buildNotesSection() {
    return NotesSection(
      initialNotes: _workingEvent.notes,
      onNotesChanged: _updateNotes,
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActivitiesListHeader(onAddActivity: _showActivityPicker),
        const SizedBox(height: 12),
        if (_workingEvent.activities.isEmpty)
          const EmptyActivitiesState()
        else
          ..._workingEvent.activities.asMap().entries.map((entry) {
            return _buildActivityCard(entry.key, entry.value);
          }),
      ],
    );
  }

  Widget _buildActivityCard(int activityIndex, EventActivity activity) {
    final myself = context.read<EventStateStore>().state.myself;
    final isExpanded = _expandedActivities.contains(activityIndex);

    return ActivityCard(
      activityIndex: activityIndex,
      activity: activity,
      availableActivityCategories: _availableActivityCategories,
      availableActivities: _availableActivities,
      availablePersons: _availablePersons,
      myself: myself,
      isExpanded: isExpanded,
      onToggleExpanded: () {
        setState(() {
          if (isExpanded) {
            _expandedActivities.remove(activityIndex);
          } else {
            _expandedActivities.add(activityIndex);
          }
        });
      },
      onRemove: () => _removeActivity(activityIndex),
      onShowPersonPicker: () => _showPersonPicker(activityIndex),
      onRemoveParticipant: (actIdx, participantIndex) {
        setState(() {
          _workingEvent = removeParticipant(
            _workingEvent,
            actIdx,
            participantIndex,
          );
        });
      },
      toggleMyselfForProperty: _toggleMyselfForProperty,
      toggleParticipantForProperty: _toggleParticipantForProperty,
      incrementPropertyCount: _incrementPropertyCount,
      decrementPropertyCount: _decrementPropertyCount,
    );
  }

  // -------------------------
  // Location section (UI)
  // -------------------------
  Widget _buildLocationSection() {
    // Determine attached state from the editor's working event and pending coords.
    final hasAttached =
        _workingEvent.location != null ||
        (_pendingLocationLat != null && _pendingLocationLng != null);

    return LocationEditor(
      showMap: _showLocationMap,
      isFetchingLocation: _isFetchingLocation,
      hasAttached: hasAttached,
      pinLatitude: _pinLatitude,
      pinLongitude: _pinLongitude,
      mapZoom: _mapZoom,
      mapController: _mapController,
      pendingLatitude: _pendingLocationLat,
      pendingLongitude: _pendingLocationLng,
      onRequestLocation: () {
        // Request device location and open the map (preserves existing logic).
        _openLocationMap();
      },
      onOpen: () {
        setState(() {
          _showLocationMap = true;
        });
        // Also attempt to center using existing resolution or device location.
        _openLocationMap();
      },
      onClose: () {
        setState(() {
          _showLocationMap = false;
        });
      },
      onRemove: _removeAttachedLocation,
      onCenterChanged: (lat, lng) {
        setState(() {
          _pinLatitude = lat;
          _pinLongitude = lng;
          _pendingLocationLat = lat;
          _pendingLocationLng = lng;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'New Event' : 'Edit Event'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveEvent,
            tooltip: 'Save Event',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateTimeSection(),
                  const SizedBox(height: 24),
                  _buildActivitiesSection(),
                  const SizedBox(height: 24),
                  _buildNotesSection(),
                  const SizedBox(height: 24),
                  _buildLocationSection(),
                ],
              ),
            ),
    );
  }
}
