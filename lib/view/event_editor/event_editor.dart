import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/person_editor/person_editor_page.dart';
import 'package:uuid/uuid.dart';

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
  Map<String, SexualActivityType> _availableActivityTypes = {};
  Map<String, SexualActivityTypeProperty> _availableProperties = {};
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
          date: widget.initialDate ?? DateTime.now(),
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
      // Auto-expand the newly added activity
      _expandedActivities.add(_workingEvent.activities.length);
    });
  }

  void _removeActivity(int activityIndex) {
    final updatedActivities = List<SexualActivity>.from(
      _workingEvent.activities,
    );
    updatedActivities.removeAt(activityIndex);

    setState(() {
      _workingEvent = _workingEvent.copyWith(activities: updatedActivities);
      // Remove the deleted activity from expanded set
      _expandedActivities.remove(activityIndex);
      // Adjust indices for activities after the removed one
      final adjustedExpanded = <int>{};
      for (var idx in _expandedActivities) {
        if (idx > activityIndex) {
          adjustedExpanded.add(idx - 1);
        } else {
          adjustedExpanded.add(idx);
        }
      }
      _expandedActivities.clear();
      _expandedActivities.addAll(adjustedExpanded);
    });
  }

  void _addParticipant(int activityIndex, Person person) {
    final participant = SexualActivityParticipant(
      participant: Reference(reference: person.id, resourceType: 'Person'),
      propertyCounts: [],
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

  void _toggleMyselfForProperty(int activityIndex, String propertyId) {
    final provider = context.read<SexualEventsProvider>();
    final myself = provider.state.myself;
    if (myself == null) return;

    setState(() {
      final updatedActivities = List<SexualActivity>.from(
        _workingEvent.activities,
      );
      final activity = updatedActivities[activityIndex];

      // Find or create "Me" participant
      final meParticipantIndex = activity.participants.indexWhere(
        (p) => p.participant.reference == myself.id,
      );

      List<SexualActivityParticipant> updatedParticipants;

      if (meParticipantIndex == -1) {
        // Create "Me" participant with this property
        final newParticipant = SexualActivityParticipant(
          participant: Reference(reference: myself.id, resourceType: 'Person'),
          propertyCounts: [
            PropertyCount(
              propertyReference: Reference(
                reference: propertyId,
                resourceType: 'SexualActivityTypeProperty',
              ),
              count: 1,
            ),
          ],
        );
        updatedParticipants = [...activity.participants, newParticipant];
      } else {
        // Toggle property for existing "Me" participant
        final meParticipant = activity.participants[meParticipantIndex];
        final hasProperty = meParticipant.propertyCounts.any(
          (pc) => pc.propertyReference.reference == propertyId,
        );

        List<PropertyCount> updatedProperties;
        if (hasProperty) {
          // Remove this property
          updatedProperties = meParticipant.propertyCounts
              .where((pc) => pc.propertyReference.reference != propertyId)
              .toList();
        } else {
          // Add this property
          updatedProperties = [
            ...meParticipant.propertyCounts,
            PropertyCount(
              propertyReference: Reference(
                reference: propertyId,
                resourceType: 'SexualActivityTypeProperty',
              ),
              count: 1,
            ),
          ];
        }

        updatedParticipants = List<SexualActivityParticipant>.from(
          activity.participants,
        );

        if (updatedProperties.isEmpty) {
          // Remove "Me" participant if no properties
          updatedParticipants.removeAt(meParticipantIndex);
        } else {
          // Update "Me" participant with new properties
          updatedParticipants[meParticipantIndex] = meParticipant.copyWith(
            propertyCounts: updatedProperties,
          );
        }
      }

      updatedActivities[activityIndex] = activity.copyWith(
        participants: updatedParticipants,
      );

      _workingEvent = _workingEvent.copyWith(activities: updatedActivities);
    });
  }

  void _toggleParticipantForProperty(
    int activityIndex,
    String propertyId,
    String personId,
  ) {
    final updatedActivities = List<SexualActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    final updatedParticipants = <SexualActivityParticipant>[];

    for (var participant in activity.participants) {
      if (participant.participant.reference != personId) {
        updatedParticipants.add(participant);
        continue;
      }

      // This is the participant we're updating
      final currentPropertyIds = participant.propertyCounts
          .map((pc) => pc.propertyReference.reference)
          .toSet();

      List<PropertyCount> newPropertyCounts;
      if (currentPropertyIds.contains(propertyId)) {
        // Remove property
        newPropertyCounts = participant.propertyCounts
            .where((pc) => pc.propertyReference.reference != propertyId)
            .toList();
      } else {
        // Add property
        newPropertyCounts = [
          ...participant.propertyCounts,
          PropertyCount(
            propertyReference: Reference(
              reference: propertyId,
              resourceType: 'SexualActivityTypeProperty',
            ),
            count: 1,
          ),
        ];
      }

      updatedParticipants.add(
        participant.copyWith(propertyCounts: newPropertyCounts),
      );
    }

    updatedActivities[activityIndex] = activity.copyWith(
      participants: updatedParticipants,
    );

    setState(() {
      _workingEvent = _workingEvent.copyWith(activities: updatedActivities);
    });
  }

  void _incrementPropertyCount(
    int activityIndex,
    String propertyId,
    String personId,
  ) {
    final updatedActivities = List<SexualActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    final updatedParticipants = <SexualActivityParticipant>[];

    for (var participant in activity.participants) {
      if (participant.participant.reference != personId) {
        updatedParticipants.add(participant);
        continue;
      }

      // Find the property count to increment
      final updatedPropertyCounts = participant.propertyCounts.map((pc) {
        if (pc.propertyReference.reference == propertyId) {
          return pc.copyWith(count: pc.count + 1);
        }
        return pc;
      }).toList();

      updatedParticipants.add(
        participant.copyWith(propertyCounts: updatedPropertyCounts),
      );
    }

    updatedActivities[activityIndex] = activity.copyWith(
      participants: updatedParticipants,
    );

    setState(() {
      _workingEvent = _workingEvent.copyWith(activities: updatedActivities);
    });
  }

  void _decrementPropertyCount(
    int activityIndex,
    String propertyId,
    String personId,
  ) {
    final updatedActivities = List<SexualActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    final updatedParticipants = <SexualActivityParticipant>[];

    for (var participant in activity.participants) {
      if (participant.participant.reference != personId) {
        updatedParticipants.add(participant);
        continue;
      }

      // Find the property count to decrement
      final updatedPropertyCounts = <PropertyCount>[];
      for (var pc in participant.propertyCounts) {
        if (pc.propertyReference.reference == propertyId) {
          if (pc.count > 1) {
            // Decrement count
            updatedPropertyCounts.add(pc.copyWith(count: pc.count - 1));
          }
          // If count is 1, don't add it (remove the property)
        } else {
          updatedPropertyCounts.add(pc);
        }
      }

      updatedParticipants.add(
        participant.copyWith(propertyCounts: updatedPropertyCounts),
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
    final provider = context.read<SexualEventsProvider>();
    final myself = provider.state.myself;

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
                .where((person) {
                  // Filter out anonymous
                  if (person.id == 'anonymous') return false;

                  // Never show "Me" in picker - only add via property checkboxes
                  if (myself != null && person.id == myself.id) {
                    return false;
                  }

                  // Show all other persons
                  return true;
                })
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

    final provider = context.read<SexualEventsProvider>();
    final myself = provider.state.myself;

    // Each activity must have at least one participant (can be "Me" or others)
    for (var i = 0; i < _workingEvent.activities.length; i++) {
      final activity = _workingEvent.activities[i];
      final activityType = _availableActivityTypes[activity.type.reference];

      // Check if activity requires a partner
      if (activityType?.requiresPartner == true) {
        // For activities requiring a partner, must have at least one non-self participant
        final nonSelfCount = activity.participants.where((p) {
          return myself == null || p.participant.reference != myself.id;
        }).length;

        if (nonSelfCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Activity "${activityType?.name ?? 'Unknown'}" requires at least one partner',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }
      } else {
        // For solo-capable activities, must have at least one participant (including "Me")
        if (activity.participants.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Activity "${activityType?.name ?? 'Unknown'}" must have at least one participant (you or someone else)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }
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
    final isExpanded = _expandedActivities.contains(activityIndex);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity header (always visible, tappable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedActivities.remove(activityIndex);
                  } else {
                    _expandedActivities.add(activityIndex);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (activityType?.requiresPartner == true)
                            const Text(
                              'Requires partner',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeActivity(activityIndex),
                      tooltip: 'Remove activity',
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Collapsible content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Participants section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Participants',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activityType?.requiresPartner == true
                                  ? 'Add at least one partner to continue'
                                  : 'Add other participants, or toggle properties below to track your own participation',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildParticipantsList(activityIndex, activity),
                  // Properties section (show even with no participants for solo-capable activities)
                  if (availableProperties.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Properties',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...availableProperties.map((property) {
                      return _buildPropertyRow(
                        activityIndex,
                        activity,
                        property,
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantsList(int activityIndex, SexualActivity activity) {
    final provider = context.watch<SexualEventsProvider>();
    final myself = provider.state.myself;

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
        final isSelf = myself != null && person.id == myself.id;

        return Chip(
          avatar: Icon(
            isSelf ? Icons.account_circle : Icons.person,
            size: 18,
            color: isSelf ? Colors.blue : null,
          ),
          label: Text(
            personName,
            style: TextStyle(
              fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: isSelf ? Colors.blue.shade50 : null,
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
    final provider = context.read<SexualEventsProvider>();
    final myself = provider.state.myself;
    final activityType = _availableActivityTypes[activity.type.reference];

    // Use the current working activity state (not from provider)
    final currentActivity = _workingEvent.activities[activityIndex];

    // Check if "Me" has this property
    final meParticipant = currentActivity.participants.firstWhere(
      (p) => myself != null && p.participant.reference == myself.id,
      orElse: () => SexualActivityParticipant(
        participant: Reference(reference: '', resourceType: 'Person'),
        propertyCounts: [],
      ),
    );
    final mePropertyCount = meParticipant.propertyCounts.firstWhere(
      (pc) => pc.propertyReference.reference == property.id,
      orElse: () => PropertyCount(
        propertyReference: Reference(
          reference: '',
          resourceType: 'SexualActivityTypeProperty',
        ),
        count: 0,
      ),
    );
    final meHasProperty = mePropertyCount.count > 0;

    // Determine if "Me" checkbox should be enabled
    final activityRequiresPartner = activityType?.requiresPartner ?? false;
    final propertyRequiresPartner = property.requiresPartner;
    final meCheckboxEnabled =
        !activityRequiresPartner && !propertyRequiresPartner;

    // Get non-self participants who have this property
    final participantsWithProperty = <String>[];
    for (var participant in currentActivity.participants) {
      if (myself != null && participant.participant.reference == myself.id) {
        continue; // Skip "Me"
      }
      final propertyCount = participant.propertyCounts.firstWhere(
        (pc) => pc.propertyReference.reference == property.id,
        orElse: () => PropertyCount(
          propertyReference: Reference(
            reference: '',
            resourceType: 'SexualActivityTypeProperty',
          ),
          count: 0,
        ),
      );
      if (propertyCount.count > 0) {
        participantsWithProperty.add(participant.participant.reference);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: property.isRisky ? Colors.orange.shade50 : Colors.grey.shade50,
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
              children: [
                // "Me" checkbox (only show if activity doesn't require partner)
                if (myself != null && !activityRequiresPartner)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilterChip(
                        selected: meHasProperty,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_circle, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              meHasProperty
                                  ? 'Me (${mePropertyCount.count})'
                                  : 'Me',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (propertyRequiresPartner) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.lock,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ],
                        ),
                        onSelected: meCheckboxEnabled
                            ? (bool selected) {
                                _toggleMyselfForProperty(
                                  activityIndex,
                                  property.id,
                                );
                              }
                            : null,
                        selectedColor: Colors.blue.shade100,
                        backgroundColor: meCheckboxEnabled
                            ? null
                            : Colors.grey.shade300,
                        checkmarkColor: Colors.blue,
                      ),
                      if (meHasProperty && meCheckboxEnabled) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _decrementPropertyCount(
                            activityIndex,
                            property.id,
                            myself.id,
                          ),
                          tooltip: 'Decrease count',
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _incrementPropertyCount(
                            activityIndex,
                            property.id,
                            myself.id,
                          ),
                          tooltip: 'Increase count',
                        ),
                      ],
                    ],
                  ),
                // Other participants
                ...currentActivity.participants
                    .where((p) {
                      return myself == null ||
                          p.participant.reference != myself.id;
                    })
                    .map((participant) {
                      final person = _availablePersons.firstWhere(
                        (p) => p.id == participant.participant.reference,
                        orElse: () => Person(
                          date: DateTime.now(),
                          name: const Name(given: 'Unknown'),
                        ),
                      );
                      final personName =
                          person.name.nickname ??
                          person.name.given ??
                          'Unknown';
                      final isSelected = participantsWithProperty.contains(
                        person.id,
                      );
                      final propertyCount = participant.propertyCounts
                          .firstWhere(
                            (pc) =>
                                pc.propertyReference.reference == property.id,
                            orElse: () => PropertyCount(
                              propertyReference: Reference(
                                reference: '',
                                resourceType: 'SexualActivityTypeProperty',
                              ),
                              count: 0,
                            ),
                          );

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilterChip(
                            selected: isSelected,
                            label: Text(
                              isSelected
                                  ? '$personName (${propertyCount.count})'
                                  : personName,
                            ),
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
                                : Colors.green,
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _decrementPropertyCount(
                                activityIndex,
                                property.id,
                                person.id,
                              ),
                              tooltip: 'Decrease count',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _incrementPropertyCount(
                                activityIndex,
                                property.id,
                                person.id,
                              ),
                              tooltip: 'Increase count',
                            ),
                          ],
                        ],
                      );
                    })
                    .toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
