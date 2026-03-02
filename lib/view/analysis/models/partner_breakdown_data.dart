import 'package:indulge/data/models.dart';

class PartnerBreakdownData {
  /// Full map of all categories from the store (including subcategories).
  /// Used by widgets that need to show the nested category hierarchy.
  final Map<String, SexualActivityCategory> allCategoriesMap;
  final Map<String, int> personCounts;
  final Map<String, int> personEventCounts;
  final Map<String, List<SexualEvent>> personEvents;
  final Map<String, Map<String, int>> personPropertyCounts;
  final int uniquePartners;
  final int knownPartners;
  final int anonymousPartnerInstances;
  final int uniquePartnersThisYear;
  final int uniquePartnersThisMonth;
  final Map<String, int> sexualActivityPartnerCounts;
  final Map<String, int> categoryPartnerCountsThisYear;
  final Map<String, int> sexualActivityPartnerCountsThisYear;
  final Map<String, Map<String, int>> categoryActivityPartnerCountsThisYear;
  final Map<String, SexualActivity> sexualActivities;
  final Map<String, SexualActivityCategory> activityCategories;
  final Map<String, Person> personMap;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<SexualEvent> events;

  const PartnerBreakdownData({
    required this.allCategoriesMap,
    required this.personCounts,
    required this.personEventCounts,
    required this.personEvents,
    required this.personPropertyCounts,
    required this.uniquePartners,
    required this.knownPartners,
    required this.anonymousPartnerInstances,
    required this.uniquePartnersThisYear,
    required this.uniquePartnersThisMonth,
    required this.sexualActivityPartnerCounts,
    required this.categoryPartnerCountsThisYear,
    required this.sexualActivityPartnerCountsThisYear,
    required this.categoryActivityPartnerCountsThisYear,
    required this.sexualActivities,
    required this.activityCategories,
    required this.personMap,
    this.startDate,
    this.endDate,
    required this.events,
  });

  factory PartnerBreakdownData.empty() {
    return const PartnerBreakdownData(
      allCategoriesMap: {},
      personCounts: {},
      personEventCounts: {},
      personEvents: {},
      personPropertyCounts: {},
      uniquePartners: 0,
      knownPartners: 0,
      anonymousPartnerInstances: 0,
      uniquePartnersThisYear: 0,
      uniquePartnersThisMonth: 0,
      sexualActivityPartnerCounts: {},
      categoryPartnerCountsThisYear: {},
      sexualActivityPartnerCountsThisYear: {},
      categoryActivityPartnerCountsThisYear: {},
      sexualActivities: {},
      activityCategories: {},
      personMap: {},
      events: [],
    );
  }
}
