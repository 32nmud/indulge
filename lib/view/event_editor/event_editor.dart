import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/person_editor/person_editor_page.dart';
import 'package:uuid/uuid.dart';
import 'widgets/widgets.dart';
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
    final newActivity = EventActivity(
      category: Reference(
        reference: activityCategory.id,
        resourceType: 'SexualActivityCategory',
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
    final updatedActivities = List<EventActivity>.from(
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
    final updatedActivities = List<EventActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    // Check if participant already exists in this activity
    final alreadyExists = activity.participants.any(
      (p) => p.participant.reference == person.id,
    );

    if (alreadyExists) {
      // Show a message to the user
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

    final participant = ActivityParticipant(
      participant: Reference(reference: person.id, resourceType: 'Person'),
      activityCounts: [],
    );

    updatedActivities[activityIndex] = activity.copyWith(
      participants: [...activity.participants, participant],
    );

    setState(() {
      _workingEvent = _workingEvent.copyWith(activities: updatedActivities);
    });
  }

  void _removeParticipant(int activityIndex, int participantIndex) {
    final updatedActivities = List<EventActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    final updatedParticipants = List<ActivityParticipant>.from(
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

  void _toggleMyselfForProperty(int activityIndex, String activityId) {
    final provider = context.read<SexualEventsProvider>();
    final myself = provider.state.myself;
    if (myself == null) return;

    setState(() {
      final updatedActivities = List<EventActivity>.from(
        _workingEvent.activities,
      );
      final activity = updatedActivities[activityIndex];

      // Find or create "Me" participant
      final meParticipantIndex = activity.participants.indexWhere(
        (p) => p.participant.reference == myself.id,
      );

      List<ActivityParticipant> updatedParticipants;

      if (meParticipantIndex == -1) {
        // Create "Me" participant with this activity
        final newParticipant = ActivityParticipant(
          participant: Reference(reference: myself.id, resourceType: 'Person'),
          activityCounts: [
            ActivityCount(
              activityReference: Reference(
                reference: activityId,
                resourceType: 'SexualActivity',
              ),
              count: 1,
            ),
          ],
        );
        updatedParticipants = [...activity.participants, newParticipant];
      } else {
        // Toggle activity for existing "Me" participant
        final meParticipant = activity.participants[meParticipantIndex];
        final hasActivity = meParticipant.activityCounts.any(
          (ac) => ac.activityReference.reference == activityId,
        );

        List<ActivityCount> updatedActivities;
        if (hasActivity) {
          // Remove this activity
          updatedActivities = meParticipant.activityCounts
              .where((ac) => ac.activityReference.reference != activityId)
              .toList();
        } else {
          // Add this activity
          updatedActivities = [
            ...meParticipant.activityCounts,
            ActivityCount(
              activityReference: Reference(
                reference: activityId,
                resourceType: 'SexualActivity',
              ),
              count: 1,
            ),
          ];
        }

        updatedParticipants = List<ActivityParticipant>.from(
          activity.participants,
        );

        if (updatedActivities.isEmpty) {
          // Remove "Me" participant if no activities
          updatedParticipants.removeAt(meParticipantIndex);
        } else {
          // Update "Me" participant with new activities
          updatedParticipants[meParticipantIndex] = meParticipant.copyWith(
            activityCounts: updatedActivities,
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
    String activityId,
    String personId,
  ) {
    final updatedActivities = List<EventActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    final updatedParticipants = <ActivityParticipant>[];

    for (var participant in activity.participants) {
      if (participant.participant.reference != personId) {
        updatedParticipants.add(participant);
        continue;
      }

      // This is the participant we're updating
      final currentActivityIds = participant.activityCounts
          .map((ac) => ac.activityReference.reference)
          .toSet();

      List<ActivityCount> newActivityCounts;
      if (currentActivityIds.contains(activityId)) {
        // Remove activity
        newActivityCounts = participant.activityCounts
            .where((ac) => ac.activityReference.reference != activityId)
            .toList();
      } else {
        // Add activity
        newActivityCounts = [
          ...participant.activityCounts,
          ActivityCount(
            activityReference: Reference(
              reference: activityId,
              resourceType: 'SexualActivity',
            ),
            count: 1,
          ),
        ];
      }

      updatedParticipants.add(
        participant.copyWith(activityCounts: newActivityCounts),
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
    String activityId,
    String personId,
  ) {
    final updatedActivities = List<EventActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    final updatedParticipants = <ActivityParticipant>[];

    for (var participant in activity.participants) {
      if (participant.participant.reference != personId) {
        updatedParticipants.add(participant);
        continue;
      }

      // Find the activity count to increment
      final updatedActivityCounts = participant.activityCounts.map((ac) {
        if (ac.activityReference.reference == activityId) {
          return ac.copyWith(count: ac.count + 1);
        }
        return ac;
      }).toList();

      updatedParticipants.add(
        participant.copyWith(activityCounts: updatedActivityCounts.toList()),
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
    String activityId,
    String personId,
  ) {
    final updatedActivities = List<EventActivity>.from(
      _workingEvent.activities,
    );
    final activity = updatedActivities[activityIndex];

    final updatedParticipants = <ActivityParticipant>[];

    for (var participant in activity.participants) {
      if (participant.participant.reference != personId) {
        updatedParticipants.add(participant);
        continue;
      }

      // Find the activity count to decrement or remove
      final updatedActivityCounts = <ActivityCount>[];
      for (var ac in participant.activityCounts) {
        if (ac.activityReference.reference == activityId) {
          if (ac.count > 1) {
            // Decrement count
            updatedActivityCounts.add(ac.copyWith(count: ac.count - 1));
          }
          // If count is 1, don't add it (remove the activity)
        } else {
          updatedActivityCounts.add(ac);
        }
      }

      updatedParticipants.add(
        participant.copyWith(activityCounts: updatedActivityCounts),
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
                ],
              ),
            ),
    );
  }

  Widget _buildDateTimeSection() {
    return DateTimeSection(dateTime: _workingEvent.date, onTap: _pickDateTime);
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
    final activityCategory =
        _availableActivityCategories[activity.category.reference];
    final emoji = activityCategory?.displayCharacter ?? '❔';
    final name = activityCategory?.name ?? 'Unknown';
    final isExpanded = _expandedActivities.contains(activityIndex);

    // Get available properties for this activity type
    final availableSexualActivities = <SexualActivity>[];
    if (activityCategory != null) {
      for (var activityRef in activityCategory.activities) {
        final sexualActivity = _availableActivities[activityRef.reference];
        if (sexualActivity != null) {
          availableSexualActivities.add(sexualActivity);
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
                          if (activityCategory?.requiresPartner == true)
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
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activityCategory?.requiresPartner == true
                                  ? 'Add at least one partner to continue'
                                  : 'Add other participants, or toggle properties below to track your own participation',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildParticipantSection(activityIndex, activity),
                  // Properties section (show even with no participants for solo-capable activities)
                  if (availableSexualActivities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Activities',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...availableSexualActivities.map((sexualActivity) {
                      return _buildPropertyRow(
                        activityIndex,
                        activity,
                        sexualActivity,
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantSection(int activityIndex, EventActivity activity) {
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
    EventActivity activity,
    SexualActivity sexualActivity,
  ) {
    final provider = context.read<SexualEventsProvider>();
    final myself = provider.state.myself;
    final activityCategory =
        _availableActivityCategories[activity.category.reference];

    // Use the current working activity state (not from provider)
    final currentActivity = _workingEvent.activities[activityIndex];

    // Check if "Me" has this property
    final meParticipant = currentActivity.participants.firstWhere(
      (p) => myself != null && p.participant.reference == myself.id,
      orElse: () => ActivityParticipant(
        participant: Reference(reference: '', resourceType: 'Person'),
        activityCounts: [],
      ),
    );
    final meActivityCount = meParticipant.activityCounts.firstWhere(
      (ac) => ac.activityReference.reference == sexualActivity.id,
      orElse: () => ActivityCount(
        activityReference: Reference(
          reference: '',
          resourceType: 'SexualActivity',
        ),
        count: 0,
      ),
    );
    final meHasProperty = meActivityCount.count > 0;

    // Determine if "Me" checkbox should be enabled
    final activityRequiresPartner = activityCategory?.requiresPartner ?? false;
    final propertyRequiresPartner = sexualActivity.requiresPartner;
    final meCheckboxEnabled =
        !activityRequiresPartner && !propertyRequiresPartner;

    // Get non-self participants who have this property
    final participantsWithProperty = <String>[];
    for (var participant in currentActivity.participants) {
      if (myself != null && participant.participant.reference == myself.id) {
        continue; // Skip "Me"
      }
      final activityCount = participant.activityCounts.firstWhere(
        (ac) => ac.activityReference.reference == sexualActivity.id,
        orElse: () => ActivityCount(
          activityReference: Reference(
            reference: '',
            resourceType: 'SexualActivity',
          ),
          count: 0,
        ),
      );
      if (activityCount.count > 0) {
        participantsWithProperty.add(participant.participant.reference);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: sexualActivity.isRisky
          ? Theme.of(context).colorScheme.tertiaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  sexualActivity.displayCharacter,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sexualActivity.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                                  ? 'Me (${meActivityCount.count})'
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                        onSelected: meCheckboxEnabled
                            ? (bool selected) {
                                _toggleMyselfForProperty(
                                  activityIndex,
                                  sexualActivity.id,
                                );
                              }
                            : null,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        backgroundColor: meCheckboxEnabled
                            ? null
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        checkmarkColor: Theme.of(context).colorScheme.primary,
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
                            sexualActivity.id,
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
                            sexualActivity.id,
                            myself.id,
                          ),
                          tooltip: 'Increase count',
                        ),
                      ],
                    ],
                  ),
                // Other participants
                ..._availablePersons
                    .where((person) {
                      return myself == null || person.id != myself.id;
                    })
                    .map((person) {
                      final personName =
                          person.name.nickname ??
                          person.name.given ??
                          'Unknown';
                      final isSelected = participantsWithProperty.contains(
                        person.id,
                      );
                      final participant = currentActivity.participants
                          .firstWhere(
                            (p) => p.participant.reference == person.id,
                            orElse: () => ActivityParticipant(
                              participant: Reference(
                                reference: '',
                                resourceType: 'Person',
                              ),
                              activityCounts: [],
                            ),
                          );
                      final activityCount = participant.activityCounts
                          .firstWhere(
                            (ac) =>
                                ac.activityReference.reference ==
                                sexualActivity.id,
                            orElse: () => ActivityCount(
                              activityReference: Reference(
                                reference: '',
                                resourceType: 'SexualActivity',
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
                                  ? '$personName (${activityCount.count})'
                                  : personName,
                            ),
                            onSelected: (bool selected) {
                              _toggleParticipantForProperty(
                                activityIndex,
                                sexualActivity.id,
                                person.id,
                              );
                            },
                            selectedColor: Colors.white,
                            checkmarkColor: sexualActivity.isRisky
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
                                sexualActivity.id,
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
                                sexualActivity.id,
                                person.id,
                              ),
                              tooltip: 'Increase count',
                            ),
                          ],
                        ],
                      );
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
