import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

/// Shows a dialog to pick an activity role (Give, Receive, Both, Participated).
Future<ActivityRole?> showRolePickerDialog(
  BuildContext context,
  ActivityRole currentRole,
) async {
  return showDialog<ActivityRole>(
    context: context,
    builder: (context) => RolePickerDialog(currentRole: currentRole),
  );
}

/// Dialog widget for selecting an activity role.
class RolePickerDialog extends StatefulWidget {
  final ActivityRole currentRole;

  const RolePickerDialog({super.key, required this.currentRole});

  @override
  State<RolePickerDialog> createState() => _RolePickerDialogState();
}

class _RolePickerDialogState extends State<RolePickerDialog> {
  late ActivityRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
  }

  String _roleLabel(ActivityRole role) {
    switch (role) {
      case ActivityRole.give:
        return 'Gave';
      case ActivityRole.receive:
        return 'Received';
      case ActivityRole.both:
        return 'Both';
      case ActivityRole.participated:
        return 'Participated';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Role'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ActivityRole.values
            .where((role) => role != ActivityRole.participated)
            .map((role) {
              return ListTile(
                leading: Radio<ActivityRole>(
                  value: role,
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    if (value != null) {
                      Navigator.of(context).pop(value);
                    }
                  },
                ),
                title: Text(_roleLabel(role)),
                onTap: () {
                  Navigator.of(context).pop(role);
                },
              );
            })
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
