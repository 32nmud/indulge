import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/dialogs/category_filter_dialog.dart';
import 'package:indulge/services/preferences_service.dart';
import '../../models/analysis_event_type.dart';
import '../../models/activity_breakdown_data.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _ActivityEntry {
  final String compositeKey; // "catId:activityName"
  final String activityName;
  final String displayCharacter;
  final int count;
  final bool isActionable;
  final bool stiRisk;
  final bool healthRisk;
  final int sortOrder;

  const _ActivityEntry({
    required this.compositeKey,
    required this.activityName,
    required this.displayCharacter,
    required this.count,
    required this.isActionable,
    required this.stiRisk,
    required this.healthRisk,
    required this.sortOrder,
  });
}

class _SubGroup {
  final SexualActivityCategory sub;
  final List<_ActivityEntry> entries;
  const _SubGroup({required this.sub, required this.entries});
}

class _CategoryBreakdown {
  final SexualActivityCategory category;
  final List<_ActivityEntry> directEntries; // activities directly on this cat
  final List<_SubGroup> subGroups; // subcategories with their activities
  final int totalCount;

  const _CategoryBreakdown({
    required this.category,
    required this.directEntries,
    required this.subGroups,
    required this.totalCount,
  });

  bool get hasData =>
      totalCount > 0 &&
      (directEntries.isNotEmpty || subGroups.any((g) => g.entries.isNotEmpty));

  /// True if ANY entry (direct or in a sub) is actionable.
  bool get hasActionable =>
      directEntries.any((e) => e.isActionable) ||
      subGroups.any((g) => g.entries.any((e) => e.isActionable));

  /// True if ANY entry (direct or in a sub) is inactionable.
  bool get hasGear =>
      directEntries.any((e) => !e.isActionable) ||
      subGroups.any((g) => g.entries.any((e) => !e.isActionable));
}

// ── Main widget ───────────────────────────────────────────────────────────────

/// Renders a single section card (either actionable "Activities" or inactionable
/// "Gear & Items") depending on [showActionable].  Callers should render two
/// instances – one for each type – so both sections are always visible.
class PropertiesByActivitySection extends StatefulWidget {
  final ActivityBreakdownData data;
  final AnalysisEventType? filterType;

  /// When true, shows only actionable activities; when false, shows only
  /// inactionable (gear / items) activities.
  final bool showActionable;

  final String title;
  final String subtitle;
  final IconData icon;

  const PropertiesByActivitySection({
    super.key,
    required this.data,
    required this.showActionable,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.filterType,
  });

  @override
  State<PropertiesByActivitySection> createState() =>
      _PropertiesByActivitySectionState();
}

