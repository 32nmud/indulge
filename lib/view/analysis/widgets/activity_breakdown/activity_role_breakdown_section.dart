import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import '../../models/activity_breakdown_data.dart';

/// Widget showing user's role breakdown (give/receive/both) for each activity,
/// grouped by category with collapsible sections. Only shows activities
/// where hasRoles = true.
class ActivityRoleBreakdownSection extends StatelessWidget {
  final ActivityBreakdownData data;

  const ActivityRoleBreakdownSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.userRoleActivityCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build category groupings with role data
    final categories = _buildCategoryBreakdowns(context);
    if (categories.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your Role Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'What you did with partners (inverted from their role)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.map((cat) => _CategoryRoleCard(category: cat)),
          ],
        ),
      ),
    );
  }

  List<_CategoryRoleData> _buildCategoryBreakdowns(BuildContext context) {
    final result = <_CategoryRoleData>[];
    final subcategoryIds = <String>{};

    // Find all subcategory IDs
    for (final cat in data.allCategoriesMap.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) subcategoryIds.add(ref.reference);
      }
    }

    // Get top-level categories (not subcategories)
    final topLevelCats =
        data.allCategoriesMap.values
            .where((c) => !subcategoryIds.contains(c.id))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final cat in topLevelCats) {
      final breakdown = _buildCategoryBreakdown(cat);
      if (breakdown != null) {
        result.add(breakdown);
      }
    }

    return result;
  }

  _CategoryRoleData? _buildCategoryBreakdown(SexualActivityCategory cat) {
    final subIds = cat.subCategories
        .where((r) => r.reference.isNotEmpty)
        .map((r) => r.reference)
        .toSet();

    // Collect activities and their role data
    final directEntries = <_ActivityRoleEntry>[];
    final subGroups = <_SubGroupRoleData>[];

    for (final entry in data.userRoleActivityCounts.entries) {
      final compositeKey = entry.key;
      final parts = compositeKey.split(':');
      final catId = parts.isNotEmpty ? parts[0] : '';
      final activityName = parts.length > 1 ? parts.sublist(1).join(':') : '';

      // Skip if not this category or a subcategory of this category
      if (catId != cat.id && !subIds.contains(catId)) continue;

      final sexualActivity = data.sexualActivities[compositeKey];

      // Skip activities without roles
      if (sexualActivity == null || !sexualActivity.hasRoles) continue;

      final roleCounts = entry.value;
      final userGave = roleCounts[ActivityRole.give] ?? 0;
      final userReceive = roleCounts[ActivityRole.receive] ?? 0;
      final userBoth = roleCounts[ActivityRole.both] ?? 0;
      final total = userGave + userReceive + userBoth;

      if (total == 0) continue;

      final entryData = _ActivityRoleEntry(
        compositeKey: compositeKey,
        activityName: activityName,
        displayCharacter: sexualActivity.displayCharacter,
        giveCount: userGave,
        receiveCount: userReceive,
        bothCount: userBoth,
        totalCount: total,
      );

      // Determine if this belongs to a subcategory
      if (subIds.contains(catId) && catId != cat.id) {
        final subCat = data.allCategoriesMap[catId];
        if (subCat != null) {
          final existingSub = subGroups
              .where((s) => s.sub.id == subCat.id)
              .firstOrNull;
          if (existingSub != null) {
            existingSub.entries.add(entryData);
          } else {
            subGroups.add(_SubGroupRoleData(sub: subCat, entries: [entryData]));
          }
        }
      } else {
        directEntries.add(entryData);
      }
    }

    // Sort entries
    directEntries.sort((a, b) {
      final sa = data.sexualActivities[a.compositeKey];
      final sb = data.sexualActivities[b.compositeKey];
      return (sa?.sortOrder ?? 0).compareTo(sb?.sortOrder ?? 0);
    });

    for (final sub in subGroups) {
      sub.entries.sort((a, b) {
        final sa = data.sexualActivities[a.compositeKey];
        final sb = data.sexualActivities[b.compositeKey];
        return (sa?.sortOrder ?? 0).compareTo(sb?.sortOrder ?? 0);
      });
    }

    // Sort subcategories
    subGroups.sort((a, b) => a.sub.sortOrder.compareTo(b.sub.sortOrder));

    final totalCount =
        directEntries.fold<int>(0, (sum, e) => sum + e.totalCount) +
        subGroups.fold<int>(
          0,
          (sum, g) => sum + g.entries.fold<int>(0, (s, e) => s + e.totalCount),
        );

    if (totalCount == 0) return null;

    return _CategoryRoleData(
      category: cat,
      directEntries: directEntries,
      subGroups: subGroups,
      totalCount: totalCount,
    );
  }
}

