import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:provider/provider.dart';

class EventCard extends StatefulWidget {
  final SexualEvent event;
  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  /* ########################
         Main build
  ####################### */

  @override
  Widget build(BuildContext context) {
    SexualEventsProvider provider = context.watch<SexualEventsProvider>();
    final List<SexualActivity> activities = widget.event.activities;
    final EventState eventState = provider.state;
    final Future<List<Person>> participants = provider.getPersonsForEvent(
      widget.event.id,
    );

    return Card(
      child: FutureBuilder<List<Person>>(
        future: participants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No participants found');
          } else {
            return _eventCard(context, snapshot.data!, eventState, activities);
          }
        },
      ),
    );
  }

  /* ########################
          Widgets
  ####################### */

  Widget _eventCard(
    BuildContext context,
    List<Person> persons,
    EventState eventState,
    List<SexualActivity> activities,
  ) {
    return ExpansionTile(
      leading: _previewIcon(),
      title: Text(_getEventTitleString(persons)),
      subtitle: _getEventPreviewText(activities, eventState),
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _activitiesOverview(activities, persons, eventState),
        _buttonRow(context),
      ],
    );
  }

  Widget _previewIcon() {
    return Padding(
      padding: EdgeInsetsGeometry.directional(end: 10),
      child: Icon(Icons.monitor_heart),
    );
  }

  Widget _getEventPreviewText(
    List<SexualActivity> activities,
    EventState eventState,
  ) {
    List<TextSpan> spans = [];
    for (SexualActivity activity in activities) {
      String activityTitle =
          eventState.sexualActivityTypes![activity.type.reference]!.name;
      String activityIcon =
          eventState
              .sexualActivityTypes![activity.type.reference]!
              .displayCharacter ??
          '❔';
      spans.add(
        TextSpan(
          text:
              '$activityIcon $activityTitle with ${activity.participants.length} ${activity.participants.length == 1 ? 'person' : 'people'}${spans.isNotEmpty ? '' : '\n'}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _activitiesOverview(
    List<SexualActivity> activities,
    List<Person> persons,
    EventState eventState,
  ) {
    List<TextSpan> spans = [];
    for (SexualActivity activity in activities) {
      String activityTitle =
          eventState.sexualActivityTypes![activity.type.reference]!.name;
      String activityIcon =
          eventState
              .sexualActivityTypes![activity.type.reference]!
              .displayCharacter ??
          '❔';
      spans.add(
        TextSpan(
          text:
              '${spans.isNotEmpty ? '\n' : ''}$activityIcon $activityTitle with ${activity.participants.length} people',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      );
      spans.addAll(_participantsOverview(persons, activity));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _editButton(BuildContext context) {
    // TODO: This needs to be implemented
    return ElevatedButton.icon(
      icon: Icon(Icons.edit),
      label: Text("Edit"),
      onPressed: () {},
    );
  }

  Widget _deleteButton(BuildContext context) {
    // TODO: This needs to be implemented
    return ElevatedButton.icon(
      icon: Icon(Icons.delete),
      label: Text("Remove"),
      onPressed: () {},
    );
  }

  Widget _buttonRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [_editButton(context), _deleteButton(context)],
    );
  }

  /* ########################
        Helper Methods
  ####################### */

  String _getEventTitleString(List<Person> persons) {
    return 'Sexual event with ${persons.length} ${persons.length == 1 ? 'person' : 'people'}';
  }

  List<TextSpan> _participantsOverview(
    List<Person> persons,
    SexualActivity activity,
  ) {
    SexualEventsProvider provider = context.read<SexualEventsProvider>();
    List<TextSpan> participantSpans = [];
    Map<String, TextSpan> propertyTitles = {};
    Map<String, List<TextSpan>> participantTitles = {};
    for (Person person in persons) {
      final properties = provider
          .getSexualActivityTypePropertiesForPersonAndActivity(
            person,
            activity,
          );

      for (SexualActivityTypeProperty property in properties) {
        String propertyTitle =
            "\n    ${property.displayCharacter} ${property.name}${property.isRisky ? ' (❗)' : ''}";
        propertyTitles.putIfAbsent(
          property.id,
          () => TextSpan(
            text: propertyTitle,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        );

        String personTitle =
            "\n        • ${person.name.nickname ?? person.name.given ?? "unknown"}";
        if (participantTitles.containsKey(property.id)) {
          participantTitles[property.id]!.add(
            TextSpan(
              text: personTitle,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          );
        } else {
          participantTitles[property.id] = [
            TextSpan(
              text: personTitle,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ];
        }
      }
    }

    for (String key in participantTitles.keys) {
      participantSpans.add(propertyTitles[key]!);
      participantSpans.addAll(participantTitles[key]!);
    }

    return participantSpans;
  }
}
