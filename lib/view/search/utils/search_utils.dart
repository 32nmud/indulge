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
///   reference is present in [categoryIds].
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

    // Category filter: require at least one activity category matches
    if (categoryIds != null && categoryIds.isNotEmpty) {
      final eventCategoryIds = event.activities
          .map((a) => a.category.reference)
          .cast<String>()
          .toSet();
      final intersects = categoryIds.any((id) => eventCategoryIds.contains(id));
      if (!intersects) return false;
    }

    // Activity filter (composite keys)
    if (activityKeys != null && activityKeys.isNotEmpty) {
      var hasMatching = false;
      for (final activity in event.activities) {
        final catId = activity.category.reference;
        for (final participant in activity.participants) {
          for (final activityCount in participant.activityCounts) {
            final activityId = activityCount.activityReference.reference;
            final composite = '$catId:$activityId';
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
