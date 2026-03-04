import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/services/preferences_service.dart';

import '../../models/analysis_event_type.dart';
import '../../models/activity_breakdown_data.dart';
import '../../models/co_occurance_pair.dart';

class CoOccurrenceSection extends StatefulWidget {
  final ActivityBreakdownData data;
  final AnalysisEventType? filterType;

  const CoOccurrenceSection({super.key, required this.data, this.filterType});

  @override
  State<CoOccurrenceSection> createState() => _CoOccurrenceSectionState();
}

class _CoOccurrenceSectionState extends State<CoOccurrenceSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Composite keys (catId:activityName) excluded from the Activities tab.
  final Set<String> _excludedActivityKeys = {};

  /// Category IDs excluded from the Categories tab — parent mode.
  final Set<String> _excludedCategoryIdsParent = {};

  /// Category IDs excluded from the Categories tab — subcategory mode.
  final Set<String> _excludedCategoryIdsSubcategory = {};

  /// Whether the Categories tab shows subcategories (true) or parent
  /// categories (false, default).
  bool _useSubcategories = false;

  /// Whether we've loaded persisted exclusions from PreferencesService yet.
  bool _prefsLoaded = false;

  // ── Lazy pair caches ─────────────────────────────────────────────────────
  // Pairs are expensive to recompute on every build (O(events²) in the worst
  // case).  Instead, we compute them on demand and cache the result.  The
  // cache is invalidated whenever any exclusion set or the grouping toggle
  // changes so that the next build transparently recomputes.

  List<CoOccurrencePair>? _cachedCategoryPairs;
  List<CoOccurrencePair>? _cachedActivityPairs;

  List<CoOccurrencePair> get _categoryPairs {
    return _cachedCategoryPairs ??= _getPairs(true);
  }

  List<CoOccurrencePair> get _activityPairs {
    return _cachedActivityPairs ??= _getPairs(false);
  }

  void _invalidatePairCache({
    bool invalidateCategories = true,
    bool invalidateActivities = true,
  }) {
    if (invalidateCategories) _cachedCategoryPairs = null;
    if (invalidateActivities) _cachedActivityPairs = null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefsLoaded) {
      _prefsLoaded = true;
      _loadPersistedExclusions();
    }
  }

  void _loadPersistedExclusions() {
    try {
      final prefs = Provider.of<PreferencesService>(context, listen: false);
      final activityKeys = prefs.getCoOccurrenceExcludedActivityKeys();
      final categoryIdsParent = prefs
          .getCoOccurrenceExcludedCategoryIdsParent();
      final categoryIdsSubcategory = prefs
          .getCoOccurrenceExcludedCategoryIdsSubcategory();
      if (activityKeys.isNotEmpty ||
          categoryIdsParent.isNotEmpty ||
          categoryIdsSubcategory.isNotEmpty) {
        setState(() {
          _excludedActivityKeys.addAll(activityKeys);
          _excludedCategoryIdsParent.addAll(categoryIdsParent);
          _excludedCategoryIdsSubcategory.addAll(categoryIdsSubcategory);
        });
      }
    } catch (_) {
      // PreferencesService not available — silently ignore.
    }
  }

  Future<void> _persistExclusions() async {
    try {
      final prefs = Provider.of<PreferencesService>(context, listen: false);
      await prefs.setCoOccurrenceExcludedActivityKeys(
        _excludedActivityKeys.toList(),
      );
      await prefs.setCoOccurrenceExcludedCategoryIdsParent(
        _excludedCategoryIdsParent.toList(),
      );
      await prefs.setCoOccurrenceExcludedCategoryIdsSubcategory(
        _excludedCategoryIdsSubcategory.toList(),
      );
    } catch (_) {
      // PreferencesService not available — silently ignore.
    }
  }

  void _handleTabSelection() {
    // No cache invalidation needed on tab switch — caches remain valid.
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  // ── Category hierarchy helpers ────────────────────────────────────────────

  /// IDs that are referenced as a subcategory of any other category.
  Set<String> get _subcategoryIds {
    final ids = <String>{};
    for (final cat in widget.data.allCategoriesMap.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) ids.add(ref.reference);
      }
    }
    return ids;
  }

  // ── Pair computation ──────────────────────────────────────────────────────

  /// Returns the active excluded-category set for the current mode.
  Set<String> get _activeCategoryExclusions => _useSubcategories
      ? _excludedCategoryIdsSubcategory
      : _excludedCategoryIdsParent;

  List<CoOccurrencePair> _getPairs(bool categories) {
    final events = widget.filterType == null
        ? widget.data.events
        : (widget.data.eventsByType[widget.filterType!] ?? []);

    final pairCounts = <String, int>{};

    for (final event in events) {
      final ids = <String>{};
      if (categories) {
        if (_useSubcategories) {
          // Subcategory mode: collect the unique set of categoryReference IDs
          // from ActivityCount records — these carry the subcategory ID that
          // was actually selected when the activity was logged.
          for (final activity in event.activities) {
            for (final participant in activity.participants) {
              for (final ac in participant.activityCounts) {
                final id = ac.categoryReference.reference;
                if (id.isNotEmpty &&
                    !_excludedCategoryIdsSubcategory.contains(id)) {
                  ids.add(id);
                }
              }
            }
          }
        } else {
          // Parent mode: use EventActivity.category.reference, which is the
          // top-level category the user chose for the activity block.
          for (final activity in event.activities) {
            final id = activity.category.reference;
            if (!_excludedCategoryIdsParent.contains(id)) ids.add(id);
          }
        }
      } else {
        for (final activity in event.activities) {
          for (final participant in activity.participants) {
            for (final count in participant.activityCounts) {
              final key =
                  '${count.categoryReference.reference}:${count.activityName}';
              if (!_excludedActivityKeys.contains(key)) ids.add(key);
            }
          }
        }
      }

      final idList = ids.toList()..sort();
      for (int i = 0; i < idList.length; i++) {
        for (int j = i + 1; j < idList.length; j++) {
          final key = '${idList[i]}|${idList[j]}';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        }
      }
    }

    final pairs = pairCounts.entries.map((e) {
      final parts = e.key.split('|');
      final id1 = parts[0];
      final id2 = parts[1];

      // Look up category name + emoji from both maps.
      String _catLabel(String id) {
        final cat =
            widget.data.allCategoriesMap[id] ??
            widget.data.activityCategories[id];
        if (cat == null) return 'Unknown';
        final emoji = (cat.displayCharacter?.isNotEmpty == true)
            ? '${cat.displayCharacter} '
            : '';
        return '$emoji${cat.name}';
      }

      // Look up activity name + emoji.
      String _actLabel(String key) {
        final act = widget.data.sexualActivities[key];
        if (act != null) {
          final emoji = act.displayCharacter.isNotEmpty
              ? '${act.displayCharacter} '
              : '';
          return '$emoji${act.name}';
        }
        return key.contains(':') ? key.split(':').last : 'Unknown';
      }

      final name1 = categories ? _catLabel(id1) : _actLabel(id1);
      final name2 = categories ? _catLabel(id2) : _actLabel(id2);

      return CoOccurrencePair(
        id1: id1,
        id2: id2,
        name1: name1,
        name2: name2,
        count: e.value,
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));

    return pairs;
  }

  // ── Activity key helpers ──────────────────────────────────────────────────

  /// Returns a de-duplicated set of composite keys seen across all events.
  Set<String> _allSeenActivityKeys() {
    final keys = <String>{};
    for (final event in widget.data.events) {
      for (final activity in event.activities) {
        for (final participant in activity.participants) {
          for (final count in participant.activityCounts) {
            keys.add(
              '${count.categoryReference.reference}:${count.activityName}',
            );
          }
        }
      }
    }
    return keys;
  }

  // ── Exclude dialogs ───────────────────────────────────────────────────────

  /// Opens the category-exclude dialog.
  /// In parent mode only top-level categories are shown; in subcategory mode
  /// the full hierarchy is available.
  Future<void> _showCategoryExcludeDialog(BuildContext context) async {
    final subcatIds = _subcategoryIds;

    // Build a filtered map: parent mode → only top-level; sub mode → all.
    final Map<String, SexualActivityCategory> dialogMap = _useSubcategories
        ? widget.data.allCategoriesMap
        : Map.fromEntries(
            widget.data.allCategoriesMap.entries.where(
              (e) => !subcatIds.contains(e.key),
            ),
          );

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _CategoryExcludeDialog(
        categoriesMap: dialogMap,
        excludedIds: Set.from(_activeCategoryExclusions),
      ),
    );
    if (result != null) {
      setState(() {
        if (_useSubcategories) {
          _excludedCategoryIdsSubcategory
            ..clear()
            ..addAll(result);
        } else {
          _excludedCategoryIdsParent
            ..clear()
            ..addAll(result);
        }
        _invalidatePairCache(
          invalidateCategories: true,
          invalidateActivities: false,
        );
      });
      _persistExclusions();
    }
  }

  /// Opens the activity-exclude dialog, which groups activities under their
  /// parent categories with emoji and allows individual selection.
  Future<void> _showActivityExcludeDialog(BuildContext context) async {
    final seenKeys = _allSeenActivityKeys();
    if (seenKeys.isEmpty) return;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _ActivityExcludeDialog(
        allCategoriesMap: widget.data.allCategoriesMap,
        sexualActivities: widget.data.sexualActivities,
        seenKeys: seenKeys,
        excludedKeys: Set.from(_excludedActivityKeys),
      ),
    );
    if (result != null) {
      setState(() {
        _excludedActivityKeys
          ..clear()
          ..addAll(result);
        _invalidatePairCache(
          invalidateCategories: false,
          invalidateActivities: true,
        );
      });
      _persistExclusions();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(covariant CoOccurrenceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the underlying event data or filter type changed, all caches are stale.
    if (oldWidget.data != widget.data ||
        oldWidget.filterType != widget.filterType) {
      _invalidatePairCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCategoryTab = _tabController.index == 0;

    // Compute the active tab eagerly; compute the inactive tab lazily only
    // to determine whether we should hide the whole section.
    final categoryPairs = _categoryPairs;
    final activityPairs = _activityPairs;

    if (categoryPairs.isEmpty && activityPairs.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeExcludeCount = isCategoryTab
        ? _activeCategoryExclusions.length
        : _excludedActivityKeys.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.link,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Top Combinations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Filter button with active-count badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      activeExcludeCount > 0
                          ? Icons.filter_list_alt
                          : Icons.filter_list,
                      color: activeExcludeCount > 0
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: 'Exclude noisy items',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (isCategoryTab) {
                        _showCategoryExcludeDialog(context);
                      } else {
                        _showActivityExcludeDialog(context);
                      }
                    },
                  ),
                  if (activeExcludeCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$activeExcludeCount',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Categories'),
              Tab(text: 'Activities'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Parent / subcategory toggle — only visible on the Categories tab
        if (isCategoryTab)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Group by:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Parent'),
                  selected: !_useSubcategories,
                  onSelected: (v) {
                    if (v) {
                      setState(() {
                        _useSubcategories = false;
                        // Grouping change affects which pairs are produced.
                        _invalidatePairCache(
                          invalidateCategories: true,
                          invalidateActivities: false,
                        );
                      });
                    }
                  },
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: !_useSubcategories
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Subcategory'),
                  selected: _useSubcategories,
                  onSelected: (v) {
                    if (v) {
                      setState(() {
                        _useSubcategories = true;
                        // Grouping change affects which pairs are produced.
                        _invalidatePairCache(
                          invalidateCategories: true,
                          invalidateActivities: false,
                        );
                      });
                    }
                  },
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: _useSubcategories
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Pair list for the active tab only.
        isCategoryTab
            ? _buildPairList(categoryPairs, Colors.teal)
            : _buildPairList(activityPairs, Colors.orange),
      ],
    );
  }

  Widget _buildPairList(List<CoOccurrencePair> pairs, Color color) {
    if (pairs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: Text(
            'No combinations found.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final displayPairs = pairs.take(10).toList();
    final maxCount = displayPairs.first.count;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayPairs.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemBuilder: (context, index) {
        final pair = displayPairs[index];
        final ratio = pair.count / maxCount;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: pair.name1,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: ' + ',
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          TextSpan(
                            text: pair.name2,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '${pair.count}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Category exclude dialog ────────────────────────────────────────────────
//
// Wraps [CategoryFilterDialog] semantics but with "exclude" framing:
// the user picks categories to EXCLUDE from pair counting.
// Internally we just show the CategoryFilterDialog with the current excluded
// IDs as the "selected" set, then return whatever was selected as the new
// excluded set.

class _CategoryExcludeDialog extends StatefulWidget {
  final Map<String, SexualActivityCategory> categoriesMap;
  final Set<String> excludedIds;

  const _CategoryExcludeDialog({
    required this.categoriesMap,
    required this.excludedIds,
  });

  @override
  State<_CategoryExcludeDialog> createState() => _CategoryExcludeDialogState();
}

class _CategoryExcludeDialogState extends State<_CategoryExcludeDialog> {
  late Set<String> _excludedIds;

  @override
  void initState() {
    super.initState();
    _excludedIds = Set.from(widget.excludedIds);
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

  Set<String> _coveredIds(SexualActivityCategory cat) {
    final ids = {cat.id};
    for (final sub in _subsOf(cat)) {
      ids.add(sub.id);
    }
    return ids;
  }

  bool _anyExcluded(SexualActivityCategory cat) =>
      _coveredIds(cat).any((id) => _excludedIds.contains(id));

  bool _allExcluded(SexualActivityCategory cat) =>
      _coveredIds(cat).every((id) => _excludedIds.contains(id));

  void _toggleParent(SexualActivityCategory cat) {
    final covered = _coveredIds(cat);
    setState(() {
      if (_allExcluded(cat)) {
        _excludedIds.removeAll(covered);
      } else {
        _excludedIds.addAll(covered);
      }
    });
  }

  void _toggleSub(SexualActivityCategory sub) {
    setState(() {
      if (_excludedIds.contains(sub.id)) {
        _excludedIds.remove(sub.id);
      } else {
        _excludedIds.add(sub.id);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subcatIds = _subcategoryIds;
    final topLevel = _topLevel(subcatIds);

    return AlertDialog(
      title: const Text('Exclude Categories'),
      titleTextStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Checked categories will be excluded from pair counting.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            height: 360,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: topLevel.length,
              itemBuilder: (_, i) => _buildParentTile(topLevel[i]),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => setState(() => _excludedIds.clear()),
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_excludedIds),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildParentTile(SexualActivityCategory cat) {
    final subs = _subsOf(cat);
    final allExcl = _allExcluded(cat);
    final anyExcl = _anyExcluded(cat);
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
                    value: allExcl ? true : (anyExcl ? null : false),
                    tristate: true,
                    onChanged: (_) => _toggleParent(cat),
                    visualDensity: VisualDensity.compact,
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
            child: Column(children: subs.map(_buildSubTile).toList()),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSubTile(SexualActivityCategory sub) {
    final isExcluded = _excludedIds.contains(sub.id);
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
                value: isExcluded,
                onChanged: (_) => _toggleSub(sub),
                visualDensity: VisualDensity.compact,
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
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity exclude dialog ────────────────────────────────────────────────
//
// Shows activities grouped under their parent categories. Each activity row
// shows its displayCharacter emoji and name. The user checks activities to
// EXCLUDE from pair counting.

class _ActivityExcludeDialog extends StatefulWidget {
  final Map<String, SexualActivityCategory> allCategoriesMap;
  final Map<String, SexualActivity> sexualActivities;

  /// Composite keys (catId:activityName) that appear in the event data.
  final Set<String> seenKeys;

  /// Currently excluded composite keys.
  final Set<String> excludedKeys;

  const _ActivityExcludeDialog({
    required this.allCategoriesMap,
    required this.sexualActivities,
    required this.seenKeys,
    required this.excludedKeys,
  });

  @override
  State<_ActivityExcludeDialog> createState() => _ActivityExcludeDialogState();
}

class _ActivityExcludeDialogState extends State<_ActivityExcludeDialog> {
  late Set<String> _excluded;

  @override
  void initState() {
    super.initState();
    _excluded = Set.from(widget.excludedKeys);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Set<String> get _subcategoryIds {
    final ids = <String>{};
    for (final cat in widget.allCategoriesMap.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) ids.add(ref.reference);
      }
    }
    return ids;
  }

  List<SexualActivityCategory> _topLevel(Set<String> subcatIds) {
    return widget.allCategoriesMap.values
        .where((c) => !subcatIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<SexualActivityCategory> _subsOf(SexualActivityCategory parent) {
    return parent.subCategories
        .where((r) => r.reference.isNotEmpty)
        .map((r) => widget.allCategoriesMap[r.reference])
        .whereType<SexualActivityCategory>()
        .toList();
  }

  /// All seen composite keys whose catId prefix matches [catId].
  List<_ActivityItem> _itemsForCat(String catId) {
    final items = <_ActivityItem>[];
    for (final key in widget.seenKeys) {
      final colonIdx = key.indexOf(':');
      if (colonIdx <= 0) continue;
      if (key.substring(0, colonIdx) != catId) continue;
      final actName = key.substring(colonIdx + 1);
      final fromMap = widget.sexualActivities[key];
      final cat = widget.allCategoriesMap[catId];

      String displayChar = '❔';
      String displayName = actName;
      int sortOrder = 0;

      if (fromMap != null) {
        displayChar = fromMap.displayCharacter.isNotEmpty
            ? fromMap.displayCharacter
            : '❔';
        displayName = fromMap.name.isNotEmpty ? fromMap.name : actName;
        sortOrder = fromMap.sortOrder;
      } else if (cat != null) {
        for (final act in cat.activities) {
          if (act.name == actName) {
            displayChar = act.displayCharacter.isNotEmpty
                ? act.displayCharacter
                : '❔';
            displayName = act.name.isNotEmpty ? act.name : actName;
            sortOrder = act.sortOrder;
            break;
          }
        }
      }

      items.add(
        _ActivityItem(
          compositeKey: key,
          displayCharacter: displayChar,
          name: displayName,
          sortOrder: sortOrder,
        ),
      );
    }
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  /// Keys for an entire category subtree (parent + all subs).
  Set<String> _keysForCatTree(SexualActivityCategory cat) {
    final subs = _subsOf(cat);
    final allCatIds = {cat.id, ...subs.map((s) => s.id)};
    return widget.seenKeys.where((key) {
      final colonIdx = key.indexOf(':');
      if (colonIdx <= 0) return false;
      return allCatIds.contains(key.substring(0, colonIdx));
    }).toSet();
  }

  bool _allExcludedForCat(SexualActivityCategory cat) {
    final keys = _keysForCatTree(cat);
    if (keys.isEmpty) return false;
    return keys.every((k) => _excluded.contains(k));
  }

  bool _anyExcludedForCat(SexualActivityCategory cat) {
    final keys = _keysForCatTree(cat);
    return keys.any((k) => _excluded.contains(k));
  }

  void _toggleCat(SexualActivityCategory cat) {
    final keys = _keysForCatTree(cat);
    setState(() {
      if (_allExcludedForCat(cat)) {
        _excluded.removeAll(keys);
      } else {
        _excluded.addAll(keys);
      }
    });
  }

  void _toggleItem(String compositeKey) {
    setState(() {
      if (_excluded.contains(compositeKey)) {
        _excluded.remove(compositeKey);
      } else {
        _excluded.add(compositeKey);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subcatIds = _subcategoryIds;
    final topLevel = _topLevel(subcatIds);

    // Only show categories that have at least one seen activity key.
    final visibleTopLevel = topLevel.where((cat) {
      return _keysForCatTree(cat).isNotEmpty;
    }).toList();

    return AlertDialog(
      title: const Text('Exclude Activities'),
      titleTextStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Checked activities will be excluded from pair counting.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: visibleTopLevel.length,
              itemBuilder: (_, i) =>
                  _buildCategorySection(visibleTopLevel[i], subcatIds),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => setState(() => _excluded.clear()),
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_excluded),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    SexualActivityCategory cat,
    Set<String> subcatIds,
  ) {
    final subs = _subsOf(cat);
    final allExcl = _allExcludedForCat(cat);
    final anyExcl = _anyExcludedForCat(cat);
    final scheme = Theme.of(context).colorScheme;

    // Direct activities (catId prefix = cat.id, not a subcategory)
    final directItems = _itemsForCat(cat.id);

    // Build sub-section items
    final subSections = subs
        .map((sub) => (sub: sub, items: _itemsForCat(sub.id)))
        .where((pair) => pair.items.isNotEmpty)
        .toList();

    final hasContent = directItems.isNotEmpty || subSections.isNotEmpty;
    if (!hasContent) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category header row ──────────────────────────────────────
        InkWell(
          onTap: () => _toggleCat(cat),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: allExcl ? true : (anyExcl ? null : false),
                    tristate: true,
                    onChanged: (_) => _toggleCat(cat),
                    visualDensity: VisualDensity.compact,
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

        // ── Direct activity rows ─────────────────────────────────────
        if (directItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: directItems
                  .map((item) => _buildActivityTile(item, indent: false))
                  .toList(),
            ),
          ),

        // ── Subcategory sections ─────────────────────────────────────
        for (final pair in subSections) ...[
          _buildSubcategoryHeader(pair.sub, pair.items),
          Padding(
            padding: const EdgeInsets.only(left: 64),
            child: Column(
              children: pair.items
                  .map((item) => _buildActivityTile(item, indent: false))
                  .toList(),
            ),
          ),
        ],

        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSubcategoryHeader(
    SexualActivityCategory sub,
    List<_ActivityItem> items,
  ) {
    final allExcl = items.every((i) => _excluded.contains(i.compositeKey));
    final anyExcl = items.any((i) => _excluded.contains(i.compositeKey));
    final scheme = Theme.of(context).colorScheme;

    void toggle() {
      setState(() {
        if (allExcl) {
          for (final item in items) {
            _excluded.remove(item.compositeKey);
          }
        } else {
          for (final item in items) {
            _excluded.add(item.compositeKey);
          }
        }
      });
    }

    return InkWell(
      onTap: toggle,
      child: Padding(
        padding: const EdgeInsets.only(left: 40, right: 16, top: 6, bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: allExcl ? true : (anyExcl ? null : false),
                tristate: true,
                onChanged: (_) => toggle(),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
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
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(_ActivityItem item, {required bool indent}) {
    final isExcluded = _excluded.contains(item.compositeKey);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _toggleItem(item.compositeKey),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isExcluded,
                onChanged: (_) => _toggleItem(item.compositeKey),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Text(item.displayCharacter, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Value object ──────────────────────────────────────────────────────────

class _ActivityItem {
  final String compositeKey;
  final String displayCharacter;
  final String name;
  final int sortOrder;

  const _ActivityItem({
    required this.compositeKey,
    required this.displayCharacter,
    required this.name,
    required this.sortOrder,
  });
}
