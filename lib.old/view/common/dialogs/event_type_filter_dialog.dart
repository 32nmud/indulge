import 'package:flutter/material.dart';

/// A reusable dialog for selecting an event type.
///
/// Returns the selected event type as a `String?` when closed via the
/// 'Apply' button. If the user presses 'Cancel' the dialog returns `null`.
/// If the user presses 'Clear' the selection is reset to `null` in the UI
/// and can be applied by pressing 'Apply'.
class EventTypeFilterDialog extends StatefulWidget {
  final String? selectedType;

  const EventTypeFilterDialog({super.key, this.selectedType});

  @override
  State<EventTypeFilterDialog> createState() => _EventTypeFilterDialogState();
}

class _EventTypeFilterDialogState extends State<EventTypeFilterDialog> {
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    final types = ['Solo', 'Couple', 'Group'];

    return AlertDialog(
      title: const Text('Select Event Type'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: types.map((type) {
            return RadioListTile<String>(
              title: Text(type),
              value: type,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Cancel -> no change
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Clear selection in dialog; user must press Apply to confirm.
            setState(() {
              _selectedType = null;
            });
          },
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedType),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
