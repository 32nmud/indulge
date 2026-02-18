/// Converts Set-based partner tracking maps into simple integer count maps
/// for use in the final [AnalysisData] object.
class PartnerCountConverter {
  /// Converts a map of `{id: Set<partnerId>}` into `{id: partnerCount}`.
  static Map<String, int> convertPartnerCounts(
    Map<String, Set<String>> partnerSets,
  ) {
    return {
      for (final entry in partnerSets.entries) entry.key: entry.value.length,
    };
  }

  /// Converts a nested map of `{categoryId: {activityId: Set<partnerId>}}`
  /// into `{categoryId: {activityId: partnerCount}}`.
  static Map<String, Map<String, int>> convertNestedPartnerCounts(
    Map<String, Map<String, Set<String>>> nestedPartnerSets,
  ) {
    final result = <String, Map<String, int>>{};
    for (final categoryEntry in nestedPartnerSets.entries) {
      result[categoryEntry.key] = {
        for (final activityEntry in categoryEntry.value.entries)
          activityEntry.key: activityEntry.value.length,
      };
    }
    return result;
  }
}
