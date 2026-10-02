import 'package:flutter/material.dart';
import 'package:indulge/view/analysis/models/overview_data.dart';
import 'package:indulge/view/analysis/share/share_card_models.dart';
import 'package:indulge/view/common/share/share_card_theme.dart';

// ── Category mix stacked bar ──────────────────────────────────────────────────

class ShareCategoryMixBar extends StatelessWidget {
  final List<CategoryMixEntry> entries;

  const ShareCategoryMixBar({super.key, required this.entries});

  static const _palette = [
    Color(0xFF7C6FCD),
    Color(0xFF4DB6AC),
    Color(0xFFAB47BC),
    Color(0xFF4FC3F7),
    Color(0xFFFFA726),
    Color(0xFFAED581),
    Color(0xFFEF5350),
    Color(0xFF26C6DA),
  ];

  @override
  Widget build(BuildContext context) {
    final total = entries.fold(0, (s, e) => s + e.count);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 18,
            child: Row(
              children: [
                for (int i = 0; i < entries.length; i++)
                  Expanded(
                    flex: entries[i].count,
                    child: Container(color: _palette[i % _palette.length]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Legend
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            for (int i = 0; i < entries.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _palette[i % _palette.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(entries[i].emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 3),
                  Text(
                    entries[i].name,
                    style: const TextStyle(
                      color: ShareCardTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(entries[i].count / total * 100).round().toInt()}%',
                    style: const TextStyle(
                      color: ShareCardTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ── Records block ─────────────────────────────────────────────────────────────

class ShareRecordsBlock extends StatelessWidget {
  final OverviewData overviewData;

  const ShareRecordsBlock({super.key, required this.overviewData});

  static String _fmtDate(DateTime d) =>
      '${d.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final items = <_RecordItem>[];

    if (overviewData.busiestDay != null &&
        overviewData.busiestDayEventCount > 0) {
      items.add(
        _RecordItem(
          icon: '🔥',
          label: 'Busiest Day',
          value: '${overviewData.busiestDayEventCount}',
          unit: overviewData.busiestDayEventCount == 1 ? 'event' : 'events',
          sub: _fmtDate(overviewData.busiestDay!),
        ),
      );
    }

    if (overviewData.busiestEvent != null &&
        overviewData.busiestEventActivityCount > 0) {
      items.add(
        _RecordItem(
          icon: '⚡',
          label: 'Most Activities',
          value: '${overviewData.busiestEventActivityCount}',
          unit: 'in one event',
          sub: _fmtDate(overviewData.busiestEvent!.date),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ShareCardTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ShareCardTheme.border, width: 1),
                ),
                child: Row(
                  children: [
                    Text(item.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: ShareCardTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              item.value,
                              style: const TextStyle(
                                color: ShareCardTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.unit,
                              style: const TextStyle(
                                color: ShareCardTheme.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item.sub,
                          style: const TextStyle(
                            color: ShareCardTheme.textMuted,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Internal record item data class ──────────────────────────────────────────

class _RecordItem {
  final String icon;
  final String label;
  final String value;
  final String unit;
  final String sub;

  const _RecordItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.sub,
  });
}
