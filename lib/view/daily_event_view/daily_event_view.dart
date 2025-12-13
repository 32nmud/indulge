import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'day_card.dart';
import 'event_list.dart';

class EventViewPage extends StatefulWidget {
  const EventViewPage({super.key});

  @override
  State<EventViewPage> createState() => _EventViewPageState();
}

class _EventViewPageState extends State<EventViewPage> {
  final DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Trigger the initial load for the current day once the widget tree is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SexualEventsProvider>().selectDate(_selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          DayCard(),
          const SizedBox(height: 8.0),
          AnimatedEventList(),
        ],
      ),
    );
  }
}
