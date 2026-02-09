import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/settings/activity_type_editor_page.dart';

class ActivityTypeListPage extends StatefulWidget {
  const ActivityTypeListPage({super.key});

  @override
  State<ActivityTypeListPage> createState() => _ActivityTypeListPageState();
}

class _ActivityTypeListPageState extends State<ActivityTypeListPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SexualEventsProvider>();
    final activityTypes =
        provider.state.sexualActivityTypes?.values.toList() ?? [];

    // Sort alphabetically
    activityTypes.sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Activity Types'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const ActivityTypeEditorPage(),
            ),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
      body: activityTypes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No activity types found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: activityTypes.length,
              itemBuilder: (context, index) {
                final activityType = activityTypes[index];
                final propertyCount = activityType.properties.length;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Text(
                      activityType.displayCharacter ?? '❓',
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(activityType.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (propertyCount > 0)
                          Chip(
                            label: Text(
                              '$propertyCount ${propertyCount == 1 ? 'property' : 'properties'}',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(context, activityType),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityTypeEditorPage(
                            activityType: activityType,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SexualActivityType activityType,
  ) async {
    final provider = context.read<SexualEventsProvider>();

    // Check if this activity type is used in any events
    final isUsed = await provider.isActivityTypeUsed(activityType.id);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity Type?'),
        content: Text(
          isUsed
              ? 'This activity type is used in existing events. Deleting it will remove it from all events. This action cannot be undone.'
              : 'Are you sure you want to delete "${activityType.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await provider.deleteActivityType(activityType.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${activityType.name} deleted')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
