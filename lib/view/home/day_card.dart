import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';

class DayCard extends StatefulWidget {
  const DayCard({super.key});

  @override
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> {
  late EasyDatePickerController _controller;
  DateTime? _previousSelectedDate;

  @override
  void initState() {
    super.initState();
    _controller = EasyDatePickerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _getEarliestEvent() => DateTime(2024, 1, 1);
  DateTime _getLatestEvent() => DateTime(2026, 12, 31);

  Widget _dayPicker() {
    final store = context.watch<EventStateStore>();
    final selectedDay = store.state.selectedDate ?? DateTime.now();

    // Animate to the new date when it changes
    if (_previousSelectedDate != selectedDay) {
      _previousSelectedDate = selectedDay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.animateToFocusDate(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }

    return EasyDateTimeLinePicker.itemBuilder(
      controller: _controller,
      firstDate: _getEarliestEvent(),
      lastDate: _getLatestEvent(),
      focusedDate: selectedDay,
      onDateChange: (date) {
        context.read<SexualEventsProvider>().selectDate(date);
        context.read<ClinicalEventsProvider>().selectDate(date);
      },
      itemExtent: 80.0,
      selectionMode: const SelectionMode.autoCenter(),
      itemBuilder: (context, date, isSelected, isDisabled, isToday, onTap) =>
          _dayItem(context, date, isSelected, isDisabled, isToday, onTap),
    );
  }

  Widget _dayItem(
    BuildContext context,
    DateTime date,
    bool isSelected,
    bool isDisabled,
    bool isToday,
    VoidCallback onTap,
  ) {
    final store = context.watch<EventStateStore>();
    // Normalize date to match the keys in dailyEventCount (removes time component)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final count = store.state.dailyEventCount?[normalizedDate] ?? 0;
    final hasClinicalEvent =
        store.state.dailyClinicalEventPresence?[normalizedDate] ?? false;
    final theme = Theme.of(context);

    return InkResponse(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Card(
          color: Colors.transparent,
          elevation: 0,
          borderOnForeground: false,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: (theme.textTheme.bodySmall ?? const TextStyle())
                          .copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                      child: Text(DateFormat('MMM').format(date)),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: (theme.textTheme.titleLarge ?? const TextStyle())
                          .copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                      child: Text(DateFormat('d').format(date)),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: (theme.textTheme.bodySmall ?? const TextStyle())
                          .copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                      child: Text(DateFormat('E').format(date)),
                    ),
                  ],
                ),
              ),
              if (hasClinicalEvent)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_services,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (count > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _dayPicker();
  }
}
