import 'package:indulge/data/models.dart';

// ── Hierarchy data models ─────────────────────────────────────────────────────

class HierarchyActivity {
  final String emoji;
  final String name;
  final int count;
  final int uniquePartners;
  final bool stiRisk;
  final bool healthRisk;
  final bool isActionable;

  const HierarchyActivity({
    required this.emoji,
    required this.name,
    required this.count,
    required this.uniquePartners,
    required this.stiRisk,
    required this.healthRisk,
    this.isActionable = true,
  });
}

class HierarchySub {
  final SexualActivityCategory sub;
  final int totalCount;
  final int uniquePartners;
  final List<HierarchyActivity> activities;

  const HierarchySub({
    required this.sub,
    required this.totalCount,
    required this.activities,
    this.uniquePartners = 0,
  });
}

class HierarchyCat {
  final SexualActivityCategory category;
  final int totalCount;
  final List<HierarchyActivity> directActivities;
  final List<HierarchySub> subGroups;
  final int uniquePartners;

  /// True if this category contains any actionable activities; false = gear/items only.
  final bool isActionable;

  const HierarchyCat({
    required this.category,
    required this.totalCount,
    required this.directActivities,
    required this.subGroups,
    this.uniquePartners = 0,
    this.isActionable = true,
  });

  int get maxActivityCount {
    int m = 1;
    for (final a in directActivities) {
      if (a.count > m) m = a.count;
    }
    for (final g in subGroups) {
      for (final a in g.activities) {
        if (a.count > m) m = a.count;
      }
    }
    return m;
  }
}

// ── Partner row data ──────────────────────────────────────────────────────────

class PartnerRowData {
  final Person person;
  final int eventCount;
  final int activityCount;
  final int anonymousIndex;

  const PartnerRowData({
    required this.person,
    required this.eventCount,
    required this.activityCount,
    required this.anonymousIndex,
  });
}

// ── Category mix entry ────────────────────────────────────────────────────────

class CategoryMixEntry {
  final String id;
  final String emoji;
  final String name;
  final int count;

  const CategoryMixEntry({
    required this.id,
    required this.emoji,
    required this.name,
    required this.count,
  });
}

// ── Time-of-day bucket ────────────────────────────────────────────────────────

enum ShareTimeOfDay { morning, afternoon, evening, night }
