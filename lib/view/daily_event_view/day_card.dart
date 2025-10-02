import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/event_provider.dart';

class DayCard extends StatefulWidget {
  const DayCard({super.key});

  @override
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> {
  DateTime _selectedDay = DateTime.now();
  DateTime _getEarliestEvent() => DateTime(2024, 1, 1);
  DateTime _getLatestEvent() => DateTime(2025, 12, 31);

  Widget _dayPicker() {
    return EasyDateTimeLinePicker.itemBuilder(
      firstDate: _getEarliestEvent(),
      lastDate: _getLatestEvent(),
      focusedDate: _selectedDay,
      onDateChange: (date) {
        setState(() {
          _selectedDay = date;
          context.read<EventsProvider>().selectDate(date);
        });
      },
      itemExtent: 64.0,
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
    final provider = context.watch<EventsProvider>();
    final count = provider.state.dailyEventCount?[date] ?? 0;
    final theme = Theme.of(context);

    return InkResponse(
      onTap: onTap,
      child: Card(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainer,
        borderOnForeground: isSelected,
        child: Badge.count(
          count: count,
          isLabelVisible: count != 0,
          alignment: Alignment.topRight,
          offset: const Offset(-8, 8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('MMM').format(date),
                    style: theme.textTheme.bodySmall),
                Text(DateFormat('d').format(date),
                    style: theme.textTheme.titleLarge),
                Text(DateFormat('E').format(date),
                    style: theme.textTheme.bodySmall),
              ],
            ),
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
