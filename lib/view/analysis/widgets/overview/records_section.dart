import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:indulge/view/common/event_card/event_card.dart';
import '../../models/analysis_data.dart';

class RecordsSection extends StatelessWidget {
  final AnalysisData data;

  const RecordsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.busiestDay == null && data.busiestEvent == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.busiestDay != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(elevation: 2, child: _buildBusiestDayInfo(context)),
          ),
        if (data.busiestDay != null && data.busiestEvent != null)
          const SizedBox(height: 12),
        if (data.busiestEvent != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(elevation: 2, child: _buildBusiestEventInfo(context)),
          ),
      ],
    );
  }

  Widget _buildBusiestDayInfo(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(data.busiestDay!);
    final dayEvents = data.events
        .where((e) => DateUtils.isSameDay(e.date, data.busiestDay!))
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Icon(
          Icons.event_busy,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'Busiest Day',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$dateStr • ${data.busiestDayEventCount} events',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: dayEvents
            .map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: EventCard(event: event),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBusiestEventInfo(BuildContext context) {
    final event = data.busiestEvent!;
    final dateStr = DateFormat('MMM d, yyyy').format(event.date);
    final activityCount = event.activities
        .expand((a) => a.participants)
        .expand((p) => p.activityCounts)
        .map((ac) => ac.activityReference.reference)
        .toSet()
        .length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Icon(
          Icons.celebration,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          'Busiest Event',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$dateStr • $activityCount activities',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [EventCard(event: event)],
      ),
    );
  }
}
