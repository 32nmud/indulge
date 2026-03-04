import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

/// A reusable hierarchical category picker dialog.
///
/// Shows parent categories with optional tri-state checkboxes (checked,
/// indeterminate, unchecked) and expands to show subcategories indented
/// beneath each parent.
///
/// Returns the final [Set<String>] of selected category IDs via
/// [Navigator.pop], or `null` if the user cancels.
///
/// Usage:
/// ```dart
/// final result = await showDialog<Set<String>>(
///   context: context,
///   builder: (_) => CategoryPickerDialog(
///     categoriesMap: allCategoriesMap,
///     selectedIds: currentSelection,
///   ),
/// );
/// if (result != null) { /* apply */ }
/// ```
class CategoryPickerDialog extends StatefulWidget {
  /// Full map of categories (parents and subcategories) keyed by ID.
  final Map<String, SexualActivityCategory> categoriesMap;

  /// The currently selected IDs — the dialog starts with these pre-ticked.
  final Set<String> selectedIds;

  /// Optional dialog title. Defaults to "Select Categories".
  final String title;

  const CategoryPickerDialog({
    super.key,
    required this.categoriesMap,
    required this.selectedIds,
    this.title = 'Select Categories',
  });

  @override
  State<CategoryPickerDialog> createState() => _CategoryPickerDialogState();
}

class _CategoryPickerDialogState extends State<CategoryPickerDialog> {
  late Set<String> _selected;

  // ── Hierarchy helpers ────────────────────────────────────────────────────

  Set<String> get _subcategoryIds {
    final ids = <String>{};
    for (final cat in widget.categoriesMap.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) ids.add(ref.reference);
      }
    }
    return ids;
  }

  List<SexualActivityCategory> _topLevel(Set<String> subcatIds) {
    return widget.categoriesMap.values
        .where((c) => !subcatIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<SexualActivityCategory> _subsOf(SexualActivityCategory parent) {
    return parent.subCategories
        .where((r) => r.reference.isNotEmpty)
        .map((r) => widget.categoriesMap[r.reference])
        .whereType<SexualActivityCategory>()
        .toList();
  }

  /// All IDs covered by [cat] (the parent itself plus all direct subcategory IDs).
  Set<String> _coveredIds(SexualActivityCategory cat) {
    final ids = <String>{cat.id};
    for (final sub in _subsOf(cat)) {
      ids.add(sub.id);
    }
    return ids;
  }

  bool _allSelected(SexualActivityCategory cat) =>
      _coveredIds(cat).every((id) => _selected.contains(id));

  bool _anySelected(SexualActivityCategory cat) =>
      _coveredIds(cat).any((id) => _selected.contains(id));

  void _toggleParent(SexualActivityCategory cat) {
    final covered = _coveredIds(cat);
    setState(() {
      if (_allSelected(cat)) {
        _selected.removeAll(covered);
      } else {
        _selected.addAll(covered);
      }
    });
  }

  void _toggleSub(String subId) {
    setState(() {
      if (_selected.contains(subId)) {
        _selected.remove(subId);
      } else {
        _selected.add(subId);
      }
    });
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedIds);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subcatIds = _subcategoryIds;
    final topLevel = _topLevel(subcatIds);

    return AlertDialog(
      title: Text(widget.title),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => setState(() => _selected.clear()),
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, Set<String>.from(_selected)),
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
        InkWell(
          onTap: () => _toggleParent(cat),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: allSel ? true : (anySel ? null : false),
                    tristate: true,
                    visualDensity: VisualDensity.compact,
                    onChanged: (_) => _toggleParent(cat),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  cat.displayCharacter ?? '❔',
                  style: const TextStyle(fontSize: 22),
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
                    size: 14,
                    color: scheme.outline,
                  ),
              ],
            ),
          ),
        ),
        if (subs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: subs.map((sub) {
                final isSelected = _selected.contains(sub.id);
                return InkWell(
                  onTap: () => _toggleSub(sub.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: isSelected,
                            visualDensity: VisualDensity.compact,
                            onChanged: (_) => _toggleSub(sub.id),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          sub.displayCharacter ?? '❔',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}
