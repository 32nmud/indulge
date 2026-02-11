import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

/// A reusable expandable card widget for displaying categories with their activities
class ExpandableActivityCard extends StatelessWidget {
  final String title;
  final String? emoji;
  final String subtitle;
  final int badgeCount;
  final String badgeLabel;
  final bool isExpanded;
  final VoidCallback onTap;
  final Map<String, int> activityCountsMap;
  final Map<String, SexualActivity> availableActivities;
  final Widget? additionalContent;

  const ExpandableActivityCard({
    super.key,
    required this.title,
    this.emoji,
    required this.subtitle,
    required this.badgeCount,
    required this.badgeLabel,
    required this.isExpanded,
    required this.onTap,
    required this.activityCountsMap,
    required this.availableActivities,
    this.additionalContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Emoji/Icon
                    if (emoji != null) ...[
                      Text(emoji!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                    ],
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Badge
                    if (badgeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$badgeCount $badgeLabel',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded content
          if (isExpanded) ...[
            const Divider(height: 1),
            if (activityCountsMap.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...activityCountsMap.entries.map((propEntry) {
                      final propertyId = propEntry.key;
                      final count = propEntry.value;
                      final property = availableActivities[propertyId];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            // Risky indicator
                            SizedBox(
                              width: 20,
                              child: property?.isRisky ?? false
                                  ? Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.tertiary,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 4),
                            // Property name
                            Expanded(
                              child: Text(
                                property?.name ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Count badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count×',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (additionalContent != null) ...[
                      const SizedBox(height: 12),
                      additionalContent!,
                    ],
                  ],
                ),
              ),
            if (activityCountsMap.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'No activities recorded',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
