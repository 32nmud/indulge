import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/data/models.dart';
import '../models/analysis_data.dart';
import 'common/expandable_activity_card.dart';

class PropertiesByActivitySection extends StatefulWidget {
  final AnalysisData data;

  const PropertiesByActivitySection({super.key, required this.data});

  @override
  State<PropertiesByActivitySection> createState() =>
      _PropertiesByActivitySectionState();
}

class _PropertiesByActivitySectionState
    extends State<PropertiesByActivitySection> {
  final Logger _logger = Logger('PropertiesByActivitySection');
  final Set<String> _expandedActivities = {};

  @override
  Widget build(BuildContext context) {
    if (widget.data.activityCountsThisYear.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort activities by count (last 12 months)
    final sortedActivities = widget.data.activityCountsThisYear.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Properties by Activity Type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.data.timeWindowLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...sortedActivities.map((entry) {
              final activityTypeId = entry.key;
              final activityCount = entry.value;
              final activityType = widget.data.activityTypes[activityTypeId];
              final isExpanded = _expandedActivities.contains(activityTypeId);

              // Get properties for this activity type from the events
              final activityProperties = _getPropertiesForActivity(
                activityTypeId,
              );

              _logger.info(
                'Activity ${activityType?.name} ($activityTypeId): found ${activityProperties.length} properties',
              );

              // Get enriched properties (from data and provider)
              final enrichedProperties = _getEnrichedProperties(
                activityProperties.keys.toSet(),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ExpandableActivityCard(
                  title: activityType?.name ?? 'Unknown',
                  emoji: activityType?.displayCharacter ?? '❓',
                  subtitle:
                      '$activityCount activit${activityCount != 1 ? 'ies' : 'y'}',
                  badgeCount: activityProperties.length,
                  badgeLabel: activityProperties.length == 1
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
                  propertyCountsMap: activityProperties,
                  availableProperties: enrichedProperties,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Get enriched properties (from data and provider state)
  Map<String, SexualActivityTypeProperty> _getEnrichedProperties(
    Set<String> propertyIds,
  ) {
    final result = <String, SexualActivityTypeProperty>{};

    for (final propertyId in propertyIds) {
      var property = widget.data.properties[propertyId];
      _logger.info('Property $propertyId: in data=${property != null}');

      if (property == null) {
        final providerState = context.read<SexualEventsProvider>().state;
        property = providerState.sexualActivityTypeProperties?[propertyId];
        _logger.info(
          'Property $propertyId: in provider=${property != null}, name=${property?.name}',
        );
        if (property == null) {
          _logger.warning(
            'Property $propertyId not found in data or provider state',
          );
        }
      }

      if (property != null) {
        result[propertyId] = property;
      }
    }

    return result;
  }

  /// Get properties used for a specific activity type with their counts
  Map<String, int> _getPropertiesForActivity(String activityTypeId) {
    final propertyCountsForActivity = <String, int>{};

    _logger.info('Getting properties for activity: $activityTypeId');
    _logger.info('Total events to search: ${widget.data.events.length}');

    // Iterate through events (already filtered by selected time window)
    for (final event in widget.data.events) {
      for (final activity in event.activities) {
        if (activity.type.reference == activityTypeId) {
          _logger.info(
            'Found matching activity in event ${event.date}, participants: ${activity.participants.length}',
          );

          // Count properties from all participants in this activity
          for (final participant in activity.participants) {
            _logger.info(
              'Participant has ${participant.propertyCounts.length} property counts',
            );

            for (final propertyCount in participant.propertyCounts) {
              final propertyId = propertyCount.propertyReference.reference;
              _logger.info(
                'Found property $propertyId with count ${propertyCount.count}',
              );
              propertyCountsForActivity[propertyId] =
                  (propertyCountsForActivity[propertyId] ?? 0) +
                  propertyCount.count;
            }
          }
        }
      }
    }

    _logger.info(
      'Activity $activityTypeId has ${propertyCountsForActivity.length} properties: ${propertyCountsForActivity.keys.toList()}',
    );

    // Sort by count descending
    final sortedEntries = propertyCountsForActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }
}
