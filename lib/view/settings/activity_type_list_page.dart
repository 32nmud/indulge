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
    final activityCategories =
        provider.state.sexualActivityCategories?.values.toList() ?? [];

    // Sort alphabetically
    activityCategories.sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Activity Categories'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'activity_categories_add_fab',
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
      body: activityCategories.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No categories found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: activityCategories.length,
              itemBuilder: (context, index) {
                final activityCategory = activityCategories[index];
                final activityCount = activityCategory.activities.length;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Text(
                      activityCategory.displayCharacter ?? '❓',
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            activityCategory.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (activityCategory.requiresPartner) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.group, size: 16, color: Colors.blue),
                        ],
                      ],
                    ),
                    subtitle: activityCategory.requiresPartner
                        ? const Text(
                            'Requires partner',
                            style: TextStyle(fontSize: 11, color: Colors.blue),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (activityCount > 0)
                          Chip(
                            label: Text(
                              '$activityCount ${activityCount == 1 ? 'activity' : 'activities'}',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(context, activityCategory),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityTypeEditorPage(
                            activityCategory: activityCategory,
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
    SexualActivityCategory activityCategory,
  ) async {
    final provider = context.read<SexualEventsProvider>();

    // Check if this activity category is used in any events
    final isUsed = await provider.isActivityCategoryUsed(activityCategory.id);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          isUsed
              ? 'This category is used in existing events. Deleting it will remove it from all events. This action cannot be undone.'
              : 'Are you sure you want to delete "${activityCategory.name}"?',
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
        await provider.deleteActivityCategory(activityCategory.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${activityCategory.name} deleted')),
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
