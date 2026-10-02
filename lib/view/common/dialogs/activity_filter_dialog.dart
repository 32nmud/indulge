import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

class ActivityFilterDialog extends StatefulWidget {
  /// Full map of all categories (needed to resolve parent/child relationships).
  final Map<String, SexualActivityCategory> categoriesMap;
  final Set<String> selectedKeys; // format: "categoryId:activityName"

  const ActivityFilterDialog({
    super.key,
    required this.categoriesMap,
    required this.selectedKeys,
  });

  @override
  State<ActivityFilterDialog> createState() => _ActivityFilterDialogState();
}

class _ActivityFilterDialogState extends State<ActivityFilterDialog> {
  late Set<String> _selectedKeys;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedKeys = Set.from(widget.selectedKeys);
    // Auto-expand categories that already have selections.
    for (final key in _selectedKeys) {
      final colon = key.indexOf(':');
      if (colon > 0) _expandedIds.add(key.substring(0, colon));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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

  List<SexualActivity> _sortedActivities(SexualActivityCategory cat) {
    return List<SexualActivity>.from(cat.activities)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Composite key for an activity owned by [categoryId].
  String _key(String categoryId, String activityName) =>
      '$categoryId:$activityName';

  /// All composite keys for activities in [cat] and its subcategories.
  Set<String> _allKeysFor(SexualActivityCategory cat) {
    final keys = <String>{};
    for (final act in cat.activities) {
      keys.add(_key(cat.id, act.name));
    }
    for (final sub in _subsOf(cat)) {
      for (final act in sub.activities) {
        keys.add(_key(sub.id, act.name));
      }
    }
    return keys;
  }

  bool _allSelectedFor(SexualActivityCategory cat) {
    final keys = _allKeysFor(cat);
    return keys.isNotEmpty && keys.every((k) => _selectedKeys.contains(k));
  }

  bool _anySelectedFor(SexualActivityCategory cat) =>
      _allKeysFor(cat).any((k) => _selectedKeys.contains(k));

  int _selectedCountFor(SexualActivityCategory cat) =>
      _allKeysFor(cat).where((k) => _selectedKeys.contains(k)).length;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subcatIds = _subcategoryIds;
    final topLevel = _topLevel(subcatIds);

    // Only show categories (or subcategories) that have at least one activity.
    final visible = topLevel.where((cat) {
      if (cat.activities.isNotEmpty) return true;
      return _subsOf(cat).any((sub) => sub.activities.isNotEmpty);
    }).toList();

    return AlertDialog(
      title: const Text('Filter by Activities'),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: visible.length,
          itemBuilder: (context, i) => _buildParentSection(visible[i]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => setState(() => _selectedKeys.clear()),
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedKeys),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildParentSection(SexualActivityCategory cat) {
    final subs = _subsOf(cat);
    final isExpanded = _expandedIds.contains(cat.id);
    final selectedCount = _selectedCountFor(cat);
    final allSel = _allSelectedFor(cat);
    final anySel = _anySelectedFor(cat);
    final scheme = Theme.of(context).colorScheme;

    // Flat activities directly on this parent (only shown when no subcategories
    // or when the parent itself has activities alongside subcategories).
    final directActivities = _sortedActivities(cat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category header row ──────────────────────────────────────
        InkWell(
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedIds.remove(cat.id);
            } else {
              _expandedIds.add(cat.id);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Tri-state checkbox: filled=all, dash=some, empty=none
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: allSel ? true : (anySel ? null : false),
                    tristate: true,
                    visualDensity: VisualDensity.compact,
                    onChanged: (_) {
                      final all = _allKeysFor(cat);
                      setState(() {
                        if (allSel) {
                          _selectedKeys.removeAll(all);
                        } else {
                          _selectedKeys.addAll(all);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  cat.displayCharacter ?? '❔',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (selectedCount > 0)
                        Text(
                          '$selectedCount selected',
                          style: TextStyle(fontSize: 11, color: scheme.primary),
                        ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: scheme.outline,
                ),
              ],
            ),
          ),
        ),

        // ── Expanded content ─────────────────────────────────────────
        if (isExpanded) ...[
          // Direct activities (when parent has its own activities)
          if (directActivities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                children: directActivities
                    .map((act) => _buildActivityTile(cat.id, act))
                    .toList(),
              ),
            ),

          // Subcategory sections
          ...subs
              .where((sub) => sub.activities.isNotEmpty)
              .map((sub) => _buildSubSection(cat, sub)),
        ],

        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSubSection(
    SexualActivityCategory parent,
    SexualActivityCategory sub,
  ) {
    final activities = _sortedActivities(sub);
    final subKeys = activities.map((a) => _key(sub.id, a.name)).toSet();
    final allSel = subKeys.every((k) => _selectedKeys.contains(k));
    final anySel = subKeys.any((k) => _selectedKeys.contains(k));
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subcategory header
          InkWell(
            onTap: () {
              setState(() {
                if (allSel) {
                  _selectedKeys.removeAll(subKeys);
                } else {
                  _selectedKeys.addAll(subKeys);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: allSel ? true : (anySel ? null : false),
                      tristate: true,
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) {
                        setState(() {
                          if (allSel) {
                            _selectedKeys.removeAll(subKeys);
                          } else {
                            _selectedKeys.addAll(subKeys);
                          }
                        });
                      },
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Activities under this subcategory
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: activities
                  .map((act) => _buildActivityTile(sub.id, act))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(String categoryId, SexualActivity activity) {
    final compositeKey = _key(categoryId, activity.name);
    final isSelected = _selectedKeys.contains(compositeKey);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedKeys.remove(compositeKey);
        } else {
          _selectedKeys.add(compositeKey);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isSelected,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => setState(() {
                  if (isSelected) {
                    _selectedKeys.remove(compositeKey);
                  } else {
                    _selectedKeys.add(compositeKey);
                  }
                }),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              activity.displayCharacter,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activity.name,
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
              ),
            ),
            if (activity.stiRisk)
              Tooltip(
                message: 'STI Risk',
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.purple.shade700,
                ),
              )
            else if (activity.healthRisk)
              Tooltip(
                message: 'Health Risk',
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
