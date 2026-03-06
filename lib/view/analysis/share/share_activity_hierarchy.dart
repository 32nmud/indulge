import 'package:flutter/material.dart';
import 'package:indulge/view/analysis/share/share_card_models.dart';
import 'package:indulge/view/common/share/share_card_theme.dart';

// ── Three-column masonry layout ───────────────────────────────────────────────

class ShareThreeColumnHierarchy extends StatelessWidget {
  final List<HierarchyCat> cats;
  final int maxCount;

  const ShareThreeColumnHierarchy({
    super.key,
    required this.cats,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < cats.length; i += 3)
                ShareCatHierarchyBlock(cat: cats[i], maxCount: maxCount),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 1; i < cats.length; i += 3)
                ShareCatHierarchyBlock(cat: cats[i], maxCount: maxCount),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 2; i < cats.length; i += 3)
                ShareCatHierarchyBlock(cat: cats[i], maxCount: maxCount),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Category block ────────────────────────────────────────────────────────────

class ShareCatHierarchyBlock extends StatelessWidget {
  final HierarchyCat cat;
  final int maxCount;

  const ShareCatHierarchyBlock({
    super.key,
    required this.cat,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0
        ? (cat.totalCount / maxCount).clamp(0.0, 1.0)
        : 0.0;
    final fillFlex = (fraction * 1000).round().clamp(1, 1000);
    final emptyFlex = (1000 - fillFlex).clamp(0, 999);
    final maxAct = cat.maxActivityCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ShareCardTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ShareCardTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Category header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0x2A7C6FCD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Text(
                  cat.category.displayCharacter ?? '❔',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat.category.name,
                    style: const TextStyle(
                      color: ShareCardTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                // Unique partners badge
                if (cat.uniquePartners > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ShareCardTheme.couple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ShareCardTheme.couple.withOpacity(0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 11,
                          color: ShareCardTheme.couple,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${cat.uniquePartners}',
                          style: const TextStyle(
                            color: ShareCardTheme.couple,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                // Total count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ShareCardTheme.accent.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cat.totalCount}×',
                    style: const TextStyle(
                      color: ShareCardTheme.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Progress bar ─────────────────────────────────────────────────
          ClipRRect(
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  Expanded(
                    flex: fillFlex,
                    child: Container(color: ShareCardTheme.accent),
                  ),
                  if (emptyFlex > 0)
                    Expanded(
                      flex: emptyFlex,
                      child: Container(color: ShareCardTheme.surfaceHigh),
                    ),
                ],
              ),
            ),
          ),

          // ── Activities / subcategories ────────────────────────────────────
          if (cat.subGroups.isNotEmpty || cat.directActivities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final sub in cat.subGroups) ...[
                    ShareSubGroupBlock(sub: sub, maxAct: maxAct),
                    const SizedBox(height: 6),
                  ],
                  if (cat.directActivities.isNotEmpty) ...[
                    if (cat.subGroups.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Divider(
                          color: ShareCardTheme.divider,
                          height: 1,
                        ),
                      ),
                    ...cat.directActivities.map(
                      (a) => ShareActivityRow(activity: a, maxCount: maxAct),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Subcategory block ─────────────────────────────────────────────────────────

class ShareSubGroupBlock extends StatelessWidget {
  final HierarchySub sub;
  final int maxAct;

  const ShareSubGroupBlock({
    super.key,
    required this.sub,
    required this.maxAct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ShareCardTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ShareCardTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Subcategory header ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0x1AAB47BC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Text(
                  sub.sub.displayCharacter ?? '❔',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    sub.sub.name,
                    style: const TextStyle(
                      color: ShareCardTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sub.uniquePartners > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: ShareCardTheme.couple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ShareCardTheme.couple.withOpacity(0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 10,
                          color: ShareCardTheme.couple,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${sub.uniquePartners}',
                          style: const TextStyle(
                            color: ShareCardTheme.couple,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${sub.totalCount}×',
                  style: const TextStyle(
                    color: ShareCardTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── Activity rows ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 3, 8, 6),
            child: Column(
              children: sub.activities
                  .map((a) => ShareActivityRow(activity: a, maxCount: maxAct))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single activity row ───────────────────────────────────────────────────────

class ShareActivityRow extends StatelessWidget {
  final HierarchyActivity activity;
  final int maxCount;

  const ShareActivityRow({
    super.key,
    required this.activity,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0
        ? (activity.count / maxCount).clamp(0.0, 1.0)
        : 0.0;
    final fillFlex = (fraction * 1000).round().clamp(1, 1000);
    final emptyFlex = (1000 - fillFlex).clamp(0, 999);
    final isRisky = activity.stiRisk || activity.healthRisk;
    final showPartners = activity.uniquePartners > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(activity.emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              activity.name,
              style: const TextStyle(
                color: ShareCardTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isRisky) ...[
            const SizedBox(width: 3),
            const Icon(
              Icons.warning_amber_rounded,
              size: 13,
              color: ShareCardTheme.riskModerate,
            ),
          ],
          if (showPartners) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: ShareCardTheme.couple.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: ShareCardTheme.couple.withOpacity(0.35),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 10,
                    color: ShareCardTheme.couple,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${activity.uniquePartners}',
                    style: const TextStyle(
                      color: ShareCardTheme.couple,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 5),
          SizedBox(
            width: 36,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(
                children: [
                  Expanded(
                    flex: fillFlex,
                    child: Container(
                      color: ShareCardTheme.accent.withOpacity(0.7),
                    ),
                  ),
                  if (emptyFlex > 0)
                    Expanded(
                      flex: emptyFlex,
                      child: Container(color: ShareCardTheme.surfaceHigh),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${activity.count}×',
            style: const TextStyle(
              color: ShareCardTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
