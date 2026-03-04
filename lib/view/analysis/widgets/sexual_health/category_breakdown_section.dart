import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import '../../models/sexual_health_analysis_data.dart';

// ── Internal data models ──────────────────────────────────────────────────────

class _RiskyEntry {
  final String compositeKey;
  final String activityName;
  final String displayCharacter;
  final int count;
  final bool stiRisk;
  final bool healthRisk;
  final int sortOrder;

  const _RiskyEntry({
    required this.compositeKey,
    required this.activityName,
    required this.displayCharacter,
    required this.count,
    required this.stiRisk,
    required this.healthRisk,
    required this.sortOrder,
  });
}

class _SubGroup {
  final SexualActivityCategory sub;
  final List<_RiskyEntry> entries;
  const _SubGroup({required this.sub, required this.entries});
}

class _CategoryBreakdown {
  final SexualActivityCategory category;
  final List<_RiskyEntry> directEntries;
  final List<_SubGroup> subGroups;
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
}

// ── Main widget ───────────────────────────────────────────────────────────────

/// Displays risky activities broken down by category/subcategory hierarchy,
/// matching the visual style of [ActivitySectionBreakdown].
class CategoryBreakdownSection extends StatefulWidget {
  final SexualHealthAnalysisData data;

  const CategoryBreakdownSection({super.key, required this.data});

  @override
  State<CategoryBreakdownSection> createState() =>
      _CategoryBreakdownSectionState();
}

class _CategoryBreakdownSectionState extends State<CategoryBreakdownSection> {
  SexualHealthAnalysisData get _data => widget.data;

  // ── Hierarchy helpers ────────────────────────────────────────────────────

