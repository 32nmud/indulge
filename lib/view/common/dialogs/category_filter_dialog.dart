import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

class CategoryFilterDialog extends StatefulWidget {
  /// Full map of all categories (needed to resolve parent/child relationships).
  final Map<String, SexualActivityCategory> categoriesMap;
  final Set<String> selectedIds;
  final bool singleSelect;

  const CategoryFilterDialog({
    super.key,
    required this.categoriesMap,
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// IDs that appear as a subcategory of any other category.
  Set<String> get _subcategoryIds {
    final ids = <String>{};
    for (final cat in widget.categoriesMap.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) ids.add(ref.reference);
      }
    }
    return ids;
  }

  /// Top-level categories sorted by sortOrder.
  List<SexualActivityCategory> _topLevel(Set<String> subcatIds) {
    return widget.categoriesMap.values
        .where((c) => !subcatIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Subcategories of [parent] in declaration order.
  List<SexualActivityCategory> _subsOf(SexualActivityCategory parent) {
    return parent.subCategories
        .where((r) => r.reference.isNotEmpty)
        .map((r) => widget.categoriesMap[r.reference])
        .whereType<SexualActivityCategory>()
        .toList();
  }

  /// All IDs covered by selecting [cat] (itself + all its subcategories).
  Set<String> _coveredIds(SexualActivityCategory cat) {
    final ids = {cat.id};
    for (final sub in _subsOf(cat)) {
      ids.add(sub.id);
    }
    return ids;
  }

  /// True if [cat] or any of its subcategories is selected.
  bool _anySelected(SexualActivityCategory cat) =>
      _coveredIds(cat).any((id) => _selectedIds.contains(id));

  /// True if [cat] AND all its subcategories are selected.
  bool _allSelected(SexualActivityCategory cat) =>
      _coveredIds(cat).every((id) => _selectedIds.contains(id));

  void _toggleParent(SexualActivityCategory cat) {
    final covered = _coveredIds(cat);
    setState(() {
      if (_allSelected(cat)) {
        // Deselect parent + all subcategories.
        _selectedIds.removeAll(covered);
      } else {
        if (widget.singleSelect) {
          _selectedIds
            ..clear()
            ..addAll(covered);
        } else {
          _selectedIds.addAll(covered);
        }
      }
    });
  }

  void _toggleSub(SexualActivityCategory sub) {
    setState(() {
      if (_selectedIds.contains(sub.id)) {
        _selectedIds.remove(sub.id);
      } else {
        if (widget.singleSelect) {
          _selectedIds
            ..clear()
            ..add(sub.id);
        } else {
          _selectedIds.add(sub.id);
        }
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subcatIds = _subcategoryIds;
    final topLevel = _topLevel(subcatIds);

    return AlertDialog(
      title: const Text('Filter by Categories'),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: topLevel.length,
          itemBuilder: (context, i) => _buildParentTile(topLevel[i]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => setState(() => _selectedIds.clear()),
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildParentTile(SexualActivityCategory cat) {
    final subs = _subsOf(cat);
    final allSel = _allSelected(cat);
    final anySel = _anySelected(cat);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Parent row ────────────────────────────────────────────────
        InkWell(
          onTap: () => _toggleParent(cat),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Checkbox — tristate: filled if all selected, dash if some
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: allSel ? true : (anySel ? null : false),
                    tristate: true,
                    onChanged: (_) => _toggleParent(cat),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  cat.displayCharacter ?? '❔',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (subs.isNotEmpty)
                  Icon(
                    Icons.account_tree_outlined,
                    size: 15,
                    color: scheme.outline,
                  ),
              ],
            ),
          ),
        ),

        // ── Subcategory rows (indented) ───────────────────────────────
        if (subs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: subs.map((sub) => _buildSubTile(sub)).toList(),
            ),
          ),

        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSubTile(SexualActivityCategory sub) {
    final isSelected = _selectedIds.contains(sub.id);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _toggleSub(sub),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSub(sub),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              sub.displayCharacter ?? '❔',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sub.name,
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
