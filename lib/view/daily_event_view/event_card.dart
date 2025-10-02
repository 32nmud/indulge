import 'package:flutter/material.dart';
import 'package:indulge/data/models/sexual_event.dart';

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

  Widget _eventCard() {
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(10),
      child: Text(_getEventPreviewString(super.widget.event)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _eventCard();
  }
}
