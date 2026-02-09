import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';

class DayCard extends StatefulWidget {
  const DayCard({super.key});

  @override
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> {
  DateTime _getEarliestEvent() => DateTime(2024, 1, 1);
  DateTime _getLatestEvent() => DateTime(2026, 12, 31);

  Widget _dayPicker() {
    final provider = context.watch<SexualEventsProvider>();
    final selectedDay = provider.state.selectedDate ?? DateTime.now();

    return EasyDateTimeLinePicker.itemBuilder(
      key: ValueKey(selectedDay.toIso8601String()),
      firstDate: _getEarliestEvent(),
      lastDate: _getLatestEvent(),
      focusedDate: selectedDay,
      onDateChange: (date) {
        context.read<SexualEventsProvider>().selectDate(date);
      },
      itemExtent: 80.0,
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
    final provider = context.watch<SexualEventsProvider>();
    // Normalize date to match the keys in dailyEventCount (removes time component)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final count = provider.state.dailyEventCount?[normalizedDate] ?? 0;
    final theme = Theme.of(context);

    return InkResponse(
      onTap: onTap,
      child: Card(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainer,
        borderOnForeground: isSelected,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM').format(date),
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    DateFormat('d').format(date),
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    DateFormat('E').format(date),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (count > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return _dayPicker();
  }
}
