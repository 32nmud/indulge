import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/analysis/models/activity_breakdown_data.dart';
import 'package:indulge/view/analysis/models/analysis_event_type.dart';
import 'package:indulge/view/analysis/models/overview_data.dart';
import 'package:indulge/view/analysis/models/partner_breakdown_data.dart';
import 'package:indulge/view/analysis/share/share_activity_hierarchy.dart';
import 'package:indulge/view/analysis/share/share_card_models.dart';
import 'package:indulge/view/analysis/share/share_card_widgets.dart';
import 'package:indulge/view/analysis/share/share_charts.dart';
import 'package:indulge/view/analysis/share/share_overview_section.dart';
import 'package:indulge/view/analysis/share/share_partner_section.dart';
import 'package:indulge/view/analysis/share/share_right_column.dart';
import 'package:indulge/view/common/share/share_card_theme.dart';

/// A wide (1920 px) dashboard-style export card.
///
/// Sections top-to-bottom:
///   1. Header (time-window label + optional privacy badge)
///   2. Overview stats + Averages
///   3. Event-type bar + legend
///   4. Monthly bar-chart | Activity-log heatmap
///   5. Time-of-Day | Day-of-Week patterns
///   6. Activities hierarchy (3 cols) | Partners + Mix + Records
///   7. Watermark
///
/// When [privacyMode] is true, partner names are replaced with "Partner N"
/// and avatars are hidden so the card can be shared without exposing identities.
///
/// Intentionally provider-free; all data is passed directly.
class AnalysisShareCard extends StatelessWidget {
  final OverviewData overviewData;
  final ActivityBreakdownData activityData;
  final PartnerBreakdownData partnerData;
  final String timeWindowLabel;

  /// When true, partner names and photos are anonymised.
  final bool privacyMode;

  // Layout constants
  static const double _hPad = 48.0;
  static const double _sectionGap = 28.0;
  static const double _colGap = 32.0;

  const AnalysisShareCard({
    super.key,
    required this.overviewData,
    required this.activityData,
    required this.partnerData,
    required this.timeWindowLabel,
    this.privacyMode = false,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  // ── Flat partner-count map ────────────────────────────────────────────────

  /// Builds a composite-key → unique-partner-count map by merging all inner
  /// maps of [partnerData.categoryActivityPartnerCountsThisYear].
  static Map<String, int> _buildFlatPartnerCounts(
    PartnerBreakdownData partnerData,
  ) {
    final flat = <String, int>{};
    for (final inner
        in partnerData.categoryActivityPartnerCountsThisYear.values) {
      for (final entry in inner.entries) {
        if ((flat[entry.key] ?? 0) < entry.value) {
          flat[entry.key] = entry.value;
        }
      }
    }
    return flat;
  }

  // ── Hierarchy builders ────────────────────────────────────────────────────

  List<HierarchyActivity> _activitiesForCatId(
    String catId,
    Map<String, int> flatPartnerCounts,
  ) {
    final prefix = '$catId:';
    final result = <HierarchyActivity>[];
    for (final entry in activityData.sexualActivityCountsTotal.entries) {
      if (!entry.key.startsWith(prefix) || entry.value == 0) continue;
      final actName = entry.key.substring(prefix.length);
      final sexAct = activityData.sexualActivities[entry.key];
      SexualActivity? fallback;
      if (sexAct == null) {
        final cat = activityData.allCategoriesMap[catId];
        if (cat != null) {
          for (final a in cat.activities) {
            if (a.name == actName) {
              fallback = a;
              break;
            }
          }
        }
      }
      result.add(
        HierarchyActivity(
          emoji: sexAct?.displayCharacter ?? fallback?.displayCharacter ?? '❔',
          name: actName,
          count: entry.value,
          uniquePartners: flatPartnerCounts[entry.key] ?? 0,
          stiRisk: sexAct?.stiRisk ?? fallback?.stiRisk ?? false,
          healthRisk: sexAct?.healthRisk ?? fallback?.healthRisk ?? false,
          isActionable: sexAct?.isActionable ?? fallback?.isActionable ?? true,
        ),
      );
    }
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  List<HierarchyCat> _buildCategoryHierarchy(
    Map<String, int> flatPartnerCounts,
  ) {
    final all = activityData.allCategoriesMap;

    final subIds = <String>{};
    for (final cat in all.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) subIds.add(ref.reference);
      }
    }

    final topLevel = all.values.where((c) => !subIds.contains(c.id)).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final result = <HierarchyCat>[];

    for (final cat in topLevel) {
      final subs = cat.subCategories
          .where((r) => r.reference.isNotEmpty)
          .map((r) => all[r.reference])
          .whereType<SexualActivityCategory>()
          .toList();

      final subGroups = <HierarchySub>[];
      for (final sub in subs) {
        final acts = _activitiesForCatId(
          sub.id,
          flatPartnerCounts,
        ).take(6).toList();
        if (acts.isEmpty) continue;
        subGroups.add(
          HierarchySub(
            sub: sub,
            totalCount: acts.fold(0, (int s, a) => s + a.count),
            activities: acts,
            uniquePartners:
                partnerData.sexualActivityPartnerCounts[sub.id] ?? 0,
          ),
        );
      }

      final directActivities = _activitiesForCatId(
        cat.id,
        flatPartnerCounts,
      ).take(6).toList();
      final total =
          directActivities.fold<int>(0, (s, a) => s + a.count) +
          subGroups.fold<int>(0, (s, g) => s + g.totalCount);

      if (total == 0) continue;

      bool catIsActionable = directActivities.any((a) => a.isActionable);
      if (!catIsActionable) {
        catIsActionable = subGroups.any(
          (sg) => sg.activities.any((a) => a.isActionable),
        );
      }

      result.add(
        HierarchyCat(
          category: cat,
          totalCount: total,
          directActivities: directActivities,
          subGroups: subGroups,
          uniquePartners: partnerData.sexualActivityPartnerCounts[cat.id] ?? 0,
          isActionable: catIsActionable,
        ),
      );
    }

    result.sort((a, b) => b.totalCount.compareTo(a.totalCount));
    return result;
  }

  List<PartnerRowData> _topPartners({int limit = 6}) {
    final rows = <PartnerRowData>[];
    int index = 0;
    final sorted = partnerData.personEventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      if (rows.length >= limit) break;
      final person = partnerData.personMap[entry.key];
      if (person == null) continue;
      rows.add(
        PartnerRowData(
          person: person,
          eventCount: entry.value,
          activityCount: partnerData.personCounts[entry.key] ?? 0,
          anonymousIndex: ++index,
        ),
      );
    }
    return rows;
  }

