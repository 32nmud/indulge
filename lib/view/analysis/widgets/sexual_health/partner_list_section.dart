import 'package:flutter/material.dart';
import '../../models/sexual_health_analysis_data.dart';
import '../../../common/person_avatar.dart';
import 'package:indulge/view/common/navigation_helper.dart';

/// Widget showing partner list for the sexual health period.
class PartnerListSection extends StatelessWidget {
  final SexualHealthAnalysisData data;

  const PartnerListSection({super.key, required this.data});

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
                Text(
                  'Partners in Period',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                      child: Text(
                        displayName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '$eventCount event${eventCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
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
