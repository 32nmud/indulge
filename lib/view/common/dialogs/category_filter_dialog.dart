import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

class CategoryFilterDialog extends StatefulWidget {
  final List<SexualActivityCategory> categories;
  final Set<String> selectedIds;
  final bool singleSelect;

  const CategoryFilterDialog({
    super.key,
    required this.categories,
    required this.selectedIds,
    this.singleSelect = false,
  });

  @override
  State<CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<CategoryFilterDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    // Sort categories alphabetically by name
    final sortedCategories = List<SexualActivityCategory>.from(
      widget.categories,
    )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return AlertDialog(
      title: const Text('Filter by Categories'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: sortedCategories.map((category) {
            final isSelected = _selectedIds.contains(category.id);

            if (widget.singleSelect) {
              return RadioListTile<String>(
                title: Row(
                  children: [
                    Text(
                      category.displayCharacter ?? '❔',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(category.name),
                  ],
                ),
                value: category.id,
                groupValue: _selectedIds.isNotEmpty ? _selectedIds.first : null,
                onChanged: (value) {
                  setState(() {
                    _selectedIds.clear();
                    if (value != null) {
                      _selectedIds.add(value);
                    }
                  });
                },
              );
            }

            return CheckboxListTile(
              title: Row(
                children: [
                  Text(
                    category.displayCharacter ?? '❔',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(category.id);
                  } else {
                    _selectedIds.remove(category.id);
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
