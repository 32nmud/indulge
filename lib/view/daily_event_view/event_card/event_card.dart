import 'package:flutter/material.dart';
import 'package:indulge/data/models/sexual_event.dart';
import 'package:indulge/provider/event_provider.dart';
import 'package:provider/provider.dart';
import '../../event_editor/event_editor.dart';

class EventCard extends StatefulWidget {
  final SexualEvent event;
  const EventCard({
    super.key,
    required this.event,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  String _getEventPreviewString(SexualEvent event) {
    return 'Sexual event with ${event.participants}';
  }

  Widget _editButton(BuildContext context) {
    EventsProvider provider = context.read<EventsProvider>();

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
        });
  }

  Widget _eventCard(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                    child: Text(_getEventPreviewString(super.widget.event))),
                _editButton(context),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return _eventCard(context);
  }
}
