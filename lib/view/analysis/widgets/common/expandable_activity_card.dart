import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

/// A reusable expandable card widget for displaying categories with their activities
/// Converted to a StatefulWidget so it can participate in the keep-alive mechanism
/// and remain expanded when scrolled out of view.
class ExpandableActivityCard extends StatefulWidget {
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
  State<ExpandableActivityCard> createState() => _ExpandableActivityCardState();
}

class _ExpandableActivityCardState extends State<ExpandableActivityCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.isExpanded;

  @override
  void didUpdateWidget(covariant ExpandableActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the expanded state changed, inform the framework to update keep-alive.
    if (oldWidget.isExpanded != widget.isExpanded) {
      updateKeepAlive();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin

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
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Emoji/Icon
                    if (widget.emoji != null) ...[
                      Text(widget.emoji!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                    ],
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
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
                    if (widget.badgeCount > 0)
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
                          '${widget.badgeCount} ${widget.badgeLabel}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded content
          if (widget.isExpanded) ...[
            const Divider(height: 1),
            if (widget.activityCountsMap.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.activityCountsMap.entries.map((activityEntry) {
                      final activityId = activityEntry.key;
                      final count = activityEntry.value;
                      final activity = widget.availableActivities[activityId];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              child:
                                  (activity?.stiRisk ?? false) ||
                                      (activity?.healthRisk ?? false)
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
                            Expanded(
                              child: Text(
                                activity?.name ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                    if (widget.additionalContent != null) ...[
                      const SizedBox(height: 12),
                      widget.additionalContent!,
                    ],
                  ],
                ),
              ),
            if (widget.activityCountsMap.isEmpty)
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
