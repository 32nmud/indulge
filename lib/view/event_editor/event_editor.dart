import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/person_editor/person_editor_page.dart';
import 'package:uuid/uuid.dart';
import 'utils/event_mutations.dart';
import 'widgets/widgets.dart';
import 'widgets/activity_card.dart';
import 'utils/event_validator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';

class EventEditorPage extends StatefulWidget {
  final SexualEvent? event;
  final DateTime? initialDate;

  const EventEditorPage({super.key, this.event, this.initialDate});

  @override
  State<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
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

    final persons = await provider.getAllPersons();
    final activityCategories = provider.state.sexualActivityCategories ?? {};
    final activities = provider.state.sexualActivities ?? {};

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
          provider.state.selectedEvent?.id == _workingEvent.id &&
          provider.state.selectedEventLocation != null) {
        final resolved = provider.state.selectedEventLocation!;
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
      _workingEvent = SexualEvent(
        id: const Uuid().v4(),
        date: widget.initialDate ?? DateTime.now(),
        activities: [],
      );
      _clearPendingLocation();
    }

    setState(() {
      _availablePersons = persons;
      _availableActivityCategories = activityCategories;
      _availableActivities = activities;
      _isLoading = false;
    });
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
    final provider = context.read<SexualEventsProvider>();
    final myself = provider.state.myself;
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
    final provider = context.read<SexualEventsProvider>();
    final myself = provider.state.myself;

    final EventActivity activity = _workingEvent.activities[activityIndex];
    final existingParticipantIds = activity.participants
        .map((p) => p.participant.reference)
        .toSet();

    final result = await PersonPickerDialog.show(
      context: context,
      availablePersons: _availablePersons,
      existingParticipantIds: existingParticipantIds,
      myself: myself,
      onAddNew: () {},
    );

    if (result == 'ADD_NEW') {
      final newPerson = await Navigator.push<Person>(
        context,
        MaterialPageRoute(builder: (context) => const PersonEditorPage()),
      );

      if (newPerson != null) {
        final provider = context.read<SexualEventsProvider>();
        final persons = await provider.getAllPersons();
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
    final provider = context.read<SexualEventsProvider>();
    final myself = provider.state.myself;

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
        _workingEvent = _workingEvent.copyWith(
          location: Reference(reference: loc.id, resourceType: 'Location'),
        );
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
    final provider = context.read<SexualEventsProvider>();

    setState(() {
      _showLocationMap = true;
      _isFetchingLocation = true;
    });

    // If the current working event has a saved location and the provider has
    // resolved it for this same event, initialize from that resolved Location.
    if (_workingEvent.location != null &&
        provider.state.selectedEvent?.id == _workingEvent.id &&
        provider.state.selectedEventLocation != null) {
      final resolved = provider.state.selectedEventLocation!;
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
    final provider = context.read<SexualEventsProvider>();

    // If the working event has a persisted Location reference, call provider
    // to remove it from the stored event (this persists the change).
    if (_workingEvent.location != null) {
      await provider.removeLocationFromSelectedEvent();

      // After provider operation, sync local working event to provider state if possible.
      final selected = provider.state.selectedEvent;
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
    final provider = context.read<SexualEventsProvider>();
    final myself = provider.state.myself;
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
    final provider = context.watch<SexualEventsProvider>();

    // Debug logging to help trace why UI thinks a location is attached.
    // This prints the working event's location reference, any editor-pending
    // coordinates, and the provider's selectedEvent / selectedEventLocation
    // so we can detect stale provider state vs. actual working-event state.
    debugPrint(
      'EventEditor: buildLocationSection -> '
      'workingEvent.id=${_workingEvent.id} '
      'workingEvent.location=${_workingEvent.location} '
      'pendingLat=${_pendingLocationLat?.toStringAsFixed(6)} '
      'pendingLng=${_pendingLocationLng?.toStringAsFixed(6)} '
      'provider.selectedEvent=${provider.state.selectedEvent?.id} '
      'provider.resolvedLocation=${provider.state.selectedEventLocation}',
    );

    // Determine attached state from the editor's working event and pending coords.
    // We intentionally DO NOT rely solely on provider.state.selectedEventLocation
    // because provider state may reflect a previously-selected event.
    final hasAttached =
        _workingEvent.location != null ||
        (_pendingLocationLat != null && _pendingLocationLng != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Tooltip(
              message: 'Tap to request location permission and center map',
              child: IconButton(
                icon: const Icon(Icons.gps_fixed),
                tooltip: 'Use current location',
                onPressed: _openLocationMap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_showLocationMap)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.primaryContainer,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasAttached
                        ? 'A location is attached to this event.'
                        : 'Press the GPS icon or tap Open to center the map on your current location (will fallback to a default if unavailable).',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _openLocationMap,
                  child: const Text('Open'),
                ),
                if (hasAttached) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _removeAttachedLocation,
                    child: const Text('Remove'),
                  ),
                ],
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      fm.FlutterMap(
                        mapController: _mapController,
                        options: fm.MapOptions(
                          initialCenter: ll.LatLng(_pinLatitude, _pinLongitude),
                          initialZoom: _mapZoom,
                          onPositionChanged: (pos, hasGesture) {
                            final center = pos?.center;
                            if (center != null) {
                              setState(() {
                                _pinLatitude = center.latitude;
                                _pinLongitude = center.longitude;
                                _pendingLocationLat = _pinLatitude;
                                _pendingLocationLng = _pinLongitude;
                              });
                            }
                          },
                        ),
                        children: [
                          fm.TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            tileProvider: fm.NetworkTileProvider(
                              headers: {
                                // Keep a placeholder UA; adjust for production per OSM policy.
                                'User-Agent':
                                    'indulge/0.0.2-beta (you@yourdomain.com)',
                              },
                            ),
                          ),
                          fm.RichAttributionWidget(
                            attributions: [
                              fm.TextSourceAttribution(
                                'OpenStreetMap contributors',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Positioned(
                        top: (220 / 2) - 24,
                        child: Icon(
                          Icons.location_pin,
                          size: 48,
                          color: Colors.red,
                        ),
                      ),
                      if (_isFetchingLocation)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black45,
                            child: const Center(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox.shrink(),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      // Close the map view without persisting a change.
                      setState(() {
                        _showLocationMap = false;
                      });
                    },
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
      ],
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
