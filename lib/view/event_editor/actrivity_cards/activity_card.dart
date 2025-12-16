import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:provider/provider.dart';

class ActivityCard extends StatefulWidget {
  final SexualActivity activity;
  const ActivityCard({super.key, required this.activity});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  Widget _previewIcon() {
    return Padding(
      padding: EdgeInsetsGeometry.directional(end: 10),
      child: Icon(Icons.monitor_heart),
    );
  }

  Widget _previewText() {
    int numberOfParticipants = super.widget.activity.participants.length;
    String conjugatedPerson = (numberOfParticipants > 1) ? "people" : "person";
    return Text("Activity with $numberOfParticipants $conjugatedPerson");
  }

  Widget _participantOverview(List<Person> persons) {
    SexualEventsProvider provider = context.read<SexualEventsProvider>();
    List<Widget> participantWidgets = [];
    Map<String, Widget> propertyTitles = {};
    Map<String, List<Widget>> participantTitles = {};
    for (Person person in persons) {
      final properties = provider
          .getSexualActivityTypePropertiesForPersonAndActivity(
            person,
            widget.activity,
          );

      for (SexualActivityTypeProperty property in properties) {
        String propertyTitle =
            "${property.displayCharacter} ${property.name}${property.isRisky ? ' (❗)' : ''}";
        propertyTitles.putIfAbsent(
          property.id,
          () => Text(
            propertyTitle,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );

        String personTitle =
            "    - ${person.name.nickname ?? person.name.given ?? "unknown"}";
        if (participantTitles.containsKey(property.id)) {
          participantTitles[property.id]!.add(Text(personTitle));
        } else {
          participantTitles[property.id] = [Text(personTitle)];
        }
      }
    }

    for (String key in participantTitles.keys) {
      participantWidgets.add(propertyTitles[key]!);
      participantWidgets.addAll(participantTitles[key]!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: participantWidgets,
    );
  }

  Widget _editButton(BuildContext context) {
    // EventsProvider provider = context.read<EventsProvider>();
    return ElevatedButton.icon(
      icon: Icon(Icons.edit),
      label: Text("Edit"),
      onPressed: () {},
    );
  }

  Widget _deleteButton(BuildContext context) {
    SexualEventsProvider provider = context.read<SexualEventsProvider>();
    return ElevatedButton.icon(
      icon: Icon(Icons.delete),
      label: Text("Remove"),
      onPressed: () {
        provider.removeActivity(widget.activity);
      },
    );
  }

  Widget _buttonRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [_editButton(context), _deleteButton(context)],
    );
  }

  Widget _activityCard(BuildContext context) {
    SexualEventsProvider provider = context.watch<SexualEventsProvider>();
    final Future<List<Person>> futurePersons = provider.getPersonsForActivity(
      widget.activity,
    );

    final typeId = widget.activity.type.reference;
    final activityType = provider.state.selectedEventActivityTypes?[typeId];

    return Card(
      child: FutureBuilder(
        future: futurePersons,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.hasData) {
            return ExpansionTile(
              leading: _previewIcon(),
              title: Text(activityType?.name ?? "Unknown Activity"),
              subtitle: _previewText(),
              expandedAlignment: Alignment.centerLeft,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _participantOverview(snapshot.data ?? []),
                _buttonRow(context),
              ],
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _activityCard(context);
  }
}
