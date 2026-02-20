import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

class ActivityFilterDialog extends StatefulWidget {
  final List<SexualActivityCategory> categories;
  final Map<String, SexualActivity> activitiesMap;
  final Set<String> selectedKeys; // format: "categoryId:activityId"

  const ActivityFilterDialog({
    super.key,
    required this.categories,
    required this.activitiesMap,
    required this.selectedKeys,
  });

  @override
  State<ActivityFilterDialog> createState() => _ActivityFilterDialogState();
}

class _ActivityFilterDialogState extends State<ActivityFilterDialog> {
  late Set<String> _selectedKeys;
  // Keep track of expanded categories
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _selectedKeys = Set.from(widget.selectedKeys);
    // Auto-expand categories that have selected items
    for (var key in _selectedKeys) {
      final parts = key.split(':');
      if (parts.isNotEmpty) {
        _expandedCategories.add(parts[0]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort categories alphabetically by name
    final sortedCategories = List<SexualActivityCategory>.from(
      widget.categories,
    )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return AlertDialog(
      title: const Text('Filter by Specific Activities'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: sortedCategories.map((category) {
            final categoryId = category.id;
            // Get activities for this category and sort alphabetically
            final activities =
                category.activities
                    .map((ref) => widget.activitiesMap[ref.reference])
                    .whereType<SexualActivity>()
                    .toList()
                  ..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );

            if (activities.isEmpty) return const SizedBox.shrink();

            final isExpanded = _expandedCategories.contains(categoryId);

            // Check how many items selected in this category
            final selectedCount = activities.where((a) {
              return _selectedKeys.contains("$categoryId:${a.id}");
            }).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: selectedCount > 0
                      ? Text(
                          '$selectedCount selected',
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                  leading: Text(
                    category.displayCharacter ?? '❔',
                    style: const TextStyle(fontSize: 24),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedCategories.remove(categoryId);
                      } else {
                        _expandedCategories.add(categoryId);
                      }
                    });
                  },
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      children: activities.map((activity) {
                        final compositeKey = "$categoryId:${activity.id}";
                        final isSelected = _selectedKeys.contains(compositeKey);

                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Text(
                                activity.displayCharacter,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(activity.name)),
                              if (activity.stiRisk || activity.healthRisk) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.warning,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                              ],
                            ],
                          ),
                          value: isSelected,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedKeys.add(compositeKey);
                              } else {
                                _selectedKeys.remove(compositeKey);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                const Divider(),
              ],
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
              _selectedKeys.clear();
            });
          },
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedKeys),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
