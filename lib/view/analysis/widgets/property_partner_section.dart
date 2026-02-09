import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import '../models/analysis_data.dart';
import 'common/expandable_activity_card.dart';

class PropertyPartnerSection extends StatefulWidget {
  final AnalysisData data;

  const PropertyPartnerSection({super.key, required this.data});

  @override
  State<PropertyPartnerSection> createState() => _PropertyPartnerSectionState();
}

class _PropertyPartnerSectionState extends State<PropertyPartnerSection> {
  final Set<String> _expandedActivities = {};

  @override
  Widget build(BuildContext context) {
    if (widget.data.activityPartnerCountsThisYear.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort activities by unique partner count
    final sortedActivities =
        widget.data.activityPartnerCountsThisYear.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partner Diversity by Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.data.timeWindowLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Number of unique partners per activity and property',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedActivities.map((entry) {
              final activityTypeId = entry.key;
              final partnerCount = entry.value;
              final activityType = widget.data.activityTypes[activityTypeId];
              final isExpanded = _expandedActivities.contains(activityTypeId);

              // Get properties for this activity with their unique partner counts
              final activityPropertyPartnerCounts =
                  widget
                      .data
                      .activityPropertyPartnerCountsThisYear[activityTypeId] ??
                  {};

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ExpandableActivityCard(
                  title: activityType?.name ?? 'Unknown',
                  emoji: activityType?.displayCharacter,
                  subtitle:
                      '$partnerCount unique partner${partnerCount != 1 ? 's' : ''}',
                  badgeCount: activityPropertyPartnerCounts.length,
                  badgeLabel: activityPropertyPartnerCounts.length == 1
                      ? 'property'
                      : 'properties',
                  isExpanded: isExpanded,
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedActivities.remove(activityTypeId);
                      } else {
                        _expandedActivities.add(activityTypeId);
                      }
                    });
                  },
                  propertyCountsMap: activityPropertyPartnerCounts,
                  availableProperties: widget.data.properties,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
