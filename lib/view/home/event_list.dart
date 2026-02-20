import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/data/models/v2/clinical_event/clinical_event.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/view/common/sexual_event_card.dart';
import 'package:indulge/view/common/clinical_event_card/clinical_event_card.dart';

class AnimatedEventList extends StatelessWidget {
  const AnimatedEventList({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EventStateStore>();
    final sexualEvents = store.state.currentEvents ?? [];
    final clinicalEvents = store.state.currentClinicalEvents ?? [];

    // Combine both lists into a single list and sort by date descending
    final combined = <dynamic>[];
    combined.addAll(sexualEvents);
    combined.addAll(clinicalEvents);

    combined.sort((a, b) {
      // Defensive: assume both have a `date` field of type DateTime
      final DateTime da = a.date;
      final DateTime db = b.date;
      // Oldest first (ascending)
      return da.compareTo(db);
    });

    // If both lists are empty, show an empty state
    if (combined.isEmpty) {
      return Center(
        child: Text(
          'No events for this day',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      itemCount: combined.length,
      itemBuilder: (context, idx) {
        final item = combined[idx];
        Widget card;
        if (item is SexualEvent) {
          card = SexualEventCard(event: item);
        } else if (item is ClinicalEvent) {
          card = ClinicalEventCard(key, event: item);
        } else {
          // Fallback for unknown types
          card = const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: card,
        );
      },
    );
  }
}
