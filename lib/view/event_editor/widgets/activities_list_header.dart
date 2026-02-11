import 'package:flutter/material.dart';

/// Header widget for the activities list section with title and add button
class ActivitiesListHeader extends StatelessWidget {
  final VoidCallback onAddActivity;

  const ActivitiesListHeader({super.key, required this.onAddActivity});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Activities',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          onPressed: onAddActivity,
          icon: const Icon(Icons.add),
          label: const Text('Add Activity'),
        ),
      ],
    );
  }
}
