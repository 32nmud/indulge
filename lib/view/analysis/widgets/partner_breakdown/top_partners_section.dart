import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:intl/intl.dart';
import 'package:indulge/view/common/navigation_helper.dart';
import 'package:indulge/view/common/person_avatar.dart';
import '../../models/partner_breakdown_data.dart';

class TopPartnersSection extends StatefulWidget {
  final PartnerBreakdownData data;

  const TopPartnersSection({super.key, required this.data});

  @override
  State<TopPartnersSection> createState() => _TopPartnersSectionState();
}

class _TopPartnersSectionState extends State<TopPartnersSection> {
  final Set<String> _expandedPartners = {};

  @override
  Widget build(BuildContext context) {
    if (widget.data.personEventCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort partners by event count and take top 10
    final sortedPartners = widget.data.personEventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPartners = sortedPartners.take(10).toList();

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Partners',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topPartners.map((entry) {
              final partnerId = entry.key;
              final eventCount = entry.value;
              final activityCount = widget.data.personCounts[partnerId] ?? 0;
              final percentage = (eventCount / widget.data.events.length * 100)
                  .round();
              final maxCount = sortedPartners.first.value;
              final isExpanded = _expandedPartners.contains(partnerId);
              final partnerEvents = widget.data.personEvents[partnerId] ?? [];

              return _buildPartnerRow(
                context,
                partnerId: partnerId,
                eventCount: eventCount,
                activityCount: activityCount,
                percentage: percentage,
                maxCount: maxCount,
                isExpanded: isExpanded,
                partnerEvents: partnerEvents,
                colorIndex: topPartners.indexOf(entry),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerRow(
    BuildContext context, {
    required String partnerId,
    required int eventCount,
    required int activityCount,
    required int percentage,
    required int maxCount,
    required bool isExpanded,
    required List<SexualEvent> partnerEvents,
    required int colorIndex,
  }) {
    final person = widget.data.personMap[partnerId];
    final displayName =
        person?.name.nickname ?? person?.name.given ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedPartners.remove(partnerId);
                } else {
                  _expandedPartners.add(partnerId);
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (person != null)
                              PersonAvatar(person: person, radius: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$activityCount activit${activityCount != 1 ? 'ies' : 'y'}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$eventCount event${eventCount != 1 ? 's' : ''} ($percentage%)',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.search),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              DateTimeRange? range;
                              if (widget.data.startDate != null) {
                                range = DateTimeRange(
                                  start: widget.data.startDate!,
                                  end: widget.data.endDate ?? DateTime.now(),
                                );
                              }
                              NavigationHelper.of(context)?.navigateToSearch(
                                partnerId: partnerId,
                                dateRange: range,
                              );
                            },
                            tooltip: 'Search events with this person',
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: eventCount / maxCount,
                      minHeight: 8,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorForIndex(colorIndex),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            _buildPartnerDetails(context, partnerId, partnerEvents),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerDetails(
    BuildContext context,
    String partnerId,
    List<SexualEvent> events,
  ) {
    final activityTypeCounts = <String, int>{};
    final activityTypePropertyCounts = <String, Map<String, int>>{};

    // Count activities by type and track properties per activity type
    for (final event in events) {
      for (final activity in event.activities) {
        // Check if this activity involves this partner
        final hasPartner = activity.participants.any(
          (p) => p.participant.reference == partnerId,
        );
        if (hasPartner) {
          final typeId = activity.category.reference;
          activityTypeCounts[typeId] = (activityTypeCounts[typeId] ?? 0) + 1;

          // Track properties for this activity type
          activityTypePropertyCounts.putIfAbsent(typeId, () => {});
          for (final participant in activity.participants) {
            if (participant.participant.reference == partnerId) {
              for (final activityCount in participant.activityCounts) {
                // Use categoryReference + activityName as the activity identifier
                final catRef = activityCount.categoryReference.reference;
                final actName = activityCount.activityName;
                final activityId = '$catRef:$actName';
                activityTypePropertyCounts[typeId]![activityId] =
                    (activityTypePropertyCounts[typeId]![activityId] ?? 0) +
                    activityCount.count;
              }
            }
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                'Details',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  context,
                  icon: Icons.event,
                  label: 'Total Events',
                  value: events.length.toString(),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  context,
                  icon: Icons.event_note,
                  label: 'Total Activities',
                  value: (widget.data.personCounts[partnerId] ?? 0).toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Categories & Activities',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildCategoryCards(
            context,
            partnerId,
            activityTypePropertyCounts,
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Recent Events',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          ...events.reversed.take(3).map((event) {
            final dateStr = DateFormat('MMM d, yyyy').format(event.date);

            // Count categories (activities in the event) for this partner
            final categoryCount = event.activities.where((activity) {
              return activity.participants.any(
                (p) => p.participant.reference == partnerId,
              );
            }).length;

            // Count total specific activities for this partner
            var specificActivityCount = 0;
            for (final activity in event.activities) {
              final partnerParticipant = activity.participants
                  .where((p) => p.participant.reference == partnerId)
                  .firstOrNull;
              if (partnerParticipant != null) {
                for (final activityCount in partnerParticipant.activityCounts) {
                  specificActivityCount += activityCount.count;
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '$categoryCount categor${categoryCount != 1 ? 'ies' : 'y'}, $specificActivityCount activit${specificActivityCount != 1 ? 'ies' : 'y'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

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

  List<SexualActivityCategory> _subsOf(SexualActivityCategory parent) {
    return parent.subCategories
        .where((r) => r.reference.isNotEmpty)
        .map((r) => widget.data.allCategoriesMap[r.reference])
        .whereType<SexualActivityCategory>()
        .toList();
  }

  // ── Per-partner category card builder ────────────────────────────────────

  /// Builds the hierarchical category → subcategory → activity rows for a
  /// specific partner, mirroring the style of [PartnerActivityDiversitySection].
  List<Widget> _buildCategoryCards(
    BuildContext context,
    String partnerId,
    Map<String, Map<String, int>> activityTypePropertyCounts,
  ) {
    final subcatIds = _subcategoryIds;
    // Top-level categories sorted by their sort order.
    final topLevel =
        widget.data.allCategoriesMap.values
            .where((c) => !subcatIds.contains(c.id))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final cards = <Widget>[];

    for (final cat in topLevel) {
      // Gather composite-key → count for activities logged under this parent
      // and any of its subcategories that this partner was involved in.
      final subs = _subsOf(cat);
      final subIds = subs.map((s) => s.id).toSet();

      // Collect all composite keys and counts relevant to this category tree.
      final allKeysForCat = <String, int>{};
      void addFrom(String catId) {
        final map = activityTypePropertyCounts[catId] ?? {};
        map.forEach((key, count) {
          allKeysForCat[key] = (allKeysForCat[key] ?? 0) + count;
        });
      }

      addFrom(cat.id);
      for (final sub in subs) addFrom(sub.id);

      if (allKeysForCat.isEmpty) continue;

      // Split entries into direct (belongs to parent) and per-subcategory.
      final directEntries = <_DetailEntry>[];
      final subBuckets = <String, List<_DetailEntry>>{
        for (final s in subs) s.id: [],
      };

      allKeysForCat.forEach((compositeKey, count) {
        final colonIdx = compositeKey.indexOf(':');
        final keyCatId = colonIdx > 0
            ? compositeKey.substring(0, colonIdx)
            : '';
        final actName = colonIdx > 0
            ? compositeKey.substring(colonIdx + 1)
            : compositeKey;

        final activity = widget.data.sexualActivities[compositeKey];
        final entry = _DetailEntry(
          compositeKey: compositeKey,
          activityName: activity?.name ?? actName,
          displayCharacter: activity?.displayCharacter ?? '❔',
          count: count,
          stiRisk: activity?.stiRisk ?? false,
          healthRisk: activity?.healthRisk ?? false,
          sortOrder: activity?.sortOrder ?? 0,
        );

        if (subIds.contains(keyCatId)) {
          subBuckets[keyCatId]?.add(entry);
        } else {
          directEntries.add(entry);
        }
      });

      directEntries.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final subGroups = subs
          .map((sub) {
            final entries = (subBuckets[sub.id] ?? [])
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            return (sub: sub, entries: entries);
          })
          .where((g) => g.entries.isNotEmpty)
          .toList();

      final expandKey = '$partnerId-cat-${cat.id}';
      final isExpanded = _expandedPartners.contains(expandKey);
      final scheme = Theme.of(context).colorScheme;
      final totalCount = allKeysForCat.values.fold(0, (s, v) => s + v);

      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Category header ──────────────────────────────────────
                InkWell(
                  onTap: () => setState(() {
                    if (isExpanded) {
                      _expandedPartners.remove(expandKey);
                    } else {
                      _expandedPartners.add(expandKey);
                    }
                  }),
                  borderRadius: isExpanded
                      ? const BorderRadius.vertical(top: Radius.circular(9))
                      : BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: isExpanded
                          ? const BorderRadius.vertical(top: Radius.circular(9))
                          : BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        Text(
                          cat.displayCharacter ?? '❔',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              fontSize: 13,
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
                            '$totalCount activit${totalCount == 1 ? 'y' : 'ies'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Expanded body ────────────────────────────────────────
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...directEntries.map(
                          (e) => _buildDetailEntryRow(context, e),
                        ),
                        ...subGroups.asMap().entries.map((mapEntry) {
                          final idx = mapEntry.key;
                          final g = mapEntry.value;
                          final needsTopPad =
                              directEntries.isNotEmpty || idx > 0;
                          return _buildSubcategoryGroup(
                            context,
                            g.sub,
                            g.entries,
                            topPadding: needsTopPad ? 8.0 : 0.0,
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return cards;
  }

  Widget _buildDetailEntryRow(BuildContext context, _DetailEntry entry) {
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
              '×${entry.count}',
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

  Widget _buildSubcategoryGroup(
    BuildContext context,
    SexualActivityCategory sub,
    List<_DetailEntry> entries, {
    double topPadding = 0,
  }) {
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
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sub.name,
                    style: TextStyle(
                      fontSize: 12,
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
                    .map((e) => _buildDetailEntryRow(context, e))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
    ];
    return colors[index % colors.length];
  }
}

// ── Per-partner activity entry data class ─────────────────────────────────────

class _DetailEntry {
  final String compositeKey;
  final String activityName;
  final String displayCharacter;
  final int count;
  final bool stiRisk;
  final bool healthRisk;
  final int sortOrder;

  const _DetailEntry({
    required this.compositeKey,
    required this.activityName,
    required this.displayCharacter,
    required this.count,
    required this.stiRisk,
    required this.healthRisk,
    required this.sortOrder,
  });
}
