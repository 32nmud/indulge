import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/sexual_event_editor/widgets/callbacks.dart';

/// The participants section of an [ActivityCard], displaying participant chips
/// and an "Add" button when the user has no solo activities.
class ActivityCardParticipantsSection extends StatelessWidget {
  final List<ActivityParticipant> participants;
  final List<Person> availablePersons;
  final Person? myself;
  final bool userHasSoloActivity;
  final bool requiresPartner;
  final VoidCallback onShowPersonPicker;
  final OnRemoveParticipant onRemoveParticipant;

  const ActivityCardParticipantsSection({
    super.key,
    required this.participants,
    required this.availablePersons,
    required this.myself,
    required this.userHasSoloActivity,
    this.requiresPartner = false,
    required this.onShowPersonPicker,
    required this.onRemoveParticipant,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Participants',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (!userHasSoloActivity)
              TextButton.icon(
                onPressed: onShowPersonPicker,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (participants.isEmpty)
          _buildEmptyParticipantsState(context)
        else
          _buildParticipantChips(context),
      ],
    );
  }

  Widget _buildEmptyParticipantsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              requiresPartner
                  ? 'Add at least one partner to continue'
                  : 'Add other participants, or toggle activities below to track your own participation',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: participants.asMap().entries.map((entry) {
        final participantIndex = entry.key;
        final participant = entry.value;
        final person = availablePersons.firstWhere(
          (p) => p.id == participant.participant.reference,
          orElse: () => Person(
            date: DateTime.now(),
            name: const Name(given: 'Unknown'),
          ),
        );
        final personName =
            person.name.nickname ?? person.name.given ?? 'Unknown';
        final isSelf = myself != null && person.id == myself!.id;

        return Chip(
          avatar: Icon(
            isSelf ? Icons.account_circle : Icons.person,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: Text(
            personName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          onDeleted: () => onRemoveParticipant(participantIndex),
          deleteIcon: const Icon(Icons.close, size: 18),
        );
      }).toList(),
    );
  }
}
