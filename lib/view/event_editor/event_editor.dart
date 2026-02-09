import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/person_editor/person_editor_page.dart';
import 'package:uuid/uuid.dart';

class EventEditorPage extends StatefulWidget {
  final SexualEvent? event;

  const EventEditorPage({super.key, this.event});

  @override
  State<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  late SexualEvent _workingEvent;
  bool _isLoading = true;
  List<Person> _availablePersons = [];
  Map<String, SexualActivityType> _availableActivityTypes = {};
  Map<String, SexualActivityTypeProperty> _availableProperties = {};

  @override
  void initState() {
    super.initState();
    _initializeEvent();
  }

  Future<void> _initializeEvent() async {
    final provider = context.read<SexualEventsProvider>();
    await provider.ready;

    final persons = await provider.getAllPersons();
    final activityTypes = provider.state.sexualActivityTypes ?? {};
    final properties = provider.state.sexualActivityTypeProperties ?? {};

    setState(() {
      _availablePersons = persons;
      _availableActivityTypes = activityTypes;
      _availableProperties = properties;

      if (widget.event != null) {
        // Editing existing event
        _workingEvent = widget.event!;
      } else {
        // Creating new event with explicit UUID
        _workingEvent = SexualEvent(
          id: const Uuid().v4(),
          date: DateTime.now(),
          activities: [],
        );
      }
      _isLoading = false;
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

  void _addActivity(SexualActivityType activityType) {
    final newActivity = SexualActivity(
      type: Reference(
        reference: activityType.id,
        resourceType: 'SexualActivityType',
      ),
      participants: [],
    );

    setState(() {
      _workingEvent = _workingEvent.copyWith(
        activities: [..._workingEvent.activities, newActivity],
      );
    });
  }

  void _removeActivity(int activityIndex) {
    final updatedActivities = List<SexualActivity>.from(
      _workingEvent.activities,
    );
    updatedActivities.removeAt(activityIndex);

    setState(() {
      _workingEvent = _workingEvent.copyWith(activities: updatedActivities);
    });
  }

  void _addParticipant(int activityIndex, Person person) {
    final participant = SexualActivityParticipant(
      participant: Reference(reference: person.id, resourceType: 'Person'),
      propertyReferences: [],
    );

    final updatedActivities = List<SexualActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    updatedActivities[activityIndex] = activity.copyWith(
      participants: [...activity.participants, participant],
    );

    setState(() {
      _workingEvent = _workingEvent.copyWith(activities: updatedActivities);
    });
  }

  void _removeParticipant(int activityIndex, int participantIndex) {
    final updatedActivities = List<SexualActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    final updatedParticipants = List<SexualActivityParticipant>.from(
      activity.participants,
    );
    updatedParticipants.removeAt(participantIndex);

    updatedActivities[activityIndex] = activity.copyWith(
      participants: updatedParticipants,
    );

    setState(() {
      _workingEvent = _workingEvent.copyWith(activities: updatedActivities);
    });
  }

  void _toggleParticipantForProperty(
    int activityIndex,
    String propertyId,
    String participantId,
  ) {
    final updatedActivities = List<SexualActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    final updatedParticipants = <SexualActivityParticipant>[];

    for (var participant in activity.participants) {
      if (participant.participant.reference != participantId) {
        updatedParticipants.add(participant);
        continue;
      }

      // This is the participant we're updating
      final currentPropertyIds = participant.propertyReferences
          .map((ref) => ref.reference)
          .toSet();

      List<Reference> newPropertyRefs;
      if (currentPropertyIds.contains(propertyId)) {
        // Remove property
        newPropertyRefs = participant.propertyReferences
            .where((ref) => ref.reference != propertyId)
            .toList();
      } else {
        // Add property
        newPropertyRefs = [
          ...participant.propertyReferences,
          Reference(
            reference: propertyId,
            resourceType: 'SexualActivityTypeProperty',
          ),
        ];
      }

      updatedParticipants.add(
        participant.copyWith(propertyReferences: newPropertyRefs),
      );
    }

    updatedActivities[activityIndex] = activity.copyWith(
      participants: updatedParticipants,
    );

    setState(() {
      _workingEvent = _workingEvent.copyWith(activities: updatedActivities);
    });
  }

  Future<void> _showActivityPicker() async {
    final activityType = await showDialog<SexualActivityType>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Activity Type'),
          children: _availableActivityTypes.values.map((type) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, type),
              child: Row(
                children: [
                  Text(
                    type.displayCharacter ?? '❔',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      type.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );

    if (activityType != null) {
      _addActivity(activityType);
    }
  }

  Future<void> _showPersonPicker(int activityIndex) async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Person'),
          children: [
            // Anonymous participant option first
            SimpleDialogOption(
              onPressed: () {
                // Find the anonymous person
                final anonymous = _availablePersons.firstWhere(
                  (p) => p.id == 'anonymous',
                  orElse: () => _availablePersons.first,
                );
                Navigator.pop(context, anonymous);
              },
              child: const Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.grey),
                  SizedBox(width: 12),
                  Text(
                    'Anonymous',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ..._availablePersons
                .where((person) => person.id != 'anonymous')
                .map((person) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, person),
                    child: Text(
                      person.name.nickname ?? person.name.given ?? 'Unknown',
                    ),
                  );
                })
                .toList(),
            const Divider(),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'CREATE_NEW'),
              child: const Row(
                children: [
                  Icon(Icons.person_add, color: Colors.blue),
                  SizedBox(width: 12),
                  Text(
                    'Create New Person',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (result == 'CREATE_NEW') {
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
    // Must have at least one activity
    if (_workingEvent.activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one activity'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // Each activity must have at least one participant
    for (var i = 0; i < _workingEvent.activities.length; i++) {
      if (_workingEvent.activities[i].participants.isEmpty) {
        final activityType =
            _availableActivityTypes[_workingEvent.activities[i].type.reference];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Activity "${activityType?.name ?? 'Unknown'}" must have at least one participant',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }

    return true;
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
                ],
              ),
            ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_workingEvent.date.year}-${_workingEvent.date.month.toString().padLeft(2, '0')}-${_workingEvent.date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_workingEvent.date.hour.toString().padLeft(2, '0')}:${_workingEvent.date.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _showActivityPicker,
              icon: const Icon(Icons.add),
              label: const Text('Add Activity'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_workingEvent.activities.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No activities added yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._workingEvent.activities.asMap().entries.map((entry) {
            return _buildActivityCard(entry.key, entry.value);
          }).toList(),
      ],
    );
  }

  Widget _buildActivityCard(int activityIndex, SexualActivity activity) {
    final activityType = _availableActivityTypes[activity.type.reference];
    final emoji = activityType?.displayCharacter ?? '❔';
    final name = activityType?.name ?? 'Unknown';

    // Get available properties for this activity type
    final availableProperties = <SexualActivityTypeProperty>[];
    if (activityType != null) {
      for (var propRef in activityType.properties) {
        final property = _availableProperties[propRef.reference];
        if (property != null) {
          availableProperties.add(property);
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity header
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeActivity(activityIndex),
                  tooltip: 'Remove activity',
                ),
              ],
            ),
            const Divider(),
            // Participants section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participants',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _showPersonPicker(activityIndex),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (activity.participants.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'No participants added',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              _buildParticipantsList(activityIndex, activity),
            // Properties section
            if (activity.participants.isNotEmpty &&
                availableProperties.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Properties',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...availableProperties.map((property) {
                return _buildPropertyRow(activityIndex, activity, property);
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList(int activityIndex, SexualActivity activity) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activity.participants.asMap().entries.map((entry) {
        final participantIndex = entry.key;
        final participant = entry.value;
        final person = _availablePersons.firstWhere(
          (p) => p.id == participant.participant.reference,
          orElse: () => Person(
            date: DateTime.now(),
            name: const Name(given: 'Unknown'),
          ),
        );
        final personName =
            person.name.nickname ?? person.name.given ?? 'Unknown';

        return Chip(
          avatar: const Icon(Icons.person, size: 18),
          label: Text(personName),
          onDeleted: () => _removeParticipant(activityIndex, participantIndex),
          deleteIcon: const Icon(Icons.close, size: 18),
        );
      }).toList(),
    );
  }

  Widget _buildPropertyRow(
    int activityIndex,
    SexualActivity activity,
    SexualActivityTypeProperty property,
  ) {
    // Get participants who have this property
    final participantsWithProperty = <String>[];
    for (var participant in activity.participants) {
      final hasProperty = participant.propertyReferences.any(
        (ref) => ref.reference == property.id,
      );
      if (hasProperty) {
        participantsWithProperty.add(participant.participant.reference);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: property.isRisky ? Colors.orange.shade50 : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  property.displayCharacter,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    property.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (property.isRisky)
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activity.participants.map((participant) {
                final person = _availablePersons.firstWhere(
                  (p) => p.id == participant.participant.reference,
                  orElse: () => Person(
                    date: DateTime.now(),
                    name: const Name(given: 'Unknown'),
                  ),
                );
                final personName =
                    person.name.nickname ?? person.name.given ?? 'Unknown';
                final isSelected = participantsWithProperty.contains(person.id);

                return FilterChip(
                  selected: isSelected,
                  label: Text(personName),
                  onSelected: (bool selected) {
                    _toggleParticipantForProperty(
                      activityIndex,
                      property.id,
                      person.id,
                    );
                  },
                  selectedColor: Colors.white,
                  checkmarkColor: property.isRisky
                      ? Colors.orange
                      : Colors.blue,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
