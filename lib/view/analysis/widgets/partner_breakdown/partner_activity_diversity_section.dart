import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/dialogs/category_filter_dialog.dart';
import 'package:indulge/services/preferences_service.dart';
import '../../models/partner_breakdown_data.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _PartnerEntry {
  final String compositeKey; // "catId:activityName"
  final String activityName;
  final String displayCharacter;
  final int partnerCount;
  final bool isActionable;
  final bool stiRisk;
  final bool healthRisk;
  final int sortOrder;

  const _PartnerEntry({
    required this.compositeKey,
    required this.activityName,
    required this.displayCharacter,
    required this.partnerCount,
    required this.isActionable,
    required this.stiRisk,
    required this.healthRisk,
    required this.sortOrder,
  });
}

class _PartnerSubGroup {
  final SexualActivityCategory sub;
  final List<_PartnerEntry> entries;
  const _PartnerSubGroup({required this.sub, required this.entries});
}

class _PartnerCategoryBreakdown {
  final SexualActivityCategory category;
  final List<_PartnerEntry> directEntries;
  final List<_PartnerSubGroup> subGroups;

  /// Total unique partners for this top-level category (from the pre-computed map).
  final int totalPartners;

  const _PartnerCategoryBreakdown({
    required this.category,
    required this.directEntries,
    required this.subGroups,
    required this.totalPartners,
  });

  bool get hasData =>
      totalPartners > 0 &&
      (directEntries.isNotEmpty || subGroups.any((g) => g.entries.isNotEmpty));

  bool get hasActionable =>
      directEntries.any((e) => e.isActionable) ||
      subGroups.any((g) => g.entries.any((e) => e.isActionable));

  bool get hasGear =>
      directEntries.any((e) => !e.isActionable) ||
      subGroups.any((g) => g.entries.any((e) => !e.isActionable));
}

// ── Main widget ───────────────────────────────────────────────────────────────

/// Renders a single section card (either actionable "Activities" or inactionable
/// "Gear & Items") of the partner diversity breakdown.  Render two instances —
/// one for each type — so both sections are always visible.
class PartnerActivityDiversitySection extends StatefulWidget {
  final PartnerBreakdownData data;

  /// When true shows only actionable activities; when false shows only
  /// inactionable (gear / items) activities.
  final bool showActionable;

  final String title;
  final String subtitle;
  final IconData icon;