class _ActivityRoleEntry {
  final String compositeKey;
  final String activityName;
  final String displayCharacter;
  final int giveCount;
  final int receiveCount;
  final int bothCount;
  final int totalCount;

  const _ActivityRoleEntry({
    required this.compositeKey,
    required this.activityName,
    required this.displayCharacter,
    required this.giveCount,
    required this.receiveCount,
    required this.bothCount,
    required this.totalCount,
  });
}

class _SubGroupRoleData {
  final SexualActivityCategory sub;
  final List<_ActivityRoleEntry> entries;

  _SubGroupRoleData({required this.sub, required this.entries});

  int get totalCount => entries.fold<int>(0, (sum, e) => sum + e.totalCount);
}

class _CategoryRoleData {
  final SexualActivityCategory category;
  final List<_ActivityRoleEntry> directEntries;
  final List<_SubGroupRoleData> subGroups;
  final int totalCount;

  const _CategoryRoleData({
    required this.category,
    required this.directEntries,
    required this.subGroups,
    required this.totalCount,
  });

  bool get hasData =>
      directEntries.isNotEmpty || subGroups.any((g) => g.entries.isNotEmpty);
}

class _CategoryRoleCard extends StatefulWidget {
  final _CategoryRoleData category;

  const _CategoryRoleCard({required this.category});

  @override
  State<_CategoryRoleCard> createState() => _CategoryRoleCardState();
}

class _CategoryRoleCardState extends State<_CategoryRoleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cat = widget.category.category;
    final n = widget.category.totalCount;

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
            // Tappable header
            InkWell(
              onTap: widget.category.hasData
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
                    if (widget.category.hasData) ...[
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

            // Expanded body
            if (_expanded && widget.category.hasData)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.category.directEntries.map(_buildEntryRow),
                    ...widget.category.subGroups.map(_buildSubGroup),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(_ActivityRoleEntry entry) {
    return _RoleBarRow(entry: entry);
  }

  Widget _buildSubGroup(_SubGroupRoleData group) {
    final title = group.sub.displayCharacter != null
        ? '${group.sub.displayCharacter}  ${group.sub.name}'
        : group.sub.name;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Text(
                    group.sub.displayCharacter ?? '❔',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${group.totalCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Column(
                children: group.entries.map(_buildEntryRow).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBarRow extends StatelessWidget {
  final _ActivityRoleEntry entry;

  const _RoleBarRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final total = entry.totalCount.toDouble();
    if (total == 0) return const SizedBox.shrink();

    final givePct = entry.giveCount / total;
    final receivePct = entry.receiveCount / total;
    final bothPct = entry.bothCount / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                entry.displayCharacter,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.activityName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${entry.totalCount}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (givePct > 0)
                    Expanded(
                      flex: (givePct * 100).round(),
                      child: Container(
                        color: Colors.blue.shade400,
                        alignment: Alignment.center,
                        child: givePct >= 0.15
                            ? const Text(
                                'Gave',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  if (receivePct > 0)
                    Expanded(
                      flex: (receivePct * 100).round(),
                      child: Container(
                        color: Colors.purple.shade400,
                        alignment: Alignment.center,
                        child: receivePct >= 0.15
                            ? const Text(
                                'Received',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  if (bothPct > 0)
                    Expanded(
                      flex: (bothPct * 100).round(),
                      child: Container(
                        color: Colors.teal.shade400,
                        alignment: Alignment.center,
                        child: bothPct >= 0.15
                            ? const Text(
                                'Both',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
