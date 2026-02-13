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

  void _navigateToNextDay() {
    final provider = context.read<SexualEventsProvider>();
    final currentDate = provider.state.selectedDate ?? DateTime.now();
    final nextDate = currentDate.add(const Duration(days: 1));
    provider.selectDate(nextDate);
  }

  void _navigateToPreviousDay() {
    final provider = context.read<SexualEventsProvider>();
    final currentDate = provider.state.selectedDate ?? DateTime.now();
    final previousDate = currentDate.subtract(const Duration(days: 1));
    provider.selectDate(previousDate);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe left (next day) - negative velocity
        if (details.primaryVelocity! < -500) {
          _navigateToNextDay();
        }
        // Swipe right (previous day) - positive velocity
        else if (details.primaryVelocity! > 500) {
          _navigateToPreviousDay();
        }
      },
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              DayCard(),
              const SizedBox(height: 8.0),
              AnimatedEventList(),
            ],
          ),
        ),
      ),
    );
  }
}
