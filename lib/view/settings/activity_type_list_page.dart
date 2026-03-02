import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/reorder_buttons.dart';
import 'package:indulge/view/settings/activity_type_editor_page.dart';

class ActivityTypeListPage extends StatefulWidget {
  const ActivityTypeListPage({super.key});

  @override
  State<ActivityTypeListPage> createState() => _ActivityTypeListPageState();
}

class _ActivityTypeListPageState extends State<ActivityTypeListPage> {
  // Local ordering of top-level IDs. null = use store sort order.
  List<String>? _orderedTopLevelIds;

  // ── helpers ──────────────────────────────────────────────────────────────

  List<SexualActivityCategory> _resolveTopLevel(
    Map<String, SexualActivityCategory> allCategories,
    Set<String> subcategoryIds,
  ) {
    if (_orderedTopLevelIds != null) {
      final known = _orderedTopLevelIds!
          .where(
            (id) =>
                allCategories.containsKey(id) && !subcategoryIds.contains(id),
          )
          .toList();
      final added = allCategories.values
          .where((c) => !subcategoryIds.contains(c.id) && !known.contains(c.id))
          .map((c) => c.id)
          .toList();
      return [...known, ...added].map((id) => allCategories[id]!).toList();
    }
    return allCategories.values
        .where((c) => !subcategoryIds.contains(c.id))
        .toList()
      ..sort((a, b) {
        final cmp = a.sortOrder.compareTo(b.sortOrder);
        return cmp != 0 ? cmp : a.name.compareTo(b.name);
      });
  }

  Future<void> _moveCategory(
    int from,
    int to,
    List<SexualActivityCategory> topLevel,
  ) async {
    final updated = List<SexualActivityCategory>.from(topLevel);
    final moved = updated.removeAt(from);
    updated.insert(to, moved);

    setState(() {
      _orderedTopLevelIds = updated.map((c) => c.id).toList();
    });

    final provider = context.read<SexualEventsProvider>();
    for (var i = 0; i < updated.length; i++) {
      final cat = updated[i];
      if (cat.sortOrder != i) {
        await provider.saveActivityCategory(cat.copyWith(sortOrder: i));
      }
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EventStateStore>();
    final allCategories = Map<String, SexualActivityCategory>.from(
      store.state.sexualActivityCategories ?? {},
    );

    final subcategoryIds = <String>{};
    for (final cat in allCategories.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) subcategoryIds.add(ref.reference);
      }
    }

    final topLevel = _resolveTopLevel(allCategories, subcategoryIds);

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
          if (result == true && mounted) setState(() {});
        },
        child: const Icon(Icons.add),
      ),
      body: topLevel.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create your first category',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: topLevel.length,
              itemBuilder: (context, index) {
                final category = topLevel[index];
                final subcats = category.subCategories
                    .where((r) => r.reference.isNotEmpty)
                    .map((r) => allCategories[r.reference])
                    .whereType<SexualActivityCategory>()
                    .toList();

                return _CategoryGroup(
                  key: ValueKey(category.id),
                  category: category,
                  subcategories: subcats,
                  isFirst: index == 0,
                  isLast: index == topLevel.length - 1,
                  positionIndex: index,
                  onMoveUp: index == 0
                      ? null
                      : () => _moveCategory(index, index - 1, topLevel),
                  onMoveDown: index == topLevel.length - 1
                      ? null
                      : () => _moveCategory(index, index + 1, topLevel),
                  onEdit: (cat) => _openEditor(context, cat),
                  onDelete: (cat) => _confirmDelete(context, cat),
                );
              },
            ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    SexualActivityCategory category,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityTypeEditorPage(activityCategory: category),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SexualActivityCategory category,
  ) async {
    final provider = context.read<SexualEventsProvider>();
    final count = await provider.getUsageCountForCategory(category.id);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          count > 0
              ? '"${category.name}" is used in $count existing '
                    'event${count == 1 ? '' : 's'}. Deleting it will remove it '
                    'from all of them. This cannot be undone.'
              : 'Delete "${category.name}"? This cannot be undone.',
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
        await provider.deleteActivityCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('"${category.name}" deleted')));
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

// ─────────────────────────────────────────────────────────────────────────────
// _CategoryGroup
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryGroup extends StatelessWidget {
  final SexualActivityCategory category;
  final List<SexualActivityCategory> subcategories;
  final bool isFirst;
  final bool isLast;
  final int positionIndex;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final void Function(SexualActivityCategory) onEdit;
  final void Function(SexualActivityCategory) onDelete;

  const _CategoryGroup({
    super.key,
    required this.category,
    required this.subcategories,
    required this.isFirst,
    required this.isLast,
    required this.positionIndex,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Up / down buttons for the whole group
          ReorderButtons(
            isFirst: isFirst,
            isLast: isLast,
            onUp: onMoveUp ?? () {},
            onDown: onMoveDown ?? () {},
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Parent category tile ──
                _CategoryTile(
                  category: category,
                  isSubcategory: false,
                  positionIndex: positionIndex,
                  onEdit: () => onEdit(category),
                  onDelete: () => onDelete(category),
                ),

                // ── Subcategories indented beneath ──
                if (subcategories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: subcategories.map((sub) {
                        final subIndex = subcategories.indexOf(sub);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 20,
                                child: CustomPaint(
                                  painter: _ConnectorPainter(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                    isLast: sub == subcategories.last,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _CategoryTile(
                                  category: sub,
                                  isSubcategory: true,
                                  positionIndex: subIndex,
                                  onEdit: () => onEdit(sub),
                                  onDelete: () => onDelete(sub),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CategoryTile
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final SexualActivityCategory category;
  final bool isSubcategory;
  final int positionIndex;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.isSubcategory,
    required this.positionIndex,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final activityCount = category.activities.length;
    final subcatCount = category.subCategories
        .where((r) => r.reference.isNotEmpty)
        .length;

    return Card(
      margin: EdgeInsets.zero,
      elevation: isSubcategory ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSubcategory
            ? BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              )
            : BorderSide.none,
      ),
      color: isSubcategory
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Emoji
              SizedBox(
                width: 44,
                child: Text(
                  category.displayCharacter ?? '❔',
                  style: TextStyle(fontSize: isSubcategory ? 26 : 32),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              // Name + badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: isSubcategory ? 14 : 16,
                              fontWeight: isSubcategory
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (category.requiresPartner) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Requires partner',
                            child: Icon(
                              Icons.group,
                              size: 15,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (activityCount > 0)
                          _SmallChip(
                            label:
                                '$activityCount ${activityCount == 1 ? 'activity' : 'activities'}',
                          ),
                        if (subcatCount > 0)
                          _SmallChip(
                            label:
                                '$subcatCount ${subcatCount == 1 ? 'subcategory' : 'subcategories'}',
                            icon: Icons.account_tree_outlined,
                          ),
                        _SmallChip(label: '#${positionIndex + 1}'),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _SmallChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the ├─ / └─ tree connector line to the left of a subcategory tile.
class _ConnectorPainter extends CustomPainter {
  final Color color;
  final bool isLast;

  const _ConnectorPainter({required this.color, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final midX = size.width * 0.5;
    final midY = size.height * 0.5;

    canvas.drawLine(
      Offset(midX, 0),
      Offset(midX, isLast ? midY : size.height),
      paint,
    );
    canvas.drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.color != color || old.isLast != isLast;
}
