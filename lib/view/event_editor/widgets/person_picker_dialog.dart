import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

class PersonPickerDialog extends StatelessWidget {
  final List<Person> availablePersons;
  final Set<String> existingParticipantIds;
  final Person? myself;
  final VoidCallback onAddNew;

  const PersonPickerDialog({
    super.key,
    required this.availablePersons,
    required this.existingParticipantIds,
    required this.myself,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Select Person'),
      children: [
        // Anonymous participant option first
        Builder(
          builder: (context) {
            final anonymous = availablePersons.firstWhere(
              (p) => p.id == 'anonymous',
              orElse: () => availablePersons.first,
            );
            final alreadyAdded = existingParticipantIds.contains(anonymous.id);

            return SimpleDialogOption(
              onPressed: alreadyAdded
                  ? null
                  : () => Navigator.pop(context, anonymous),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Anonymous',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  if (alreadyAdded)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
            );
          },
        ),
        const Divider(),
        // Other persons (excluding anonymous and myself)
        ...availablePersons
            .where((person) {
              if (person.id == 'anonymous') return false;
              if (myself != null && person.id == myself?.id) return false;
              return true;
            })
            .map((person) {
              final alreadyAdded = existingParticipantIds.contains(
                person.id ?? '',
              );

              return SimpleDialogOption(
                onPressed: alreadyAdded
                    ? null
                    : () => Navigator.pop(context, person),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        person.name.nickname ?? person.name.given ?? 'Unknown',
                      ),
                    ),
                    if (alreadyAdded)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                  ],
                ),
              );
            }),
        const Divider(),
        // Add new person option
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, 'ADD_NEW');
          },
          child: Row(
            children: [
              Icon(
                Icons.person_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Person',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<dynamic> show({
    required BuildContext context,
    required List<Person> availablePersons,
    required Set<String> existingParticipantIds,
    required Person? myself,
    required VoidCallback onAddNew,
  }) {
    return showDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PersonPickerDialog(
        availablePersons: availablePersons,
        existingParticipantIds: existingParticipantIds,
        myself: myself,
        onAddNew: onAddNew,
      ),
    );
  }
}
