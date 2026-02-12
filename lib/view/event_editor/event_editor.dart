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

  @override
  void initState() {
    super.initState();
    _initializeEvent();
  }

  Future<void> _initializeEvent() async {
    final provider = context.read<SexualEventsProvider>();
    await provider.ready;

    final persons = await provider.getAllPersons();
    final activityCategories = provider.state.sexualActivityCategories ?? {};
    final activities = provider.state.sexualActivities ?? {};

    setState(() {
      _availablePersons = persons;
      _availableActivityCategories = activityCategories;
      _availableActivities = activities;

      if (widget.event != null) {
        // Editing existing event
        _workingEvent = widget.event!;
      } else {
        // Creating new event with explicit UUID
        _workingEvent = SexualEvent(
          id: const Uuid().v4(),
          date: widget.initialDate ?? DateTime.now(),
          activities: [],
        );
      }
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
    // Pick date first
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _workingEvent.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    // Then pick time
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
      // If time was cancelled, just use the picked date with current time
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
      // Auto-expand the newly added activity (last index)
      _expandedActivities.add(_workingEvent.activities.length - 1);
    });
  }

  void _removeActivity(int activityIndex) {
    setState(() {
      _workingEvent = removeActivity(_workingEvent, activityIndex);
      // Remove the deleted activity from expanded set and adjust indices
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
    // Use the helper; it returns the unchanged event if the participant
    // already exists for that activity.
    final updatedEvent = addParticipant(_workingEvent, activityIndex, person);
    if (identical(updatedEvent, _workingEvent)) {
      // No-op: participant already present
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

    // Get all participants for this activity
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
      // Navigate to person editor and wait for result
      final newPerson = await Navigator.push<Person>(
        context,
        MaterialPageRoute(builder: (context) => const PersonEditorPage()),
      );

      if (newPerson != null) {
        // Refresh available persons list
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
                ],
              ),
            ),
    );
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
      // Wire participant removal from chip delete back to the page state.
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
}