  Set<String> get _subcategoryIds {
    final ids = <String>{};
    for (final cat in _data.activityCategories.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) ids.add(ref.reference);
      }
    }
    return ids;
  }

  List<SexualActivityCategory> _topLevelCategories(Set<String> subcatIds) {
    return _data.activityCategories.values
        .where((c) => !subcatIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<SexualActivityCategory> _subsOf(SexualActivityCategory parent) {
    return parent.subCategories
        .where((r) => r.reference.isNotEmpty)
        .map((r) => _data.activityCategories[r.reference])
        .whereType<SexualActivityCategory>()
        .toList();
  }

  // ── Entry builders ───────────────────────────────────────────────────────

  /// Look up a [SexualActivity] by composite key in the data's activities map,
  /// or by scanning the category definition as a fallback.
  SexualActivity? _lookupActivity(String compositeKey) {
    // Check the pre-aggregated sexualActivities map first.
    final fromMap = _data.sexualActivities[compositeKey];
    if (fromMap != null) return fromMap;

    // Fallback: scan the category's activity list.
    final colonIdx = compositeKey.indexOf(':');
    if (colonIdx <= 0) return null;
    final catId = compositeKey.substring(0, colonIdx);
    final actName = compositeKey.substring(colonIdx + 1);
    final cat = _data.activityCategories[catId];
    if (cat == null) return null;
    for (final act in cat.activities) {
      if (act.name == actName) return act;
    }
    return null;
  }

  /// Build a [_RiskyEntry] for the given composite key and count.
  /// Returns null if the activity is not flagged as risky.
  _RiskyEntry? _makeRiskyEntry(String compositeKey, int count) {
    final colonIdx = compositeKey.indexOf(':');
    final actName = colonIdx > 0
        ? compositeKey.substring(colonIdx + 1)
        : compositeKey;

    final act = _lookupActivity(compositeKey);
    if (act == null) {
      // Unknown activity — include it as potentially risky rather than silently
      // dropping it (it appeared in riskyActivityCountsByCategory).
      return _RiskyEntry(
        compositeKey: compositeKey,
        activityName: actName.isNotEmpty ? actName : 'Unknown',
        displayCharacter: '❔',
        count: count,
        stiRisk: true,
        healthRisk: false,
        sortOrder: 0,
      );
    }

    if (!act.stiRisk && !act.healthRisk) return null;

    return _RiskyEntry(
      compositeKey: compositeKey,
      activityName: act.name,
      displayCharacter: act.displayCharacter,
      count: count,
      stiRisk: act.stiRisk,
      healthRisk: act.healthRisk,
      sortOrder: act.sortOrder,
    );
  }

  /// Returns all risky composite-key → count pairs from [eventsInPeriod] whose
  /// [EventActivity.category] matches [catId].
  Map<String, int> _rawRiskyCountsForCatId(String catId) {
    final result = <String, int>{};
    for (final event in _data.eventsInPeriod) {
      for (final activity in event.activities) {
        if (activity.category.reference != catId) continue;
        for (final participant in activity.participants) {
          for (final ac in participant.activityCounts) {
            final compositeKey =
                '${ac.categoryReference.reference}:${ac.activityName}';
            final act = _lookupActivity(compositeKey);
            if (act == null || (!act.stiRisk && !act.healthRisk)) continue;
            result[compositeKey] = (result[compositeKey] ?? 0) + ac.count;
          }
        }
      }
    }
    return result;
  }

  List<_RiskyEntry> _buildEntriesFor(String catId) {
    final raw = _rawRiskyCountsForCatId(catId);
    final entries =
        raw.entries
            .map((kv) => _makeRiskyEntry(kv.key, kv.value))
            .whereType<_RiskyEntry>()
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return entries;
  }

  /// Merge a list of entries by compositeKey, summing counts.
  List<_RiskyEntry> _mergeEntries(List<_RiskyEntry> entries) {
    final merged = <String, _RiskyEntry>{};
    for (final e in entries) {
      if (merged.containsKey(e.compositeKey)) {
        final ex = merged[e.compositeKey]!;
        merged[e.compositeKey] = _RiskyEntry(
          compositeKey: e.compositeKey,
          activityName: e.activityName,
          displayCharacter: e.displayCharacter,
          count: ex.count + e.count,
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

  _CategoryBreakdown _buildBreakdown(SexualActivityCategory cat) {
    final subs = _subsOf(cat);
    final subIds = subs.map((s) => s.id).toSet();

    final subBuckets = <String, List<_RiskyEntry>>{
      for (final s in subs) s.id: [],
    };

    // Entries from activities logged directly under the parent cat id.
    final directRaw = <_RiskyEntry>[];
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

    // Entries from activities logged directly under each subcategory id.
    for (final sub in subs) {
      subBuckets[sub.id]!.addAll(_buildEntriesFor(sub.id));
    }

    // Merge and sort each bucket; drop empty sub-groups.
    final subGroups = subs
        .map(
          (sub) =>
              _SubGroup(sub: sub, entries: _mergeEntries(subBuckets[sub.id]!)),
        )
        .where((g) => g.entries.isNotEmpty)
        .toList();

    final directEntries = _mergeEntries(directRaw);

    final totalCount =
        directEntries.fold<int>(0, (s, e) => s + e.count) +
        subGroups.fold<int>(
          0,
          (s, g) => s + g.entries.fold<int>(0, (s2, e) => s2 + e.count),
        );

    return _CategoryBreakdown(
      category: cat,
      directEntries: directEntries,
      subGroups: subGroups,
      totalCount: totalCount,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_data.eventsInPeriod.isEmpty) return const SizedBox.shrink();

    final subcatIds = _subcategoryIds;
    final topLevel = _topLevelCategories(subcatIds);

    final breakdowns = topLevel
        .map(_buildBreakdown)
        .where((b) => b.hasData)
        .toList();

    if (breakdowns.isEmpty) return const SizedBox.shrink();

    final totalRiskyCount = breakdowns.fold<int>(0, (s, b) => s + b.totalCount);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header ───────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STI & Health Risk Activities',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$totalRiskyCount risky '
                        '${totalRiskyCount == 1 ? 'instance' : 'instances'}'
                        ' across ${breakdowns.length} '
                        '${breakdowns.length == 1 ? 'category' : 'categories'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Category cards ───────────────────────────────────────────
            ...breakdowns.map((b) => _CategoryCard(breakdown: b)),
          ],
        ),
      ),
    );
  }
}

// ── Collapsible category card ─────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final _CategoryBreakdown breakdown;
  const _CategoryCard({required this.breakdown});

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
    final hasContent =
        widget.breakdown.directEntries.isNotEmpty ||
        widget.breakdown.subGroups.isNotEmpty;

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
                    // Count badge
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
                    ...widget.breakdown.directEntries.map(
                      (e) => _buildEntryRow(context, e),
                    ),

                    ...widget.breakdown.subGroups.asMap().entries.map(
                      (mapEntry) => _SubcategoryGroup(
                        sub: mapEntry.value.sub,
                        entries: mapEntry.value.entries,
                        topPadding:
                            widget.breakdown.directEntries.isNotEmpty ||
                                mapEntry.key > 0
                            ? 8.0
                            : 0.0,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(BuildContext context, _RiskyEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    final riskLabel = entry.stiRisk
        ? 'STI Risk'
        : entry.healthRisk
        ? 'Health Risk'
        : null;

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
          if (riskLabel != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: riskLabel,
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
  final List<_RiskyEntry> entries;
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

  Widget _buildEntryRow(BuildContext context, _RiskyEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    final riskLabel = entry.stiRisk
        ? 'STI Risk'
        : entry.healthRisk
        ? 'Health Risk'
        : null;

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
          if (riskLabel != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: riskLabel,
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
