import 'package:flutter/material.dart';
import 'package:indulge/data/models/sexual_event/sexual_event.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/event_state.dart';

class EventEditorPage extends StatefulWidget {
  const EventEditorPage({super.key});

  @override
  State<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  @override
  Widget build(BuildContext context) {
    context.watch<SexualEventsProvider>;
    EventState state = context.read<SexualEventsProvider>().state;
    SexualEvent? event = state.selectedEvent;

    return Scaffold(
      appBar: AppBar(title: const Text('Event Editor')),
      body: const Center(child: Text("This is a placeholder")),
    );
  }
}
