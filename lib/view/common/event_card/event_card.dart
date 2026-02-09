import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/event_editor/event_editor.dart';
import 'package:provider/provider.dart';

class EventCard extends StatefulWidget {
  final SexualEvent event;
  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  @override
  Widget build(BuildContext context) {
    SexualEventsProvider provider = context.watch<SexualEventsProvider>();
    final List<SexualActivity> activities = widget.event.activities;
    final EventState eventState = provider.state;
    final Future<List<Person>> participants = provider.getPersonsForEvent(
      widget.event.id,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: FutureBuilder<List<Person>>(
        future: participants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final persons = snapshot.data ?? [];
            return _eventCard(context, persons, eventState, activities);
          }
        },
      ),
    );
  }

  Widget _eventCard(
    BuildContext context,
    List<Person> persons,
    EventState eventState,
    List<SexualActivity> activities,
  ) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.local_fire_department,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        _getEventTitleString(persons),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: _buildCompactPreview(activities, eventState, persons),
      children: [
        if (activities.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No activities in this event',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          _buildDetailedActivitiesList(activities, persons, eventState),
        const Divider(),
        _buildButtonRow(context),
      ],
    );
  }

  Widget _buildCompactPreview(
    List<SexualActivity> activities,
    EventState eventState,
    List<Person> persons,
  ) {
    if (activities.isEmpty) {
      return const Text('No activities');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: activities.map((activity) {
          final activityType =
              eventState.sexualActivityTypes?[activity.type.reference];
          final emoji = activityType?.displayCharacter ?? '❔';
          final name = activityType?.name ?? 'Unknown';

          return Chip(
            avatar: Text(emoji, style: const TextStyle(fontSize: 16)),
            label: Text(name, style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailedActivitiesList(
    List<SexualActivity> activities,
    List<Person> persons,
    EventState eventState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activities.map((activity) {
        return _buildActivityCard(activity, persons, eventState);
      }).toList(),
    );
  }

  Widget _buildActivityCard(
    SexualActivity activity,
    List<Person> persons,
    EventState eventState,
  ) {
    final activityType =
        eventState.sexualActivityTypes?[activity.type.reference];
    final emoji = activityType?.displayCharacter ?? '❔';
    final name = activityType?.name ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity header
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${activity.participants.length} ${activity.participants.length == 1 ? 'participant' : 'participants'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Participants breakdown
            if (activity.participants.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _buildParticipantsBreakdown(activity, persons, eventState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsBreakdown(
    SexualActivity activity,
    List<Person> persons,
    EventState eventState,
  ) {
    // Get the person IDs who actually participated in this activity
    final activityParticipantIds = activity.participants
        .map((p) => p.participant.reference)
        .toSet();

    // Filter persons to only those in this activity
    final activityPersons = persons
        .where((person) => activityParticipantIds.contains(person.id))
        .toList();

    // Group participants by property with counts
    final Map<String, Map<Person, int>> propertyGroups = {};

    for (var participant in activity.participants) {
      final person = activityPersons.firstWhere(
        (p) => p.id == participant.participant.reference,
        orElse: () => Person(
          date: DateTime.now(),
          name: const Name(given: 'Unknown'),
        ),
      );

      if (participant.propertyCounts.isEmpty) {
        // Group under "no properties"
        propertyGroups.putIfAbsent('_no_property', () => {});
        propertyGroups['_no_property']![person] = 1;
      } else {
        for (var propertyCount in participant.propertyCounts) {
          final propertyId = propertyCount.propertyReference.reference;
          propertyGroups.putIfAbsent(propertyId, () => {});
          propertyGroups[propertyId]![person] = propertyCount.count;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: propertyGroups.entries.map((entry) {
        if (entry.key == '_no_property') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.value.entries.map((personEntry) {
                final person = personEntry.key;
                final isSelf = person.isSelf;
                return Chip(
                  avatar: isSelf
                      ? const Icon(
                          Icons.account_circle,
                          size: 16,
                          color: Colors.blue,
                        )
                      : null,
                  label: Text(
                    person.name.nickname ?? person.name.given ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelf ? FontWeight.bold : null,
                    ),
                  ),
                  backgroundColor: isSelf ? Colors.blue.shade50 : null,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          );
        } else {
          final property = eventState.sexualActivityTypeProperties?[entry.key];
          final propertyEmoji = property?.displayCharacter ?? '❔';
          final propertyName = property?.name ?? 'Unknown';
          final isRisky = property?.isRisky ?? false;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(propertyEmoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      propertyName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isRisky) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.warning, size: 14, color: Colors.orange),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 24.0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: entry.value.entries.map((personEntry) {
                      final person = personEntry.key;
                      final count = personEntry.value;
                      final isSelf = person.isSelf;
                      return Chip(
                        avatar: isSelf
                            ? const Icon(
                                Icons.account_circle,
                                size: 16,
                                color: Colors.blue,
                              )
                            : null,
                        label: Text(
                          '${person.name.nickname ?? person.name.given ?? 'Unknown'} ($count)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelf ? FontWeight.bold : null,
                          ),
                        ),
                        backgroundColor: isSelf ? Colors.blue.shade50 : null,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildButtonRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventEditorPage(event: widget.event),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text(
            'Are you sure you want to delete this event? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        final provider = context.read<SexualEventsProvider>();
        await provider.deleteEvent(widget.event.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting event: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getEventTitleString(List<Person> persons) {
    if (persons.isEmpty) {
      return 'Event (no participants)';
    }
    return 'Event with ${persons.length} ${persons.length == 1 ? 'person' : 'people'}';
  }
}
