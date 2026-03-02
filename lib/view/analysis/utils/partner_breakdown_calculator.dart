import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/provider/sexual_event_provider.dart';

import 'person_cache.dart';
import 'calculator_utils/event_aggregator.dart';
import '../models/partner_breakdown_data.dart';

/// Calculator specifically for the Partner Breakdown page.
///
/// Computes statistics like top partners, partner diversity,
/// and property counts per partner.
class PartnerBreakdownCalculator {
  /// Computes partner breakdown statistics from the given events.
  static Future<PartnerBreakdownData> calculate({
    required List<SexualEvent> events,
    required SexualEventsProvider provider,
    required EventState stateSnapshot,
    DateTime? startDate,
    DateTime? endDate,
    List<Person>? preFetchedPersons,
  }) async {
    if (events.isEmpty) {
      return PartnerBreakdownData.empty();
    }

    // Sort events by date
    final sortedEvents = List<SexualEvent>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Build person cache
    final personCache = await PersonCache.build(
      provider,
      preFetched: preFetchedPersons ?? stateSnapshot.selectedEventParticipants,
    );

    // Aggregate events
    final agg = EventAggregator.aggregate(
      sortedEvents,
      personCache,
      stateSnapshot.sexualActivityCategories,
      stateSnapshot.sexualActivities,
      startDate: startDate,
    );

    // Calculate known partners
    final knownPartners = agg.personCounts.keys
        .where((id) => id != 'anonymous')
        .length;

    // Build person map for UI
    final personMap = <String, Person>{};
    if (preFetchedPersons != null) {
      for (final p in preFetchedPersons) {
        personMap[p.id] = p;
      }
    } else {
      // Build from personCache persons
      for (final person in personCache.persons) {
        personMap[person.id] = person;
      }
    }

    // Get sexual activity partner counts mapped to int
    final sexualActivityPartnerCounts = <String, int>{};
    for (final entry in agg.sexualActivityPartnerCounts.entries) {
      sexualActivityPartnerCounts[entry.key] = entry.value.length;
    }

    // Get category partner counts this year mapped to int
    final categoryPartnerCountsThisYear = <String, int>{};
    for (final entry in agg.categoryPartnerCountsThisYear.entries) {
      categoryPartnerCountsThisYear[entry.key] = entry.value.length;
    }

    // Get sexual activity partner counts this year mapped to int
    final sexualActivityPartnerCountsThisYear = <String, int>{};
    for (final entry in agg.sexualActivityPartnerCountsThisYear.entries) {
      sexualActivityPartnerCountsThisYear[entry.key] = entry.value.length;
    }

    // Get category activity partner counts this year mapped to int
    final categoryActivityPartnerCountsThisYear = <String, Map<String, int>>{};
    for (final categoryEntry
        in agg.categoryActivityPartnerCountsThisYear.entries) {
      final activityMap = <String, int>{};
      for (final activityEntry in categoryEntry.value.entries) {
        activityMap[activityEntry.key] = activityEntry.value.length;
      }
      categoryActivityPartnerCountsThisYear[categoryEntry.key] = activityMap;
    }

    return PartnerBreakdownData(
      allCategoriesMap: stateSnapshot.sexualActivityCategories ?? {},
      personCounts: agg.personCounts,
      personEventCounts: agg.personEventCounts,
      personEvents: agg.personEvents,
      personPropertyCounts: agg.personPropertyCounts,
      uniquePartners: agg.personCounts.length,
      knownPartners: knownPartners,
      anonymousPartnerInstances: agg.anonymousPartnerInstances,
      uniquePartnersThisYear: agg.uniquePartnersThisYear,
      uniquePartnersThisMonth: agg.uniquePartnersThisMonth,
      sexualActivityPartnerCounts: sexualActivityPartnerCounts,
      categoryPartnerCountsThisYear: categoryPartnerCountsThisYear,
      sexualActivityPartnerCountsThisYear: sexualActivityPartnerCountsThisYear,
      categoryActivityPartnerCountsThisYear:
          categoryActivityPartnerCountsThisYear,
      sexualActivities: agg.sexualActivities,
      activityCategories: agg.activityCategories,
      personMap: personMap,
      startDate: startDate,
      endDate: endDate,
      events: events,
    );
  }
}
