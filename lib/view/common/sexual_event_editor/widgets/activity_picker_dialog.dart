import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

class ActivityPickerDialog extends StatelessWidget {
  final Map<String, SexualActivityCategory> availableCategories;

  const ActivityPickerDialog({super.key, required this.availableCategories});

  @override
  Widget build(BuildContext context) {
    // Sort categories alphabetically by name
    final sortedCategories = availableCategories.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return SimpleDialog(
      title: const Text('Select Activity Category'),
      children: sortedCategories.map((category) {
        return SimpleDialogOption(
          onPressed: () => Navigator.pop(context, category),
          child: Row(
            children: [
              Text(
                category.displayCharacter ?? '❔',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static Future<SexualActivityCategory?> show({
    required BuildContext context,
    required Map<String, SexualActivityCategory> availableCategories,
  }) {
    return showDialog<SexualActivityCategory>(
      context: context,
      builder: (context) =>
          ActivityPickerDialog(availableCategories: availableCategories),
    );
  }
}
