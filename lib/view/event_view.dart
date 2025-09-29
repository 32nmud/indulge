import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:indulge/domain/repositories/sexual_event_repository.dart';
import 'package:indulge/data/models/sexual_event.dart';

class EventViewPage extends StatefulWidget {
  final SexualEventRepository sexualEventRepo;
  const EventViewPage({super.key, required this.sexualEventRepo});

  @override
  State<EventViewPage> createState() => _EventViewPageState();
}

class _EventViewPageState extends State<EventViewPage> {
  DateTime _selectedDay = DateTime.now();
  late final ValueNotifier<List<SexualEvent>> _selectedEvents;

  String _getEventPreviewString(SexualEvent event) {
    String string = 'Sexual event with ';
    return '$string${event.participants}';
  }

  DateTime _getEarliestEvent() {
    return DateTime(2024, 1, 1);
  }

  DateTime _getLatestEvent() {
    return DateTime(2025, 12, 31);
  }

  @override
  void initState() {
    super.initState();
    _selectedEvents = ValueNotifier([]);
    // dataAccess.getEncountersInRange(startDate, endDate)
    widget.sexualEventRepo.getByDate(_selectedDay).then((events) {
      _selectedEvents = ValueNotifier(events);
    });
  }

  Widget _dayPicker() {
    return EasyDateTimeLinePicker.itemBuilder(
      firstDate: _getEarliestEvent(),
      lastDate: _getLatestEvent(),
      focusedDate: _selectedDay,
      onDateChange: (date) => {
        setState(() {
          _selectedDay = date;
          widget.sexualEventRepo
              .getByDate(date)
              .then((events) => _selectedEvents.value = events);
        })
      },
      itemExtent: 64.0,
      itemBuilder: (context, date, isSelected, isDisabled, isToday, onTap) =>
          _dayItem(context, date, isSelected, isDisabled, isToday, onTap),
    );
  }

  Widget _dayItem(
      BuildContext context, date, isSelected, isDisabled, isToday, onTap) {
    Future<List<SexualEvent>> eventsForDay =
        widget.sexualEventRepo.getByDate(date);
    ThemeData theme = Theme.of(context);
    return InkResponse(
      onTap: onTap,
      child: ValueListenableBuilder<List<SexualEvent>>(
          valueListenable: _selectedEvents,
          builder: (context, value, _) {
            return Card(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainer,
              borderOnForeground: isSelected,
              child: FutureBuilder(
                  future: eventsForDay,
                  builder: (ctx, snapshot) {
                    int count =
                        snapshot.hasData ? snapshot.data?.length ?? 0 : 0;
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Badge.count(
                        count: count,
                        isLabelVisible: count != 0,
                        alignment: Alignment.topRight,
                        offset: const Offset(0, 0),
                        child: Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat("MMM").format(date),
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              DateFormat("d").format(date),
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              DateFormat("E").format(date),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        )));
                  }),
            );
          }),
    );
  }

  Widget _encounterList() {
    return Expanded(
      child: ValueListenableBuilder<List<SexualEvent>>(
        valueListenable: _selectedEvents,
        builder: (context, value, _) {
          return ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_getEventPreviewString(value[index])),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _dayPicker(),
          const SizedBox(height: 8.0),
          _encounterList(),
        ],
      ),
    );
  }
}
