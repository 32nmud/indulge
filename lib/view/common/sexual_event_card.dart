import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/common/person_avatar.dart';
import 'package:indulge/view/common/sexual_event_editor/sexual_event_editor.dart';
import 'package:indulge/view/common/share/event_share_bottom_sheet.dart';
import 'location_map.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:provider/provider.dart';

/// EventCard
///
/// Displays a compact/expandable card for a single `SexualEvent`. When the
/// event has a `location` embedded, the expanded card shows a non-interactive
/// map preview (tiles are rendered, but the preview ignores user gestures).
class SexualEventCard extends StatefulWidget {
  final SexualEvent event;
  const SexualEventCard({super.key, required this.event});

  @override
  State<SexualEventCard> createState() => _SexualEventCardState();
}

/// Helper class to hold activity display data (emoji and name)
class _ActivityDisplay {
  final String emoji;
  final String name;

  _ActivityDisplay({required this.emoji, required this.name});
}

class _SexualEventCardState extends State<SexualEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late final fm.MapController _previewMapController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Controller for the small preview map (kept per-card lifetime).
    _previewMapController = fm.MapController();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SexualEventsProvider>();
    final store = context.watch<EventStateStore>();
    final List<EventActivity> activities = widget.event.activities;
    final eventState = store.state;
    final Future<List<Person>> participants = provider.getPersonsForEvent(
      widget.event.id,
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<List<Person>>(
          future: participants,
          builder: (context, snapshot) {
            // Use empty participant list while loading to keep UI stable.
            final persons = snapshot.data ?? [];
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              );
            }
            return _eventCard(context, persons, eventState, activities);
          },
        ),
      ),
    );
  }

  Widget _eventCard(
    BuildContext context,
    List<Person> persons,
    EventState eventState,
    List<EventActivity> activities,
  ) {
    return InkWell(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_fire_department,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          _getEventTitleString(persons),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(widget.event.date),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            _buildCompactPreview(activities, eventState, persons),
          ],
        ),
        children: [
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No activities in this event',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            _buildDetailedActivitiesList(activities, persons, eventState),

          if (widget.event.notes != null &&
              widget.event.notes!.trim().isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notes",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MarkdownBody(data: widget.event.notes!),
                  ],
                ),
              ),
            ),
          ],

          // Show an embedded, non-interactive map preview when a location exists.
          if (widget.event.location != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  // Use the shared LocationMap so the preview uses the same
                  // center-fixed pin as the editor. Keep it non-interactive.
                  child: LocationMap(
                    mapController: _previewMapController,
                    latitude: widget.event.location!.latitude,
                    longitude: widget.event.location!.longitude,
                    zoom: 13.0,
                    isFetching: false,
                    interactive: false,
                    height: 140,
                    pinSize: 28,
                    pinColor: Theme.of(context).colorScheme.primary,
                    onCenterChanged: (lat, lng) {},
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          const Divider(),
          _buildButtonRow(context, persons, eventState),
        ],
      ),
    );
  }

  Widget _buildCompactPreview(
    List<EventActivity> activities,
    EventState eventState,
    List<Person> persons,
  ) {
    if (activities.isEmpty) {
      return const Text('No activities');
    }

    // Sort activities by category name alphabetically
    final sortedActivities = List<EventActivity>.from(activities)
      ..sort((a, b) {
        final nameA =
            eventState.sexualActivityCategories?[a.category.reference]?.name ??
            '';
        final nameB =
            eventState.sexualActivityCategories?[b.category.reference]?.name ??
            '';
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

    // Collect unique categories from all activities (compact view shows categories, not specific activities)
    final Map<String, _ActivityDisplay> categoryDisplays = {};
    for (final categoryActivity in sortedActivities) {
      final categoryRef = categoryActivity.category.reference;
      final category = eventState.sexualActivityCategories?[categoryRef];

      if (category != null && !categoryDisplays.containsKey(categoryRef)) {
        categoryDisplays[categoryRef] = _ActivityDisplay(
          emoji: category.displayCharacter ?? '❔',
          name: category.name,
        );
      }
    }

    final chips = categoryDisplays.values.map((display) {
      return Chip(
        avatar: Text(display.emoji, style: const TextStyle(fontSize: 14)),
        label: Text(display.name, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _buildDetailedActivitiesList(
    List<EventActivity> activities,
    List<Person> persons,
    EventState eventState,
  ) {
    // Sort activities by category sortOrder (user-defined order from Settings).
    final sortedActivities = List<EventActivity>.from(activities)
      ..sort((a, b) {
        final orderA =
            eventState
                .sexualActivityCategories?[a.category.reference]
                ?.sortOrder ??
            0;
        final orderB =
            eventState
                .sexualActivityCategories?[b.category.reference]
                ?.sortOrder ??
            0;
        return orderA.compareTo(orderB);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedActivities.map((activity) {
        return _buildActivityCard(activity, persons, eventState);
      }).toList(),
    );
  }

  Widget _buildActivityCard(
    EventActivity activity,
    List<Person> persons,
    EventState eventState,
  ) {
    final activityCategory =
        eventState.sexualActivityCategories?[activity.category.reference];
    final emoji = activityCategory?.displayCharacter ?? '❔';
    final name = activityCategory?.name ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity header
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Show parent category if this is a subcategory
                      if (_isSubcategory(activityCategory, eventState))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'in ${_getParentCategoryName(activityCategory, eventState)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.outline,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      Text(
                        '${activity.participants.length} ${activity.participants.length == 1 ? 'participant' : 'participants'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Participants breakdown
            if (activity.participants.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _buildParticipantsBreakdown(activity, persons, eventState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsBreakdown(
    EventActivity activity,
    List<Person> persons,
    EventState eventState,
  ) {
    final activityParticipantIds = activity.participants
        .map((p) => p.participant.reference)
        .toSet();

    final activityPersons = persons
        .where((person) => activityParticipantIds.contains(person.id))
        .toList();

    // key: '$catRef:$actName'  →  map of Person → count
    final Map<String, Map<Person, int>> propertyGroups = {};

    for (var participant in activity.participants) {
      final person = activityPersons.firstWhere(
        (p) => p.id == participant.participant.reference,
        orElse: () => Person(
          date: DateTime.now(),
          name: const Name(given: 'Unknown'),
        ),
      );

      if (participant.activityCounts.isEmpty) {
        propertyGroups.putIfAbsent('_no_activity', () => {});
        propertyGroups['_no_activity']![person] = 1;
      } else {
        for (var activityCount in participant.activityCounts) {
          // catRef is the direct category (may be a subcategory) that owns this activity
          final catRef = activityCount.categoryReference.reference;
          final actName = activityCount.activityName;
          final key = '$catRef:$actName';
          propertyGroups.putIfAbsent(key, () => {});
          propertyGroups[key]![person] = activityCount.count;
        }
      }
    }

    // ----------------------------------------------------------------
    // Build a display model so we can group rows by subcategory.
    // ----------------------------------------------------------------

    // Holds one row of data ready for rendering.
    final rows = <_ActivityRow>[];

    for (final entry in propertyGroups.entries) {
      if (entry.key == '_no_activity') {
        rows.add(_ActivityRow.noActivity(entry.value));
        continue;
      }

      final colonIdx = entry.key.indexOf(':');
      final catRef = colonIdx >= 0
          ? entry.key.substring(0, colonIdx)
          : entry.key;
      final actName = colonIdx >= 0
          ? entry.key.substring(colonIdx + 1)
          : entry.key;

      // catRef is the direct category that owns this activity — look it up directly.
      final category = eventState.sexualActivityCategories?[catRef];

      String? activityEmoji;
      String? activityDisplayName;
      bool isRisky = false;

      if (category != null) {
        for (final act in category.activities) {
          if (act.name == actName) {
            activityEmoji = act.displayCharacter;
            activityDisplayName = act.name;
            isRisky = act.stiRisk || act.healthRisk;
            break;
          }
        }
      }

      activityEmoji ??= '❔';
      activityDisplayName ??= actName.isNotEmpty ? actName : 'Unknown';

      // Determine whether catRef is a subcategory (i.e. a parent references it).
      String? subcategoryLabel;
      final parentCategoryRef = activity.category.reference;
      if (catRef != parentCategoryRef) {
        // catRef is a subcategory — show its name as a group label.
        subcategoryLabel = category?.displayCharacter != null
            ? '${category!.displayCharacter}  ${category.name}'
            : category?.name;
      }

      // Resolve sort orders so rows respect the user's configured order.
      // subcategorySortOrder: use the subcategory's own sortOrder when catRef
      // is a subcategory, otherwise 0 so parent-level activities sort first.
      final rowCat = eventState.sexualActivityCategories?[catRef];
      int subcatSortOrder = 0;
      int actSortOrder = 0;
      if (rowCat != null) {
        if (catRef != parentCategoryRef) {
          // It's a subcategory — find its position inside the parent's
          // subCategories list, which reflects the user's reorder order.
          final parentCat =
              eventState.sexualActivityCategories?[parentCategoryRef];
          if (parentCat != null) {
            final subIdx = parentCat.subCategories.indexWhere(
              (r) => r.reference == catRef,
            );
            subcatSortOrder = subIdx >= 0 ? subIdx : rowCat.sortOrder;
          }
        }
        // Activity sortOrder within its owning category.
        final actIdx = rowCat.activities.indexWhere((a) => a.name == actName);
        if (actIdx >= 0) actSortOrder = rowCat.activities[actIdx].sortOrder;
      }

      rows.add(
        _ActivityRow(
          catRef: catRef,
          activityEmoji: activityEmoji,
          activityName: activityDisplayName,
          isRisky: isRisky,
          subcategoryLabel: subcategoryLabel,
          persons: entry.value,
          subcategorySortOrder: subcatSortOrder,
          activitySortOrder: actSortOrder,
        ),
      );
    }

    // Sort: no-activity rows first, then by subcategory sortOrder, then by
    // activity sortOrder — preserving the order the user set in Settings.
    rows.sort((a, b) {
      if (a.isNoActivity) return -1;
      if (b.isNoActivity) return 1;
      final subCmp = a.subcategorySortOrder.compareTo(b.subcategorySortOrder);
      if (subCmp != 0) return subCmp;
      return a.activitySortOrder.compareTo(b.activitySortOrder);
    });

    // ----------------------------------------------------------------
    // Render
    // ----------------------------------------------------------------

    // Separate no-activity rows from the rest, then bucket the rest by
    // subcategoryLabel (null = belongs directly to the parent category).
    final noActivityRows = rows.where((r) => r.isNoActivity).toList();
    final activityRows = rows.where((r) => !r.isNoActivity).toList();

    // Preserve insertion order while grouping.
    final grouped = <String?, List<_ActivityRow>>{};
    for (final row in activityRows) {
      grouped.putIfAbsent(row.subcategoryLabel, () => []).add(row);
    }

    final widgets = <Widget>[];

    // No-activity participants (no specific activity logged).
    for (final row in noActivityRows) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: row.persons.entries.map((e) {
              return PersonAvatar(person: e.key, radius: 16, showName: true);
            }).toList(),
          ),
        ),
      );
    }

    // Render each group.
    grouped.forEach((subcategoryLabel, groupRows) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));

      if (subcategoryLabel != null) {
        // ── Subcategory group: header + indented rows inside a container ──
        widgets.add(
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withOpacity(0.6),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                  ),
                  child: Text(
                    subcategoryLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                // Activity rows
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildActivityRowWidgets(context, groupRows),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // ── No subcategory: flat list ──
        widgets.addAll(_buildActivityRowWidgets(context, groupRows));
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<Widget> _buildActivityRowWidgets(
    BuildContext context,
    List<_ActivityRow> rows,
  ) {
    return rows.map((row) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(row.activityEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  row.activityName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (row.isRisky) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.warning,
                    size: 14,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: row.persons.entries.map((personEntry) {
                  return PersonAvatar(
                    person: personEntry.key,
                    radius: 16,
                    count: personEntry.value > 1 ? personEntry.value : null,
                    showName: true,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildButtonRow(
    BuildContext context,
    List<Person> persons,
    EventState eventState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Share'),
            onPressed: () {
              EventShareBottomSheet.show(
                context: context,
                event: widget.event,
                persons: persons,
                categories: eventState.sexualActivityCategories ?? {},
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SexualEventEditorPage(event: widget.event),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text(
            'Are you sure you want to delete this event? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        final provider = context.read<SexualEventsProvider>();
        await provider.deleteEvent(widget.event.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting event: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getEventTitleString(List<Person> persons) {
    if (persons.isEmpty) {
      return 'Event (no participants)';
    }
    return 'Event with ${persons.length} ${persons.length == 1 ? 'person' : 'people'}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Check if a category is a subcategory of another category
  bool _isSubcategory(SexualActivityCategory? category, EventState eventState) {
    if (category == null) return false;
    final categories = eventState.sexualActivityCategories;
    if (categories == null) return false;

    // A category is a subcategory if any other category lists it in subCategories
    for (final parent in categories.values) {
      if (parent.subCategories.any((ref) => ref.reference == category.id)) {
        return true;
      }
    }
    return false;
  }

  /// Get the parent category name for a subcategory
  String _getParentCategoryName(
    SexualActivityCategory? category,
    EventState eventState,
  ) {
    if (category == null) return '';
    final categories = eventState.sexualActivityCategories;
    if (categories == null) return '';

    for (final parent in categories.values) {
      if (parent.subCategories.any((ref) => ref.reference == category.id)) {
        return parent.name;
      }
    }
    return '';
  }
}

/// Data model for a single rendered row inside [_buildParticipantsBreakdown].
class _ActivityRow {
  final String catRef;
  final String activityEmoji;
  final String activityName;
  final bool isRisky;

  /// Non-null when this activity belongs to a subcategory distinct from the
  /// parent [EventActivity] category. Used as a visual group header.
  final String? subcategoryLabel;
  final Map<Person, int> persons;
  final bool isNoActivity;

  /// Sort order of the subcategory (or 0 for the parent category). Used to
  /// preserve the order the user configured in Settings.
  final int subcategorySortOrder;

  /// Sort order of the individual activity within its category.
  final int activitySortOrder;

  const _ActivityRow({
    required this.catRef,
    required this.activityEmoji,
    required this.activityName,
    required this.isRisky,
    required this.subcategoryLabel,
    required this.persons,
    this.isNoActivity = false,
    this.subcategorySortOrder = 0,
    this.activitySortOrder = 0,
  });

  factory _ActivityRow.noActivity(Map<Person, int> persons) => _ActivityRow(
    catRef: '',
    activityEmoji: '',
    activityName: '',
    isRisky: false,
    subcategoryLabel: null,
    persons: persons,
    isNoActivity: true,
  );
}
