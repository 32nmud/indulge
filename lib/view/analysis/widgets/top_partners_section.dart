import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/data/models.dart';
import 'package:intl/intl.dart';
import '../models/analysis_data.dart';
import 'common/expandable_activity_card.dart';
import 'package:indulge/main.dart';

class TopPartnersSection extends StatefulWidget {
  final AnalysisData data;

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
              final percentage = (eventCount / widget.data.totalEvents * 100)
                  .round();
              final maxCount = sortedPartners.first.value;
              final isExpanded = _expandedPartners.contains(partnerId);
              final partnerEvents = widget.data.personEvents[partnerId] ?? [];

              return FutureBuilder(
                future: context.read<SexualEventsProvider>().getPersonById(
                  partnerId,
                ),
                builder: (context, snapshot) {
                  final person = snapshot.data;
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$activityCount activit${activityCount != 1 ? 'ies' : 'y'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '$eventCount event${eventCount != 1 ? 's' : ''} ($percentage%)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
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
                                            NavigationHelper.of(
                                              context,
                                            )?.navigateToSearchWithPartner(
                                              partnerId,
                                            );
                                          },
                                          tooltip:
                                              'Search events with this person',
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
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
                                      _getColorForIndex(
                                        topPartners.indexOf(entry),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 8),
                          _buildPartnerDetails(
                            context,
                            partnerId,
                            partnerEvents,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
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
          final typeId = activity.type.reference;
          activityTypeCounts[typeId] = (activityTypeCounts[typeId] ?? 0) + 1;

          // Track properties for this activity type
          activityTypePropertyCounts.putIfAbsent(typeId, () => {});
          for (final participant in activity.participants) {
            if (participant.participant.reference == partnerId) {
              for (final propertyCount in participant.propertyCounts) {
                final propertyId = propertyCount.propertyReference.reference;
                activityTypePropertyCounts[typeId]![propertyId] =
                    (activityTypePropertyCounts[typeId]![propertyId] ?? 0) +
                    propertyCount.count;
              }
            }
          }
        }
      }
    }

    final sortedActivityTypes = activityTypeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            'Activities & Properties',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          ...sortedActivityTypes.map((entry) {
            final typeId = entry.key;
            final activityType = widget.data.activityTypes[typeId];
            final count = entry.value;
            final propertyCountsForActivity =
                activityTypePropertyCounts[typeId] ?? {};
            final isExpanded = _expandedPartners.contains('$partnerId-$typeId');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ExpandableActivityCard(
                title: activityType?.name ?? 'Unknown',
                emoji: activityType?.displayCharacter,
                subtitle: '$count activit${count != 1 ? 'ies' : 'y'}',
                badgeCount: propertyCountsForActivity.length,
                badgeLabel: propertyCountsForActivity.length == 1
                    ? 'property'
                    : 'properties',
                isExpanded: isExpanded,
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedPartners.remove('$partnerId-$typeId');
                    } else {
                      _expandedPartners.add('$partnerId-$typeId');
                    }
                  });
                },
                propertyCountsMap: propertyCountsForActivity,
                availableProperties: widget.data.properties,
              ),
            );
          }),
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
            final activityCount = event.activities.where((activity) {
              return activity.participants.any(
                (p) => p.participant.reference == partnerId,
              );
            }).length;
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
                    '$activityCount activit${activityCount != 1 ? 'ies' : 'y'}',
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