class _PropertiesByActivitySectionState
    extends State<PropertiesByActivitySection> {
  // ── Hierarchy helpers ────────────────────────────────────────────────────

  Set<String> get _subcategoryIds {
    final ids = <String>{};
    for (final cat in widget.data.allCategoriesMap.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) ids.add(ref.reference);
      }
    }
    return ids;
  }

  List<SexualActivityCategory> _topLevelCategories(Set<String> subcatIds) {
    return widget.data.allCategoriesMap.values
        .where((c) => !subcatIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<SexualActivityCategory> _subsOf(SexualActivityCategory parent) {
    return parent.subCategories
        .where((r) => r.reference.isNotEmpty)
        .map((r) => widget.data.allCategoriesMap[r.reference])
        .whereType<SexualActivityCategory>()
        .toList();
  }

  // ── Count helpers ────────────────────────────────────────────────────────

  Map<String, int> get _counts {
    if (widget.filterType == null) return widget.data.activityCountsThisYear;
    return widget.data.activityCountsByType[widget.filterType!] ?? {};
  }

  List<SexualEvent> get _events {
    if (widget.filterType == null) return widget.data.events;
    return widget.data.eventsByType[widget.filterType!] ?? [];
  }

  int _totalCountFor(SexualActivityCategory cat) {
    int total = _counts[cat.id] ?? 0;
    for (final sub in _subsOf(cat)) {
      total += _counts[sub.id] ?? 0;
    }
    return total;
  }

  bool _isCategoryVisible(SexualActivityCategory cat, Set<String> selectedSet) {
    if (selectedSet.isEmpty) return _totalCountFor(cat) > 0;
    if (selectedSet.contains(cat.id) && (_counts[cat.id] ?? 0) > 0) return true;
    for (final sub in _subsOf(cat)) {
      if (selectedSet.contains(sub.id) && (_counts[sub.id] ?? 0) > 0) {
        return true;
      }
    }
    return false;
  }

  // ── Activity lookup ──────────────────────────────────────────────────────

  /// Look up a SexualActivity by composite key from all available sources.
  SexualActivity? _lookupActivity(String compositeKey) {
    return widget.data.sexualActivities[compositeKey] ??
        context.read<EventStateStore>().state.sexualActivities?[compositeKey];
  }

  /// Build an [_ActivityEntry] for [compositeKey] with [count].
  /// Falls back to scanning the category definition, then a synthesised stub.
  _ActivityEntry _makeEntry(String compositeKey, int count) {
    final colonIdx = compositeKey.indexOf(':');
    final catId = colonIdx > 0 ? compositeKey.substring(0, colonIdx) : '';
    final actName = colonIdx > 0
        ? compositeKey.substring(colonIdx + 1)
        : compositeKey;

    // Try the aggregated sexualActivities map first (keyed by composite key).
    final fromMap = _lookupActivity(compositeKey);
    if (fromMap != null) {
      return _ActivityEntry(
        compositeKey: compositeKey,
        activityName: fromMap.name,
        displayCharacter: fromMap.displayCharacter,
        count: count,
        isActionable: fromMap.isActionable,
        stiRisk: fromMap.stiRisk,
        healthRisk: fromMap.healthRisk,
        sortOrder: fromMap.sortOrder,
      );
    }

    // Fall back to scanning the category definition for the activity by name.
    final cat = widget.data.allCategoriesMap[catId];
    if (cat != null) {
      for (final act in cat.activities) {
        if (act.name == actName) {
          return _ActivityEntry(
            compositeKey: compositeKey,
            activityName: act.name,
            displayCharacter: act.displayCharacter,
            count: count,
            isActionable: act.isActionable,
            stiRisk: act.stiRisk,
            healthRisk: act.healthRisk,
            sortOrder: act.sortOrder,
          );
        }
      }
    }

    // Last resort stub — treat as actionable so it isn't silently hidden.
    return _ActivityEntry(
      compositeKey: compositeKey,
      activityName: actName.isNotEmpty ? actName : 'Unknown',
      displayCharacter: '❔',
      count: count,
      isActionable: true,
      stiRisk: false,
      healthRisk: false,
      sortOrder: 0,
    );
  }

  /// Raw composite-key → count for activities whose [EventActivity.category]
  /// reference matches [catId] (i.e. events recorded under this exact
  /// category or subcategory).
  Map<String, int> _rawCountsForCatId(String catId) {
    final result = <String, int>{};
    for (final event in _events) {
      for (final activity in event.activities) {
        if (activity.category.reference != catId) continue;
        for (final participant in activity.participants) {
          for (final ac in participant.activityCounts) {
            final key = '${ac.categoryReference.reference}:${ac.activityName}';
            result[key] = (result[key] ?? 0) + ac.count;
          }
        }
      }
    }
    return result;
  }

  List<_ActivityEntry> _buildEntriesFor(String catId) {
    final raw = _rawCountsForCatId(catId);
    final entries = raw.entries
        .map((kv) => _makeEntry(kv.key, kv.value))
        .toList();
    entries.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return entries;
  }

  /// Merge a list of entries by compositeKey, summing counts.
  List<_ActivityEntry> _mergeEntries(List<_ActivityEntry> entries) {
    final merged = <String, _ActivityEntry>{};
    for (final e in entries) {
      if (merged.containsKey(e.compositeKey)) {
        final existing = merged[e.compositeKey]!;
        merged[e.compositeKey] = _ActivityEntry(
          compositeKey: e.compositeKey,
          activityName: e.activityName,
          displayCharacter: e.displayCharacter,
          count: existing.count + e.count,
          isActionable: e.isActionable,
          stiRisk: e.stiRisk,
          healthRisk: e.healthRisk,
          sortOrder: e.sortOrder,
        );
      } else {
        merged[e.compositeKey] = e;
      }
    }
    return merged.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Builds a [_CategoryBreakdown] for [cat].
  ///
  /// Strategy:
  /// 1. Collect all activity entries from EventActivities logged under the
  ///    parent category ID.  For each entry whose composite-key catId matches
  ///    a known subcategory, route it into that subcategory's bucket instead
  ///    of leaving it as a direct entry.
  /// 2. Also collect entries from EventActivities logged directly under each
  ///    subcategory ID and merge them into the same buckets.
  /// 3. Merge (sum) duplicate keys within each bucket.
  _CategoryBreakdown _buildBreakdown(SexualActivityCategory cat) {
    final subs = _subsOf(cat);
    final subIds = subs.map((s) => s.id).toSet();

    // Bucket: subCatId → list of entries (will be merged later).
    final subBuckets = <String, List<_ActivityEntry>>{
      for (final s in subs) s.id: [],
    };

    // Step 1 – entries from EventActivities whose category == parent cat id.
    final directRaw = <_ActivityEntry>[];
    for (final entry in _buildEntriesFor(cat.id)) {
      final keyCatId = entry.compositeKey.contains(':')
          ? entry.compositeKey.substring(0, entry.compositeKey.indexOf(':'))
          : '';
      if (subIds.contains(keyCatId)) {
        subBuckets[keyCatId]!.add(entry);
      } else {
        directRaw.add(entry);
      }
    }

    // Step 2 – entries from EventActivities logged directly under each sub.
    for (final sub in subs) {
      subBuckets[sub.id]!.addAll(_buildEntriesFor(sub.id));
    }

    // Step 3 – merge & sort each bucket; keep only non-empty subGroups.
    final subGroups = subs
        .map((sub) {
          final merged = _mergeEntries(subBuckets[sub.id]!);
          return _SubGroup(sub: sub, entries: merged);
        })
        .where((g) => g.entries.isNotEmpty)
        .toList();

    final directEntries = _mergeEntries(directRaw);

    return _CategoryBreakdown(
      category: cat,
      directEntries: directEntries,
      subGroups: subGroups,
      totalCount: _totalCountFor(cat),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_counts.isEmpty) return const SizedBox.shrink();

    final prefs = Provider.of<PreferencesService>(context, listen: false);

    return ValueListenableBuilder<List<String>>(
      valueListenable: prefs.propertiesCategorySelectedIdsNotifier,
      builder: (context, selectedList, _) {
        final selectedSet = selectedList.toSet();
        final subcatIds = _subcategoryIds;
        final topLevel = _topLevelCategories(subcatIds);

        final breakdowns = topLevel
            .where((cat) => _isCategoryVisible(cat, selectedSet))
            .map(_buildBreakdown)
            .where((b) => b.hasData)
            .toList();

        // Filter to only breakdowns relevant to this section type.
        final relevant = widget.showActionable
            ? breakdowns.where((b) => b.hasActionable).toList()
            : breakdowns.where((b) => b.hasGear).toList();

        if (relevant.isEmpty) return const SizedBox.shrink();

        return _SectionCard(
          icon: widget.icon,
          title: widget.title,
          subtitle: widget.subtitle,
          filterActive: selectedSet.isNotEmpty,
          onFilter: () => _showCategoryFilter(context, prefs, selectedSet),
          breakdowns: relevant,
          filterEntries: widget.showActionable
              ? (entries) => entries.where((e) => e.isActionable).toList()
              : (entries) => entries.where((e) => !e.isActionable).toList(),
        );
      },
    );
  }

  Future<void> _showCategoryFilter(
    BuildContext context,
    PreferencesService prefs,
    Set<String> currentSelected,
  ) async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => CategoryFilterDialog(
        categoriesMap: widget.data.allCategoriesMap,
        selectedIds: currentSelected,
      ),
    );
    if (result != null) {
      try {
        await prefs.setPropertiesCategorySelectedIds(result.toList());
      } catch (_) {
        // best-effort
      }
    }
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool filterActive;
  final VoidCallback onFilter;
  final List<_CategoryBreakdown> breakdowns;

  /// Applied to every entry list before rendering so each section only shows
  /// its own type of activity.
  final List<_ActivityEntry> Function(List<_ActivityEntry>) filterEntries;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filterActive,
    required this.onFilter,
    required this.breakdowns,
    required this.filterEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    filterActive ? Icons.filter_list_alt : Icons.filter_list,
                    color: filterActive
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: onFilter,
                  tooltip: 'Filter categories',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // One collapsible card per top-level category
            ...breakdowns.map(
              (b) => _CategoryCard(breakdown: b, filterEntries: filterEntries),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Collapsible category card ─────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final _CategoryBreakdown breakdown;
  final List<_ActivityEntry> Function(List<_ActivityEntry>) filterEntries;

  const _CategoryCard({required this.breakdown, required this.filterEntries});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cat = widget.breakdown.category;
    final n = widget.breakdown.totalCount;

    // Filter direct entries for this section type.
    final directEntries = widget.filterEntries(widget.breakdown.directEntries);

    // Filter sub-groups — drop groups that become empty after filtering.
    final subGroups = widget.breakdown.subGroups
        .map(
          (g) =>
              _SubGroup(sub: g.sub, entries: widget.filterEntries(g.entries)),
        )
        .where((g) => g.entries.isNotEmpty)
        .toList();

    final hasContent = directEntries.isNotEmpty || subGroups.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Tappable header ──────────────────────────────────────────
            InkWell(
              onTap: hasContent
                  ? () => setState(() => _expanded = !_expanded)
                  : null,
              borderRadius: _expanded
                  ? const BorderRadius.vertical(top: Radius.circular(9))
                  : BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: _expanded
                      ? const BorderRadius.vertical(top: Radius.circular(9))
                      : BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Text(
                      cat.displayCharacter ?? '❔',
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$n ${n == 1 ? 'time' : 'times'}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    if (hasContent) ...[
                      const SizedBox(width: 6),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Expanded body ────────────────────────────────────────────
            if (_expanded && hasContent)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Direct entries (belong to this category, not a sub)
                    ...directEntries.map(_buildEntryRow),

                    // Subcategory groups
                    ...subGroups.asMap().entries.map((mapEntry) {
                      final idx = mapEntry.key;
                      final g = mapEntry.value;
                      final needsTopPad = directEntries.isNotEmpty || idx > 0;
                      return _SubcategoryGroup(
                        sub: g.sub,
                        entries: g.entries,
                        topPadding: needsTopPad ? 8.0 : 0.0,
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(_ActivityEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    final isRisky = entry.stiRisk || entry.healthRisk;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(entry.displayCharacter, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.activityName,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          if (isRisky) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: entry.stiRisk ? 'STI Risk' : 'Health Risk',
              child: Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: scheme.tertiary,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${entry.count}×',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subcategory group ─────────────────────────────────────────────────────────

class _SubcategoryGroup extends StatelessWidget {
  final SexualActivityCategory sub;
  final List<_ActivityEntry> entries;
  final double topPadding;

  const _SubcategoryGroup({
    required this.sub,
    required this.entries,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sub-category header — matches sexual_event_card style
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    sub.displayCharacter ?? '❔',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sub.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            // Activity rows
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.map(_buildEntryRow).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(_ActivityEntry entry) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final isRisky = entry.stiRisk || entry.healthRisk;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Text(
                entry.displayCharacter,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.activityName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              if (isRisky) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: entry.stiRisk ? 'STI Risk' : 'Health Risk',
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: scheme.tertiary,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${entry.count}×',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSecondaryContainer,
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
