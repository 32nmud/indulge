import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/common/person_avatar.dart';
import 'package:indulge/view/event_editor/event_editor.dart';
import 'location_map.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

/// EventCard
///
/// Displays a compact/expandable card for a single `SexualEvent`. When the
/// event has a `location` embedded, the expanded card shows a non-interactive
/// map preview (tiles are rendered, but the preview ignores user gestures).
class EventCard extends StatefulWidget {
  final SexualEvent event;
  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late final fm.MapController _previewMapController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Controller for the small preview map (kept per-card lifetime).
    _previewMapController = fm.MapController();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SexualEventsProvider provider = context.watch<SexualEventsProvider>();
    final List<EventActivity> activities = widget.event.activities;
    final EventState eventState = provider.state;
    final Future<List<Person>> participants = provider.getPersonsForEvent(
      widget.event.id,
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<List<Person>>(
          future: participants,
          builder: (context, snapshot) {
            // Use empty participant list while loading to keep UI stable.
            final persons = snapshot.data ?? [];
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              );
            }
            return _eventCard(context, persons, eventState, activities);
          },
        ),
      ),
    );
  }

  Widget _eventCard(
    BuildContext context,
    List<Person> persons,
    EventState eventState,
    List<EventActivity> activities,
  ) {
    return InkWell(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
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

          if (widget.event.notes != null &&
              widget.event.notes!.trim().isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notes",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MarkdownBody(data: widget.event.notes!),
                  ],
                ),
              ),
            ),
          ],

          // Show an embedded, non-interactive map preview when a location exists.
          if (widget.event.location != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  // Use the shared LocationMap so the preview uses the same
                  // center-fixed pin as the editor. Keep it non-interactive.
                  child: LocationMap(
                    mapController: _previewMapController,
                    latitude: widget.event.location!.latitude,
                    longitude: widget.event.location!.longitude,
                    zoom: 13.0,
                    isFetching: false,
                    interactive: false,
                    height: 140,
                    pinSize: 28,
                    pinColor: Theme.of(context).colorScheme.primary,
                    onCenterChanged: (lat, lng) {},
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          const Divider(),
          _buildButtonRow(context),
        ],
      ),
    );
  }

  Widget _buildCompactPreview(
    List<EventActivity> activities,
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
          final activityCategory =
              eventState.sexualActivityCategories?[activity.category.reference];
          final emoji = activityCategory?.displayCharacter ?? '❔';
          final name = activityCategory?.name ?? 'Unknown';

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
    List<EventActivity> activities,
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
    EventActivity activity,
    List<Person> persons,
    EventState eventState,
  ) {
    final activityCategory =
        eventState.sexualActivityCategories?[activity.category.reference];
    final emoji = activityCategory?.displayCharacter ?? '❔';
    final name = activityCategory?.name ?? 'Unknown';

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
                        style: const TextStyle(fontSize: 12),
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
    EventActivity activity,
    List<Person> persons,
    EventState eventState,
  ) {
    final activityParticipantIds = activity.participants
        .map((p) => p.participant.reference)
        .toSet();

    final activityPersons = persons
        .where((person) => activityParticipantIds.contains(person.id))
        .toList();

    final Map<String, Map<Person, int>> propertyGroups = {};

    for (var participant in activity.participants) {
      final person = activityPersons.firstWhere(
        (p) => p.id == participant.participant.reference,
        orElse: () => Person(
          date: DateTime.now(),
          name: const Name(given: 'Unknown'),
        ),
      );

      if (participant.activityCounts.isEmpty) {
        propertyGroups.putIfAbsent('_no_activity', () => {});
        propertyGroups['_no_activity']![person] = 1;
      } else {
        for (var activityCount in participant.activityCounts) {
          final activityId = activityCount.activityReference.reference;
          propertyGroups.putIfAbsent(activityId, () => {});
          propertyGroups[activityId]![person] = activityCount.count;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: propertyGroups.entries.map((entry) {
        if (entry.key == '_no_activity') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.value.entries.map((personEntry) {
                final person = personEntry.key;
                return PersonAvatar(person: person, radius: 16, showName: true);
              }).toList(),
            ),
          );
        } else {
          final activity = eventState.sexualActivities?[entry.key];
          final activityEmoji = activity?.displayCharacter ?? '❔';
          final activityName = activity?.name ?? 'Unknown';
          final isRisky = activity?.isRisky ?? false;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(activityEmoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      activityName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isRisky) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.warning,
                        size: 14,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
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
                      return PersonAvatar(
                        person: person,
                        radius: 16,
                        count: count > 1 ? count : null,
                        showName: true,
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
