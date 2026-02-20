import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/services/preferences_service.dart';
import 'event_list.dart';
import 'calendar_view.dart';

class EventViewPage extends StatefulWidget {
  const EventViewPage({super.key});

  @override
  State<EventViewPage> createState() => _EventViewPageState();
}

class _EventViewPageState extends State<EventViewPage>
    with SingleTickerProviderStateMixin {
  final DateTime _selectedDay = DateTime.now();
  late DateTime _calendarFocusedMonth;
  bool _isMonthView = true;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  DateTime? _previousDate;

  @override
  void initState() {
    super.initState();
    _calendarFocusedMonth = DateTime.now();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    // Trigger the initial load for the current day once the widget tree is built.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load saved calendar view mode preference
      try {
        final prefs = Provider.of<PreferencesService>(context, listen: false);
        setState(() {
          _isMonthView = prefs.getCalendarViewMode();
        });
      } catch (_) {
        // PreferencesService not available yet
      }

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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextDay() async {
    final store = context.read<EventStateStore>();
    final currentDate = store.state.selectedDate ?? DateTime.now();
    final normalizedCurrent = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final nextDate = normalizedCurrent.add(const Duration(days: 1));

    // Update calendar focus to show the new date
    _updateCalendarFocus(nextDate);

    // Trigger animation
    _animateToDate(nextDate, isForward: true);

    final sexualProvider = context.read<SexualEventsProvider>();
    final clinicalProvider = context.read<ClinicalEventsProvider>();
    sexualProvider.selectDate(nextDate);
    await clinicalProvider.ready;
    clinicalProvider.selectDate(nextDate);
  }

  Future<void> _navigateToPreviousDay() async {
    final store = context.read<EventStateStore>();
    final currentDate = store.state.selectedDate ?? DateTime.now();
    final normalizedCurrent = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final previousDate = normalizedCurrent.subtract(const Duration(days: 1));

    // Update calendar focus to show the new date
    _updateCalendarFocus(previousDate);

    // Trigger animation
    _animateToDate(previousDate, isForward: false);

    final sexualProvider = context.read<SexualEventsProvider>();
    final clinicalProvider = context.read<ClinicalEventsProvider>();
    sexualProvider.selectDate(previousDate);
    await clinicalProvider.ready;
    clinicalProvider.selectDate(previousDate);
  }

  void _updateCalendarFocus(DateTime date) {
    setState(() {
      _calendarFocusedMonth = date;
    });
  }

  void _animateToDate(DateTime newDate, {required bool isForward}) {
    _previousDate = _previousDate ?? newDate;

    // Set animation from off-screen position to on-screen
    _slideAnimation =
        Tween<Offset>(
          begin: Offset(isForward ? 1.0 : -1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animationController.reset();
    _animationController.forward();

    _previousDate = newDate;
  }

  void _toggleCalendarFormat() {
    try {
      final prefs = Provider.of<PreferencesService>(context, listen: false);
      final newMode = !_isMonthView;
      prefs.setCalendarViewMode(newMode);
      setState(() {
        _isMonthView = newMode;
      });
    } catch (_) {
      // PreferencesService not available
    }
  }

  void _onDateSelected(DateTime date) {
    final sexualProvider = context.read<SexualEventsProvider>();
    final clinicalProvider = context.read<ClinicalEventsProvider>();
    sexualProvider.selectDate(date);
    clinicalProvider.selectDate(date);

    // Update calendar focus to match selected date
    _updateCalendarFocus(date);
  }

  void _onFocusedMonthChanged(DateTime focusedMonth) {
    setState(() {
      _calendarFocusedMonth = focusedMonth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EventStateStore>();
    final selectedDate = store.state.selectedDate ?? DateTime.now();
    final theme = Theme.of(context);

    return SafeArea(
      child: SizedBox.expand(
        child: Column(
          children: <Widget>[
            // Header with toggle button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMM d, y').format(selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Toggle button for week/month view
                  TextButton.icon(
                    onPressed: _toggleCalendarFormat,
                    icon: Icon(
                      _isMonthView
                          ? Icons.calendar_view_week
                          : Icons.calendar_month,
                      size: 20,
                    ),
                    label: Text(
                      _isMonthView ? 'Week view' : 'Month view',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Calendar (week or month view)
            CalendarView(
              selectedDate: selectedDate,
              focusedMonth: _calendarFocusedMonth,
              isMonthView: _isMonthView,
              onDateSelected: _onDateSelected,
              onFocusedMonthChanged: _onFocusedMonthChanged,
            ),
            const SizedBox(height: 8.0),
            // Event list with swipe handling for day navigation and slide animation
            Expanded(
              child: GestureDetector(
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
                child: SlideTransition(
                  position: _slideAnimation,
                  child: const AnimatedEventList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
