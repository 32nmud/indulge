import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/clinical_event_provider.dart';

class CalendarView extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final bool isMonthView;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onFocusedMonthChanged;

  const CalendarView({
    super.key,
    required this.selectedDate,
    required this.focusedMonth,
    required this.isMonthView,
    required this.onDateSelected,
    required this.onFocusedMonthChanged,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _getEarliestEvent() => DateTime(2000, 1, 1);
  DateTime _getLatestEvent() => DateTime(2100, 12, 31);

  CalendarFormat get _calendarFormat =>
      widget.isMonthView ? CalendarFormat.month : CalendarFormat.week;

  void _navigateForward() {
    if (widget.isMonthView) {
      widget.onFocusedMonthChanged(
        DateTime(
          widget.focusedMonth.year,
          widget.focusedMonth.month + 1,
          widget.focusedMonth.day,
        ),
      );
    } else {
      widget.onFocusedMonthChanged(
        widget.focusedMonth.add(const Duration(days: 7)),
      );
    }
  }

  void _navigateBackward() {
    if (widget.isMonthView) {
      widget.onFocusedMonthChanged(
        DateTime(
          widget.focusedMonth.year,
          widget.focusedMonth.month - 1,
          widget.focusedMonth.day,
        ),
      );
    } else {
      widget.onFocusedMonthChanged(
        widget.focusedMonth.subtract(const Duration(days: 7)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EventStateStore>();
    final dailyEventCount = store.state.dailyEventCount ?? {};
    final dailyClinicalPresence = store.state.dailyClinicalEventPresence ?? {};
    final theme = Theme.of(context);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < -500) {
          _navigateForward();
        } else if (details.primaryVelocity! > 500) {
          _navigateBackward();
        }
      },
      child: TableCalendar(
        firstDay: _getEarliestEvent(),
        lastDay: _getLatestEvent(),
        focusedDay: widget.focusedMonth,
        selectedDayPredicate: (day) => isSameDay(widget.selectedDate, day),
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(1),
          cellPadding: EdgeInsets.zero,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: theme.textTheme.titleSmall ?? const TextStyle(),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 2),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle:
              theme.textTheme.bodySmall?.copyWith(fontSize: 12) ??
              const TextStyle(fontSize: 10),
          weekendStyle:
              theme.textTheme.bodySmall?.copyWith(fontSize: 12) ??
              const TextStyle(fontSize: 10),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              context,
              day,
              isSelected: false,
              isToday: false,
              isOutside: day.month != focusedDay.month,
              dailyEventCount: dailyEventCount,
              dailyClinicalPresence: dailyClinicalPresence,
              theme: theme,
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              context,
              day,
              isSelected: true,
              isToday: false,
              isOutside: day.month != focusedDay.month,
              dailyEventCount: dailyEventCount,
              dailyClinicalPresence: dailyClinicalPresence,
              theme: theme,
            );
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              context,
              day,
              isSelected: isSameDay(widget.selectedDate, day),
              isToday: true,
              isOutside: day.month != focusedDay.month,
              dailyEventCount: dailyEventCount,
              dailyClinicalPresence: dailyClinicalPresence,
              theme: theme,
            );
          },
          outsideBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              context,
              day,
              isSelected: false,
              isToday: false,
              isOutside: true,
              dailyEventCount: dailyEventCount,
              dailyClinicalPresence: dailyClinicalPresence,
              theme: theme,
            );
          },
        ),
        onDaySelected: (selectedDay, focusedDay) {
          widget.onDateSelected(selectedDay);
        },
        onPageChanged: (focusedDay) {
          widget.onFocusedMonthChanged(focusedDay);
        },
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day, {
    required bool isSelected,
    required bool isToday,
    required bool isOutside,
    required Map<DateTime, int> dailyEventCount,
    required Map<DateTime, bool> dailyClinicalPresence,
    required ThemeData theme,
  }) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    final count = dailyEventCount[normalizedDate] ?? 0;
    final hasClinicalEvent = dailyClinicalPresence[normalizedDate] ?? false;

    return InkWell(
      onTap: () {
        context.read<SexualEventsProvider>().selectDate(day);
        context.read<ClinicalEventsProvider>().selectDate(day);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : isToday
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : isToday
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            width: isSelected || isToday ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isOutside
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                      : isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (hasClinicalEvent && !isOutside)
              Positioned(
                top: 1,
                left: 1,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            if (count > 0 && !isOutside)
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
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
}
