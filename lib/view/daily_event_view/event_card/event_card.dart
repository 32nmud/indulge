import 'package:flutter/material.dart';
import 'package:indulge/data/models/sexual_event/sexual_event.dart';
import 'package:indulge/data/models/person/person.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:provider/provider.dart';
import '../../event_editor/event_editor.dart';

class EventCard extends StatefulWidget {
  final SexualEvent event;
  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  String _getEventPreviewString(List<Person> persons) {
    return 'Sexual event with ${persons.length}';
  }

  Widget _editButton(BuildContext context) {
    SexualEventsProvider provider = context.read<SexualEventsProvider>();

    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: () {
        provider.selectEvent(super.widget.event);
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const EventEditorPage(),
          ),
        );
      },
    );
  }

  //TODO: Update this to return a card that has a circular progress indicator while waiting for DB queries
  Widget _eventCard(BuildContext context) {
    SexualEventsProvider provider = context.read<SexualEventsProvider>();
    final Future<List<Person>> futurePersons = provider.getPersonsForEvent(
      super.widget.event.id,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
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
              return Row(
                children: [
                  Expanded(
                    child: Text(_getEventPreviewString(snapshot.data ?? [])),
                  ),
                  _editButton(context),
                ],
              );
            }

            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _eventCard(context);
  }
}
