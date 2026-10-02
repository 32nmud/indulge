// Utilities for filtering search results.
//
// Contains:
// - `filterSexualEvents` : pure function that filters a list of `SexualEvent`
//   according to the same rules used previously in the page state.
//
// Note: this file intentionally doesn't access providers or perform I/O;
// it operates on fully materialized data (lists of events) so it is easy to
// unit-test and reuse from different UI surfaces.

import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

/// Returns a filtered and sorted list of [SexualEvent] taken from [events]
/// applying the provided optional filters.
///
/// Behaviour mirrors the original `_performSearch` logic:
/// - Date range: inclusive of [dateRange.start] .. [dateRange.end]
/// - Notes: case-insensitive `contains` on `event.notes`
/// - Event type: 'Solo' / 'Couple' / 'Group' based on number of non-myself
///   partner references present in the event.
/// - Partner filter: event must include at least one of the provided partner ids
/// - Category filter: event must include at least one activity whose category
///   reference is present in [categoryIds]. If a parent category ID is in
///   [categoryIds], its subcategory IDs are automatically included so selecting
///   a parent matches events from any of its subcategories too.
/// - Activity filter: [activityKeys] contains composite keys "categoryId:activityId"
///   and an event matches if any of its participant activityCounts reference
///   one of those composite keys.
///
/// The returned list is sorted by date (most recent first).
List<SexualEvent> filterSexualEvents(
  List<SexualEvent> events, {
  DateTimeRange? dateRange,
  String? notesQuery,
  String? eventType, // 'Solo' | 'Couple' | 'Group'
  Set<String>? partnerIds,
  Set<String>? categoryIds,
  Map<String, SexualActivityCategory>? categoriesMap,
  Set<String>? activityKeys, // composite keys: "categoryId:activityId"
  String? myselfId,
}) {
  final query = (notesQuery ?? '').trim().toLowerCase();
  final hasQuery = query.isNotEmpty;

  final filtered = events.where((event) {
    // Date range filter (inclusive)
    if (dateRange != null) {
      final start = dateRange.start;
      final end = dateRange.end;
      if (event.date.isBefore(start) || event.date.isAfter(end)) {
        return false;
      }
    }

    // Notes filter
    if (hasQuery) {
      final notes = (event.notes ?? '').toLowerCase();
      if (!notes.contains(query)) return false;
    }

    // Event Type filter
    if (eventType != null) {
      // Collect partner ids referenced in event, excluding 'myself' if provided
      final partnerRefs = event.activities
          .expand((a) => a.participants)
          .map((p) => p.participant.reference)
          .cast<String>()
          .where((id) => id != myselfId)
          .toSet();

      if (eventType == 'Solo' && partnerRefs.isNotEmpty) return false;
      if (eventType == 'Couple' && partnerRefs.length != 1) return false;
      if (eventType == 'Group' && partnerRefs.length < 2) return false;
    }

    // Partner filter: require at least one selected partner referenced in the event
    if (partnerIds != null && partnerIds.isNotEmpty) {
      final eventPartnerIds = event.activities
          .expand((a) => a.participants)
          .map((p) => p.participant.reference)
          .cast<String>()
          .toSet();
      final intersects = partnerIds.any((id) => eventPartnerIds.contains(id));
      if (!intersects) return false;
    }

    // Category filter: require at least one activity category matches.
    // Expand each selected parent ID to also cover its subcategory IDs.
    if (categoryIds != null && categoryIds.isNotEmpty) {
      final expandedIds = <String>{};
      for (final id in categoryIds) {
        expandedIds.add(id);
        if (categoriesMap != null) {
          final cat = categoriesMap[id];
          if (cat != null) {
            for (final ref in cat.subCategories) {
              if (ref.reference.isNotEmpty) expandedIds.add(ref.reference);
            }
          }
        }
      }
      // Collect all category IDs referenced in this event — both the top-level
      // EventActivity category and any subcategory IDs stored in each
      // ActivityCount.categoryReference (which is where subcategory activities
      // are actually recorded).
      final eventCategoryIds = <String>{};
      for (final activity in event.activities) {
        eventCategoryIds.add(activity.category.reference);
        for (final participant in activity.participants) {
          for (final activityCount in participant.activityCounts) {
            final ref = activityCount.categoryReference.reference;
            if (ref.isNotEmpty) eventCategoryIds.add(ref);
          }
        }
      }
      final intersects = expandedIds.any((id) => eventCategoryIds.contains(id));
      if (!intersects) return false;
    }

    // Activity filter (composite keys)
    if (activityKeys != null && activityKeys.isNotEmpty) {
      var hasMatching = false;
      for (final activity in event.activities) {
        final catId = activity.category.reference;
        for (final participant in activity.participants) {
          for (final activityCount in participant.activityCounts) {
            final activityName = activityCount.activityName;
            // Use the categoryReference from the ActivityCount itself — this
            // stores the subcategory ID when the activity belongs to a
            // subcategory, not the parent EventActivity category ID.
            final actCountCatId =
                activityCount.categoryReference.reference.isNotEmpty
                ? activityCount.categoryReference.reference
                : catId;
            final composite = '$actCountCatId:$activityName';
            if (activityKeys.contains(composite)) {
              hasMatching = true;
              break;
            }
          }
          if (hasMatching) break;
        }
        if (hasMatching) break;
      }
      if (!hasMatching) return false;
    }

    return true;
  }).toList();

  // Sort by date descending (most recent first)
  filtered.sort((a, b) => b.date.compareTo(a.date));

  return filtered;
}
