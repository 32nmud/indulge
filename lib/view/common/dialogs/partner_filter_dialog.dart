import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/person_avatar.dart';

class PartnerFilterDialog extends StatefulWidget {
  final List<Person> allPersons;
  final Set<String> selectedIds;

  const PartnerFilterDialog({
    super.key,
    required this.allPersons,
    required this.selectedIds,
  });

  @override
  State<PartnerFilterDialog> createState() => _PartnerFilterDialogState();
}

class _PartnerFilterDialogState extends State<PartnerFilterDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Partners'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.allPersons.map((person) {
            final isSelected = _selectedIds.contains(person.id);
            return CheckboxListTile(
              title: Row(
                children: [
                  PersonAvatar(person: person, radius: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      person.name.nickname ?? person.name.given ?? 'Unknown',
                    ),
                  ),
                ],
              ),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(person.id);
                  } else {
                    _selectedIds.remove(person.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedIds.clear();
            });
          },
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
