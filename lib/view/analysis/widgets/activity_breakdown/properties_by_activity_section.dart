import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/data/models.dart';
import '../../models/analysis_data.dart';
import '../common/expandable_activity_card.dart';
import 'package:indulge/view/common/dialogs/category_filter_dialog.dart';
import 'package:indulge/services/preferences_service.dart';

class PropertiesByActivitySection extends StatefulWidget {
  final AnalysisData data;
  final AnalysisEventType? filterType;

  const PropertiesByActivitySection({
    super.key,
    required this.data,
    this.filterType,
  });

  @override
  State<PropertiesByActivitySection> createState() =>
      _PropertiesByActivitySectionState();
}

class _PropertiesByActivitySectionState
    extends State<PropertiesByActivitySection> {
  final Logger _logger = Logger('PropertiesByActivitySection');
  final Set<String> _expandedActivities = {};
  Set<String> _selectedCategoryIds = {};

  // PreferencesService instance and listener for persisted selected categories.
  PreferencesService? _prefsService;
  late VoidCallback _prefsListener;

  @override
  void initState() {
    super.initState();

    // Defer provider access until after the first frame so the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _prefsService = Provider.of<PreferencesService>(context, listen: false);
        // Seed initial selection from persisted preferences (properties-specific).
        final ids =
            _prefsService?.getPropertiesCategorySelectedIds().toSet() ??
            <String>{};
        if (mounted) {
          setState(() {
            _selectedCategoryIds = ids;
          });
        } else {
          _selectedCategoryIds = ids;
        }

        // Keep UI in sync if preferences change elsewhere.
        _prefsListener = () {
          final newIds =
              _prefsService?.getPropertiesCategorySelectedIds().toSet() ??
              <String>{};
          if (mounted) {
            setState(() {
              _selectedCategoryIds = newIds;
            });
          } else {
            _selectedCategoryIds = newIds;
          }
        };
        _prefsService?.propertiesCategorySelectedIdsNotifier.addListener(
          _prefsListener,
        );
      } catch (e) {
        _logger.warning(
          'Failed to initialize persisted category selection: $e',
        );
      }
    });
  }

  @override
  void dispose() {
    try {
      _prefsService?.propertiesCategorySelectedIdsNotifier.removeListener(
        _prefsListener,
      );
    } catch (_) {
      // ignore
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> counts;
    if (widget.filterType == null) {
      counts = widget.data.activityCountsThisYear;
    } else {
      counts = widget.data.activityCountsByType[widget.filterType!] ?? {};
    }

    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort activities by count
    final sortedActivities = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activities by Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _selectedCategoryIds.isEmpty
                        ? Icons.filter_list
                        : Icons.filter_list_alt,
                    color: _selectedCategoryIds.isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: _showCategoryFilter,
                  tooltip: 'Filter categories',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedActivities
                .where((entry) {
                  if (_selectedCategoryIds.isEmpty) return true;
                  return _selectedCategoryIds.contains(entry.key);
                })
                .map((entry) {
                  final activityTypeId = entry.key;
                  final activityCount = entry.value;
                  final activityCategory =
                      widget.data.activityCategories[activityTypeId];
                  final isExpanded = _expandedActivities.contains(
                    activityTypeId,
                  );

                  // Get properties for this activity type from the events
                  final activityProperties = _getPropertiesForActivity(
                    activityTypeId,
                  );

                  _logger.info(
                    'Activity ${activityCategory?.name} ($activityTypeId): found ${activityProperties.length} properties',
                  );

                  // Get enriched properties (from data and provider)
                  final enrichedProperties = _getEnrichedProperties(
                    activityProperties.keys.toSet(),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ExpandableActivityCard(
                      title: activityCategory?.name ?? 'Unknown',
                      emoji: activityCategory?.displayCharacter,
                      subtitle:
                          '$activityCount activit${activityCount != 1 ? 'ies' : 'y'}',
                      badgeCount: activityProperties.length,
                      badgeLabel: activityProperties.length == 1
                          ? 'activity'
                          : 'activities',
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
                      activityCountsMap: activityProperties,
                      availableActivities: enrichedProperties,
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }

  /// Get enriched properties (from data and provider state)
  Map<String, SexualActivity> _getEnrichedProperties(Set<String> propertyIds) {
    final result = <String, SexualActivity>{};

    for (final propertyId in propertyIds) {
      var property = widget.data.sexualActivities[propertyId];
      _logger.info('Property $propertyId: in data=${property != null}');

      if (property == null) {
        final providerState = context.read<SexualEventsProvider>().state;
        property = providerState.sexualActivities?[propertyId];
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
    List<SexualEvent> events;
    if (widget.filterType == null) {
      events = widget.data.events;
    } else {
      events = widget.data.eventsByType[widget.filterType!] ?? [];
    }

    _logger.info('Total events to search: ${events.length}');

    // Iterate through events (already filtered by selected time window)
    for (final event in events) {
      for (final activity in event.activities) {
        if (activity.category.reference == activityTypeId) {
          _logger.info(
            'Found matching activity in event ${event.date}, participants: ${activity.participants.length}',
          );

          // Count properties from all participants in this activity
          for (final participant in activity.participants) {
            _logger.info(
              'Participant has ${participant.activityCounts.length} activity counts',
            );

            for (final activityCount in participant.activityCounts) {
              final activityId = activityCount.activityReference.reference;
              _logger.info(
                'Found activity $activityId with count ${activityCount.count}',
              );
              propertyCountsForActivity[activityId] =
                  (propertyCountsForActivity[activityId] ?? 0) +
                  activityCount.count;
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

  Future<void> _showCategoryFilter() async {
    final categories = widget.data.activityCategories.values.toList();

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => CategoryFilterDialog(
        categories: categories,
        selectedIds: _selectedCategoryIds,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategoryIds = result;
      });

      // Persist the user's selection via PreferencesService (best-effort).
      try {
        final svc = Provider.of<PreferencesService>(context, listen: false);
        await svc.setPropertiesCategorySelectedIds(result.toList());
      } catch (e) {
        _logger.warning('Failed to persist selected categories: $e');
      }
    }
  }
}
