import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

/// Callback when the header is tapped to toggle expansion.
typedef OnToggleExpanded = void Function();

/// Callback when the remove button is pressed.
typedef OnRemove = void Function();

/// The header portion of an [ActivityCard], showing the activity category
/// emoji, name, and controls.
class ActivityCardHeader extends StatelessWidget {
  final SexualActivityCategory? activityCategory;
  final String emoji;
  final String name;
  final bool isExpanded;
  final OnToggleExpanded onToggleExpanded;
  final OnRemove onRemove;

  const ActivityCardHeader({
    super.key,
    required this.activityCategory,
    required this.emoji,
    required this.name,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggleExpanded,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (activityCategory?.requiresPartner == true)
                      const Text(
                        'Requires partner',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 24,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onRemove,
                tooltip: 'Remove activity',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