  const PartnerActivityDiversitySection({
    super.key,
    required this.data,
    required this.showActionable,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<PartnerActivityDiversitySection> createState() =>
      _PartnerActivityDiversitySectionState();
}

class _PartnerActivityDiversitySectionState
    extends State<PartnerActivityDiversitySection> {
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

  // ── Entry building ───────────────────────────────────────────────────────

  /// Build a [_PartnerEntry] for [compositeKey] with [partnerCount].
  _PartnerEntry _makeEntry(String compositeKey, int partnerCount) {
    final colonIdx = compositeKey.indexOf(':');
    final catId = colonIdx > 0 ? compositeKey.substring(0, colonIdx) : '';
    final actName = colonIdx > 0
        ? compositeKey.substring(colonIdx + 1)
        : compositeKey;

    // Try the aggregated sexualActivities map first.
    final fromMap = widget.data.sexualActivities[compositeKey];
    if (fromMap != null) {
      return _PartnerEntry(
        compositeKey: compositeKey,
        activityName: fromMap.name,
        displayCharacter: fromMap.displayCharacter,
        partnerCount: partnerCount,
        isActionable: fromMap.isActionable,
        stiRisk: fromMap.stiRisk,
        healthRisk: fromMap.healthRisk,
        sortOrder: fromMap.sortOrder,
      );
    }

    // Fall back to scanning the category definition.
    final cat = widget.data.allCategoriesMap[catId];
    if (cat != null) {
      for (final act in cat.activities) {
        if (act.name == actName) {
          return _PartnerEntry(
            compositeKey: compositeKey,
            activityName: act.name,
            displayCharacter: act.displayCharacter,
            partnerCount: partnerCount,
            isActionable: act.isActionable,
            stiRisk: act.stiRisk,
            healthRisk: act.healthRisk,
            sortOrder: act.sortOrder,
          );
        }
      }
    }

    // Stub — treat as actionable so it is never silently hidden.
    return _PartnerEntry(
      compositeKey: compositeKey,
      activityName: actName.isNotEmpty ? actName : 'Unknown',
      displayCharacter: '❔',
      partnerCount: partnerCount,
      isActionable: true,
      stiRisk: false,
      healthRisk: false,
      sortOrder: 0,
    );
  }

  /// Merge a list of entries by compositeKey, summing partner counts.
  List<_PartnerEntry> _mergeEntries(List<_PartnerEntry> entries) {
    final merged = <String, _PartnerEntry>{};
    for (final e in entries) {
      if (merged.containsKey(e.compositeKey)) {
        final existing = merged[e.compositeKey]!;
        merged[e.compositeKey] = _PartnerEntry(
          compositeKey: e.compositeKey,
          activityName: e.activityName,
          displayCharacter: e.displayCharacter,
          partnerCount: existing.partnerCount + e.partnerCount,
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

  /// Raw entries for activities whose EventActivity category reference matches
  /// [catId] (i.e. recorded directly under this category or subcategory).
  List<_PartnerEntry> _buildEntriesFor(String catId) {
    final raw = widget.data.categoryActivityPartnerCountsThisYear[catId] ?? {};
    return raw.entries.map((kv) => _makeEntry(kv.key, kv.value)).toList();
  }

  /// Builds a [_PartnerCategoryBreakdown] for [cat].
  ///
  /// Mirrors the strategy used in PropertiesByActivitySection._buildBreakdown:
  /// 1. Collect entries from EventActivities logged under the parent category.
  ///    Route any whose composite-key catId matches a known subcategory into
  ///    that sub's bucket.
  /// 2. Collect entries from EventActivities logged directly under each sub.
  /// 3. Merge (sum) duplicates within each bucket.
  _PartnerCategoryBreakdown _buildBreakdown(SexualActivityCategory cat) {
    final subs = _subsOf(cat);
    final subIds = subs.map((s) => s.id).toSet();

    final subBuckets = <String, List<_PartnerEntry>>{
      for (final s in subs) s.id: [],
    };

    // Step 1 – entries from EventActivities whose category == parent cat id.
    final directRaw = <_PartnerEntry>[];
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

    // Step 3 – merge & sort; keep only non-empty subGroups.
    final subGroups = subs
        .map((sub) {
          final merged = _mergeEntries(subBuckets[sub.id]!);
          return _PartnerSubGroup(sub: sub, entries: merged);
        })
        .where((g) => g.entries.isNotEmpty)
        .toList();

    final directEntries = _mergeEntries(directRaw);

    // Total unique partners for the category header (pre-computed).
    final totalPartners =
        widget.data.categoryPartnerCountsThisYear[cat.id] ?? 0;

    return _PartnerCategoryBreakdown(
      category: cat,
      directEntries: directEntries,
      subGroups: subGroups,
      totalPartners: totalPartners,
    );
  }

  bool _isCategoryVisible(SexualActivityCategory cat, Set<String> selectedSet) {
    if (selectedSet.isEmpty) {
      return (widget.data.categoryPartnerCountsThisYear[cat.id] ?? 0) > 0 ||
          _subsOf(cat).any(
            (s) => (widget.data.categoryPartnerCountsThisYear[s.id] ?? 0) > 0,
          );
    }
    if (selectedSet.contains(cat.id)) return true;
    for (final sub in _subsOf(cat)) {
      if (selectedSet.contains(sub.id)) return true;
    }
    return false;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.data.categoryPartnerCountsThisYear.isEmpty) {
      return const SizedBox.shrink();
    }

    final prefs = Provider.of<PreferencesService>(context, listen: false);

    return ValueListenableBuilder<List<String>>(
      valueListenable: prefs.partnerPropertiesCategorySelectedIdsNotifier,
      builder: (context, selectedList, _) {
        final selectedSet = selectedList.toSet();
        final subcatIds = _subcategoryIds;
        final topLevel = _topLevelCategories(subcatIds);

        final breakdowns = topLevel
            .where((cat) => _isCategoryVisible(cat, selectedSet))
            .map(_buildBreakdown)
            .where((b) => b.hasData)
            .toList();

        final relevant = widget.showActionable
            ? breakdowns.where((b) => b.hasActionable).toList()
            : breakdowns.where((b) => b.hasGear).toList();

        if (relevant.isEmpty) return const SizedBox.shrink();

        return _PartnerSectionCard(
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
        await prefs.setPartnerPropertiesCategorySelectedIds(result.toList());
      } catch (_) {
        prefs.partnerPropertiesCategorySelectedIdsNotifier.value =
            List.unmodifiable(result.toList());
      }
    }
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _PartnerSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool filterActive;
  final VoidCallback onFilter;
  final List<_PartnerCategoryBreakdown> breakdowns;
  final List<_PartnerEntry> Function(List<_PartnerEntry>) filterEntries;

  const _PartnerSectionCard({
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
            ...breakdowns.map(
              (b) => _PartnerCategoryCard(
                breakdown: b,
                filterEntries: filterEntries,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Collapsible category card ─────────────────────────────────────────────────

class _PartnerCategoryCard extends StatefulWidget {
  final _PartnerCategoryBreakdown breakdown;
  final List<_PartnerEntry> Function(List<_PartnerEntry>) filterEntries;

  const _PartnerCategoryCard({
    required this.breakdown,
    required this.filterEntries,
  });

  @override
  State<_PartnerCategoryCard> createState() => _PartnerCategoryCardState();
}

class _PartnerCategoryCardState extends State<_PartnerCategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cat = widget.breakdown.category;
    final n = widget.breakdown.totalPartners;

    final directEntries = widget.filterEntries(widget.breakdown.directEntries);
    final subGroups = widget.breakdown.subGroups
        .map(
          (g) => _PartnerSubGroup(
            sub: g.sub,
            entries: widget.filterEntries(g.entries),
          ),
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
                        '$n ${n == 1 ? 'partner' : 'partners'}',
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
                    ...directEntries.map(_buildEntryRow),

                    ...subGroups.asMap().entries.map((mapEntry) {
                      final idx = mapEntry.key;
                      final g = mapEntry.value;
                      final needsTopPad = directEntries.isNotEmpty || idx > 0;
                      return _PartnerSubcategoryGroup(
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

  Widget _buildEntryRow(_PartnerEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    final isRisky = entry.stiRisk || entry.healthRisk;
    final n = entry.partnerCount;

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
              '$n ${n == 1 ? 'partner' : 'partners'}',
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

class _PartnerSubcategoryGroup extends StatelessWidget {
  final SexualActivityCategory sub;
  final List<_PartnerEntry> entries;
  final double topPadding;

  const _PartnerSubcategoryGroup({
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
            // Subcategory header — matches sexual_event_card / activity breakdown style
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
                children: entries
                    .map((e) => _buildEntryRow(context, e))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(BuildContext context, _PartnerEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    final isRisky = entry.stiRisk || entry.healthRisk;
    final n = entry.partnerCount;

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
              '$n ${n == 1 ? 'partner' : 'partners'}',
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