  Map<ShareTimeOfDay, int> _timeOfDayCounts() {
    final counts = {
      ShareTimeOfDay.morning: 0,
      ShareTimeOfDay.afternoon: 0,
      ShareTimeOfDay.evening: 0,
      ShareTimeOfDay.night: 0,
    };
    for (final event in overviewData.events) {
      final h = event.date.hour;
      final bucket = h >= 4 && h < 12
          ? ShareTimeOfDay.morning
          : h >= 12 && h < 17
          ? ShareTimeOfDay.afternoon
          : h >= 17 && h < 23
          ? ShareTimeOfDay.evening
          : ShareTimeOfDay.night;
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return counts;
  }

  List<CategoryMixEntry> _buildCategoryMix({int limit = 8}) {
    final subIds = <String>{};
    for (final cat in activityData.allCategoriesMap.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) subIds.add(ref.reference);
      }
    }
    final entries = <CategoryMixEntry>[];
    for (final entry in activityData.activityCounts.entries) {
      if (subIds.contains(entry.key) || entry.value == 0) continue;
      final cat = activityData.allCategoriesMap[entry.key];
      if (cat == null) continue;
      entries.add(
        CategoryMixEntry(
          id: entry.key,
          emoji: cat.displayCharacter ?? '❔',
          name: cat.name,
          count: entry.value,
        ),
      );
    }
    entries.sort((a, b) => b.count.compareTo(a.count));
    return entries.take(limit).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final flatPartnerCounts = _buildFlatPartnerCounts(partnerData);
    final hierarchy = _buildCategoryHierarchy(flatPartnerCounts);
    final actionableHierarchy = hierarchy.where((c) => c.isActionable).toList();
    final gearHierarchy = hierarchy.where((c) => !c.isActionable).toList();
    final topPartners = _topPartners();
    final categoryMix = _buildCategoryMix();
    final todCounts = _timeOfDayCounts();
    final dowAverages = activityData.averageEventsPerDayOfWeek;

    final maxCatCount = hierarchy.isEmpty
        ? 1
        : hierarchy.map((r) => r.totalCount).reduce((a, b) => a > b ? a : b);
    final maxPartnerEvents = topPartners.isEmpty
        ? 1
        : topPartners.map((r) => r.eventCount).reduce((a, b) => a > b ? a : b);

    final hasTimeOfDayData = todCounts.values.any((v) => v > 0);
    final hasDowData =
        dowAverages.isNotEmpty && dowAverages.values.any((v) => v > 0);

    final solo = overviewData.eventCountsByType[AnalysisEventType.solo] ?? 0;
    final couple =
        overviewData.eventCountsByType[AnalysisEventType.couple] ?? 0;
    final group = overviewData.eventCountsByType[AnalysisEventType.group] ?? 0;
    final typeTotal = solo + couple + group;

