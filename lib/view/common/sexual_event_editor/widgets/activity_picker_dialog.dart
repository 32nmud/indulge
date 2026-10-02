import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

class ActivityPickerDialog extends StatelessWidget {
  final Map<String, SexualActivityCategory> availableCategories;

  const ActivityPickerDialog({super.key, required this.availableCategories});

  /// Check if a category is a subcategory of another category
  bool _isSubcategory(SexualActivityCategory category) {
    for (final other in availableCategories.values) {
      for (final subRef in other.subCategories) {
        if (subRef.reference == category.id) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Filter to only show root parent categories
    final parentCategories = availableCategories.values
        .where((category) => !_isSubcategory(category))
        .toList();

    // Sort by user-defined order from Settings.
    parentCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return SimpleDialog(
      title: const Text('Select Activity Category'),
      children: parentCategories.map((category) {
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
