import 'package:indulge/data/models.dart';
import '../../models/co_occurance_pair.dart';

/// Calculates co-occurrence pairs for activity categories and sexual activities.
///
/// A co-occurrence is when two categories or two sexual activities appear
/// together in the same event. The results are sorted by frequency (descending).
class CoOccurrenceCalculator {
  /// Computes the top co-occurring category pairs and sexual activity pairs
  /// across all [sortedEvents].
  ///
  /// [activityCategories] and [sexualActivities] are used to resolve display
  /// names for the resulting pairs.
  static CoOccurrenceResult calculate(
    List<SexualEvent> sortedEvents, {
    required Map<String, SexualActivityCategory> activityCategories,
    required Map<String, SexualActivity> sexualActivities,
  }) {
    final categoryPairCounts = <String, int>{};
    final activityPairCounts = <String, int>{};

    for (final event in sortedEvents) {
      final eventCategoryIds = <String>{};
      final eventActivityIds = <String>{};

      for (final activity in event.activities) {
        eventCategoryIds.add(activity.category.reference);
        for (final participant in activity.participants) {
          for (final activityCount in participant.activityCounts) {
            // Use categoryReference as the activity identifier (since activities don't have IDs)
            eventActivityIds.add(activityCount.categoryReference.reference);
          }
        }
      }

      // Category pairs
      final categoryList = eventCategoryIds.toList()..sort();
      for (int i = 0; i < categoryList.length; i++) {
        for (int j = i + 1; j < categoryList.length; j++) {
          final key = '${categoryList[i]}|${categoryList[j]}';
          categoryPairCounts[key] = (categoryPairCounts[key] ?? 0) + 1;
        }
      }

      // Sexual activity pairs
      final activityList = eventActivityIds.toList()..sort();
      for (int i = 0; i < activityList.length; i++) {
        for (int j = i + 1; j < activityList.length; j++) {
          final key = '${activityList[i]}|${activityList[j]}';
          activityPairCounts[key] = (activityPairCounts[key] ?? 0) + 1;
        }
      }
    }

    final topCategoryPairs = categoryPairCounts.entries.map((e) {
      final parts = e.key.split('|');
      final id1 = parts[0];
      final id2 = parts[1];
      return CoOccurrencePair(
        id1: id1,
        id2: id2,
        name1: activityCategories[id1]?.name ?? 'Unknown',
        name2: activityCategories[id2]?.name ?? 'Unknown',
        count: e.value,
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));

    final topActivityPairs = activityPairCounts.entries.map((e) {
      final parts = e.key.split('|');
      final id1 = parts[0];
      final id2 = parts[1];
      return CoOccurrencePair(
        id1: id1,
        id2: id2,
        name1: sexualActivities[id1]?.name ?? 'Unknown',
        name2: sexualActivities[id2]?.name ?? 'Unknown',
        count: e.value,
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));

    return CoOccurrenceResult(
      topCategoryPairs: topCategoryPairs,
      topActivityPairs: topActivityPairs,
    );
  }
}

/// Holds the results of a co-occurrence calculation.
class CoOccurrenceResult {
  final List<CoOccurrencePair> topCategoryPairs;
  final List<CoOccurrencePair> topActivityPairs;

  const CoOccurrenceResult({
    required this.topCategoryPairs,
    required this.topActivityPairs,
  });
}