    final now = DateTime.now();
    final heatmapEnd = overviewData.endDate ?? now;
    final heatmapStart =
        overviewData.startDate ?? DateTime(now.year - 1, now.month, now.day);

    return SizedBox(
      width: ShareCardTheme.analysisCardWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ShareCardTheme.cardRadius),
        child: Container(
          decoration: const BoxDecoration(
            gradient: ShareCardTheme.backgroundGradient,
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Decorative background circles ──────────────────────────
              const Positioned(
                top: -100,
                right: -80,
                child: ShareCardCircle(size: 500, color: Color(0x0E7C6FCD)),
              ),
              const Positioned(
                top: 600,
                left: -100,
                child: ShareCardCircle(size: 380, color: Color(0x09796FCD)),
              ),
              const Positioned(
                bottom: 100,
                right: -60,
                child: ShareCardCircle(size: 300, color: Color(0x08796FCD)),
              ),

              // ── Main content ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 28, _hPad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Row(
                      children: [
                        ShareCardSectionLabel(timeWindowLabel),
                        if (privacyMode) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4DB6AC).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFF4DB6AC,
                                ).withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 13,
                                  color: Color(0xFF4DB6AC),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Partners anonymised',
                                  style: TextStyle(
                                    color: Color(0xFF4DB6AC),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── Overview stats + Averages ──────────────────────
                    const ShareCardSectionHeading(
                      icon: Icons.dashboard_outlined,
                      title: 'Overview',
                    ),
                    const SizedBox(height: 14),

                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ShareStatCell(
                              icon: Icons.local_fire_department,
                              label: 'Total Events',
                              value: overviewData.totalEvents.toString(),
                              color: ShareCardTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ShareStatCell(
                              icon: Icons.bolt_outlined,
                              label: 'Activities',
                              value: overviewData.totalActivities.toString(),
                              color: ShareCardTheme.riskModerate,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ShareStatCell(
                              icon: Icons.people_outline,
                              label: 'Unique Partners',
                              value: overviewData.uniquePartners.toString(),
                              color: ShareCardTheme.couple,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ShareStatCell(
                              icon: Icons.emoji_events_outlined,
                              label: 'Longest Streak',
                              value: overviewData.longestStreak.toString(),
                              subtitle: overviewData.longestStreak == 1
                                  ? 'day'
                                  : 'days',
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(width: 1, color: ShareCardTheme.divider),
                          const SizedBox(width: 16),
                          // 2×2 averages grid
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ShareAverageCell(
                                          label: 'Events / week',
                                          value: _fmt(
                                            activityData.averageEventsPerWeek,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ShareAverageCell(
                                          label: 'Events / month',
                                          value: _fmt(
                                            activityData.averageEventsPerMonth,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ShareAverageCell(
                                          label: 'Partners / event',
                                          value: _fmt(
                                            activityData
                                                .averagePartnersPerEvent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ShareAverageCell(
                                          label: 'Acts / event',
                                          value: _fmt(
                                            activityData
                                                .averageActivitiesPerEvent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Event type bar ─────────────────────────────────
                    if (typeTotal > 0) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 10,
                          child: Row(
                            children: [
                              if (solo > 0)
                                Expanded(
                                  flex: solo,
                                  child: Container(color: ShareCardTheme.solo),
                                ),
                              if (couple > 0)
                                Expanded(
                                  flex: couple,
                                  child: Container(
                                    color: ShareCardTheme.couple,
                                  ),
                                ),
                              if (group > 0)
                                Expanded(
                                  flex: group,
                                  child: Container(color: ShareCardTheme.group),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ShareCardTypeLegendDot(
                            label: 'Solo  $solo',
                            color: ShareCardTheme.solo,
                          ),
                          const SizedBox(width: 20),
                          ShareCardTypeLegendDot(
                            label: 'Couple  $couple',
                            color: ShareCardTheme.couple,
                          ),
                          const SizedBox(width: 20),
                          ShareCardTypeLegendDot(
                            label: 'Group  $group',
                            color: ShareCardTheme.group,
                          ),
                        ],
                      ),
                    ],

                    // ── Role breakdown ────────────────────────────────
                    if (activityData.userRoleCounts.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const ShareCardSectionHeading(
                        icon: Icons.swap_horiz,
                        title: 'Your Role Breakdown',
                      ),
                      const SizedBox(height: 14),
                      ShareRoleBreakdownChart(
                        roleCounts: activityData.userRoleCounts,
                      ),
                    ],

                    SizedBox(height: _sectionGap),
                    const Divider(color: ShareCardTheme.divider, height: 1),
                    SizedBox(height: _sectionGap),

                    // ── Charts row: Monthly bar + Heatmap ──────────────
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const ShareCardSectionHeading(
                                  icon: Icons.bar_chart_outlined,
                                  title: 'Monthly Activity (total events)',
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 200,
                                  child: ShareMonthlyBarChart(
                                    monthlyCounts: overviewData.monthlyCounts,
                                    startDate: overviewData.startDate,
                                    endDate: overviewData.endDate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            margin: EdgeInsets.symmetric(
                              horizontal: _colGap / 2,
                            ),
                            color: ShareCardTheme.divider,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const ShareCardSectionHeading(
                                  icon: Icons.grid_on_outlined,
                                  title: 'Activity Log',
                                ),
                                const SizedBox(height: 14),
                                ShareActivityHeatmap(
                                  dailyCounts: overviewData.dailyCounts,
                                  startDate: heatmapStart,
                                  endDate: heatmapEnd,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Patterns row: Time of Day + Day of Week ────────
                    if (hasTimeOfDayData || hasDowData) ...[
                      SizedBox(height: _sectionGap),
                      const Divider(color: ShareCardTheme.divider, height: 1),
                      SizedBox(height: _sectionGap),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasTimeOfDayData)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const ShareCardSectionHeading(
                                      icon: Icons.schedule_outlined,
                                      title: 'Time of Day',
                                    ),
                                    const SizedBox(height: 16),
                                    ShareTimeOfDayChart(counts: todCounts),
                                  ],
                                ),
                              ),
                            if (hasTimeOfDayData && hasDowData)
                              Container(
                                width: 1,
                                margin: EdgeInsets.symmetric(
                                  horizontal: _colGap / 2,
                                ),
                                color: ShareCardTheme.divider,
                              ),
                            if (hasDowData)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const ShareCardSectionHeading(
                                      icon: Icons.view_week_outlined,
                                      title: 'Day of Week (avg. events)',
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      height: 160,
                                      child: ShareDayOfWeekChart(
                                        averages: dowAverages,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: _sectionGap),
                    const Divider(color: ShareCardTheme.divider, height: 1),
                    SizedBox(height: _sectionGap),

                    // ── Activities (left 3/4) + Partners/Stats (right 1/4)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Left: Activities + Gear ────────────────────
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Partner badge legend key
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ShareCardTheme.couple.withOpacity(
                                        0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: ShareCardTheme.couple
                                            .withOpacity(0.35),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 10,
                                          color: ShareCardTheme.couple,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'N',
                                          style: TextStyle(
                                            color: ShareCardTheme.couple,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '= unique partners this year',
                                    style: TextStyle(
                                      color: ShareCardTheme.textMuted,
                                      fontSize: 17,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              const ShareCardSectionHeading(
                                icon: Icons.category_outlined,
                                title: 'Activities',
                              ),
                              const SizedBox(height: 10),
                              if (actionableHierarchy.isEmpty)
                                const ShareCardEmptyState('No activity data')
                              else
                                ShareThreeColumnHierarchy(
                                  cats: actionableHierarchy,
                                  maxCount: maxCatCount,
                                ),

                              if (gearHierarchy.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const ShareCardSectionHeading(
                                  icon: Icons.hardware_outlined,
                                  title: 'Gear & Items',
                                ),
                                const SizedBox(height: 10),
                                ShareThreeColumnHierarchy(
                                  cats: gearHierarchy,
                                  maxCount: maxCatCount,
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(width: _colGap),

                        // ── Right: Partners + Mix + Records ───────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ShareCardSectionHeading(
                                icon: Icons.people_outline,
                                title: 'Top Partners',
                              ),
                              const SizedBox(height: 14),
                              if (topPartners.isEmpty)
                                const ShareCardEmptyState('No partner data')
                              else
                                ...topPartners.map(
                                  (row) => SharePartnerBarRow(
                                    row: row,
                                    maxEvents: maxPartnerEvents,
                                    privacyMode: privacyMode,
                                  ),
                                ),

                              if (categoryMix.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Divider(
                                  color: ShareCardTheme.divider,
                                  height: 1,
                                ),
                                const SizedBox(height: 16),
                                const ShareCardSectionHeading(
                                  icon: Icons.donut_small_outlined,
                                  title: 'Activity Mix',
                                ),
                                const SizedBox(height: 12),
                                ShareCategoryMixBar(entries: categoryMix),
                              ],

                              if (overviewData.busiestDay != null ||
                                  overviewData.busiestEvent != null) ...[
                                const SizedBox(height: 20),
                                const Divider(
                                  color: ShareCardTheme.divider,
                                  height: 1,
                                ),
                                const SizedBox(height: 16),
                                const ShareCardSectionHeading(
                                  icon: Icons.military_tech_outlined,
                                  title: 'Records',
                                ),
                                const SizedBox(height: 12),
                                ShareRecordsBlock(overviewData: overviewData),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Watermark ──────────────────────────────────────
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'made with indulge 💜',
                            style: TextStyle(
                              color: Color(0x4DADA8CC),
                              fontSize: 18,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
