import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ensure ClinicalEventsProvider has finished initialization before asking it
      // to load day events. This avoids races where the provider's repository
      // hasn't been created yet.
      await context.read<ClinicalEventsProvider>().ready;
      // Use the sexual events provider to load sexual events for the day.
      context.read<SexualEventsProvider>().selectDate(_selectedDay);
      // Now ask the clinical events provider to load clinical events for the same day.
      context.read<ClinicalEventsProvider>().selectDate(_selectedDay);
    });
  }

  Future<void> _navigateToNextDay() async {
    final sexualProvider = context.read<SexualEventsProvider>();
    final clinicalProvider = context.read<ClinicalEventsProvider>();
    final store = context.read<EventStateStore>();
    // Normalize to midnight for consistent day queries
    final currentDate = store.state.selectedDate ?? DateTime.now();
    final normalizedCurrent = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final nextDate = normalizedCurrent.add(const Duration(days: 1));
    // Trigger sexual events load immediately.
    sexualProvider.selectDate(nextDate);
    // Ensure clinical provider is ready then request clinical events for the same date.
    await clinicalProvider.ready;
    clinicalProvider.selectDate(nextDate);
  }

  Future<void> _navigateToPreviousDay() async {
    final sexualProvider = context.read<SexualEventsProvider>();
    final clinicalProvider = context.read<ClinicalEventsProvider>();
    final store = context.read<EventStateStore>();
    // Normalize to midnight for consistent day queries
    final currentDate = store.state.selectedDate ?? DateTime.now();
    final normalizedCurrent = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final previousDate = normalizedCurrent.subtract(const Duration(days: 1));
    // Trigger sexual events load immediately.
    sexualProvider.selectDate(previousDate);
    // Ensure clinical provider is initialized and then request clinical events.
    await clinicalProvider.ready;
    clinicalProvider.selectDate(previousDate);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
        child: SizedBox.expand(
          child: Column(
            children: <Widget>[
              DayCard(),
              const SizedBox(height: 8.0),
              Expanded(child: AnimatedEventList()),
            ],
          ),
        ),
      ),
    );
  }
}
