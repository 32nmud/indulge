import 'package:flutter/material.dart';
import '../../models/sexual_health_analysis_data.dart';
import '../../../common/person_avatar.dart';
import 'package:indulge/view/common/navigation_helper.dart';

/// Widget showing partner list for the sexual health period.
class PartnerListSection extends StatelessWidget {
  final SexualHealthAnalysisData data;

  const PartnerListSection({super.key, required this.data});

  /// Counts the number of risky activity instances involving [partnerId]
  /// across all events in the period.
  int _riskyCountForPartner(String partnerId) {
    int count = 0;
    for (final event in data.eventsInPeriod) {
      for (final activity in event.activities) {
        final hasPartner = activity.participants.any(
          (p) => p.participant.reference == partnerId,
        );
        if (!hasPartner) continue;
        for (final participant in activity.participants) {
          if (participant.participant.reference != partnerId) continue;
          for (final ac in participant.activityCounts) {
            final compositeKey =
                '${ac.categoryReference.reference}:${ac.activityName}';
            final act = data.sexualActivities[compositeKey];
            if (act != null && (act.stiRisk || act.healthRisk)) {
              count += ac.count;
            }
          }
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    // Filter partners: exclude "me", include anonymous and known partners
    final filteredPartners = data.partnerEventCountsInPeriod.entries
        .where((entry) => entry.key != 'me' && entry.key.isNotEmpty)
        .toList();

    if (filteredPartners.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedPartners = filteredPartners
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Partners in Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedPartners.take(10).map((entry) {
              final partnerId = entry.key;
              final eventCount = entry.value;
              final person = data.partnerMap[partnerId];
              final isAnonymous = partnerId == 'anonymous';
              final displayName = isAnonymous
                  ? 'Anonymous'
                  : (person?.name.nickname ?? person?.name.given ?? 'Unknown');

              final riskyCount = _riskyCountForPartner(partnerId);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    if (person != null)
                      PersonAvatar(person: person, radius: 16)
                    else
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Row(
                            children: [
                              Text(
                                '$eventCount event${eventCount == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (riskyCount > 0) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 11,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$riskyCount risky',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.red.shade600,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, size: 18),
                      onPressed: () {
                        NavigationHelper.of(context)?.navigateToSearch(
                          partnerId: partnerId,
                          dateRange: data.periodRange,
                        );
                      },
                      tooltip: 'Search events with this person',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
