import 'package:flutter/material.dart';
import 'package:indulge/data/models/sexual_event.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/event_provider.dart';
import 'package:indulge/provider/event_state.dart';
import 'activity_list.dart';

class EventEditorPage extends StatefulWidget {
  const EventEditorPage({super.key});

  @override
  State<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  Widget _activityList() {
    return AnimatedEventActivityList();
  }

  Widget _sectionHeader(String text) {
    return Padding(
        padding: EdgeInsetsGeometry.all(10),
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: TextStyle(fontWeight: FontWeight.w900),
        ));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<EventsProvider>;
    EventState state = context.read<EventsProvider>().state;
    SexualEvent? event = state.selectedEvent;

    return Scaffold(
      appBar: AppBar(title: const Text('Event Editor')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Activities:"),
          _activityList(),
        ],
      ),
    );
  }
}
