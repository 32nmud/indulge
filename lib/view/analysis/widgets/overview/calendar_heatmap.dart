import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarHeatmap extends StatelessWidget {
  final Map<String, int> dailyCounts;
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime) onDaySelected;

  const CalendarHeatmap({
    super.key,
    required this.dailyCounts,
    required this.startDate,
    required this.endDate,
    required this.onDaySelected,
  });

  // Box size and gap must be consistent across grid, day labels, and month labels.
  static const double _boxSize = 12.0;
  static const double _gap = 3.0;
  static const double _colWidth = _boxSize + _gap;

  @override
  Widget build(BuildContext context) {
    // Align the grid start to Sunday.
    final startOffset = startDate.weekday % 7; // Sun=0, Mon=1 … Sat=6
    final gridStart = startDate.subtract(Duration(days: startOffset));

    final daysDifference = endDate.difference(gridStart).inDays + 1;
    final totalWeeks = (daysDifference / 7).ceil();

    int maxCount = 0;
    for (final count in dailyCounts.values) {
      if (count > maxCount) maxCount = count;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final emptyColor = isDark ? Colors.white10 : Colors.grey[200]!;
    const baseColor = Colors.purple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title row ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activity Log', style: theme.textTheme.titleMedium),
              if (maxCount > 0)
                Row(
                  children: [
                    Text(
                      'Less',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    _legendBox(emptyColor),
                    _legendBox(baseColor[200]!),
                    _legendBox(baseColor[400]!),
                    _legendBox(baseColor[600]!),
                    _legendBox(baseColor[900]!),
                    const SizedBox(width: 4),
                    Text(
                      'More',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // ── Scrollable heatmap ─────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDayLabels(theme),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthLabels(gridStart, totalWeeks, theme),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      totalWeeks,
                      (w) => _buildWeekColumn(
                        context,
                        gridStart,
                        w,
                        maxCount,
                        emptyColor,
                        baseColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Month label row ────────────────────────────────────────────────────────
  //
  // One SizedBox per week column, each exactly _colWidth wide. A month name is
  // placed in the column where the Sunday of that week first falls in a new
  // month; all other columns get an empty SizedBox.

  Widget _buildMonthLabels(
    DateTime gridStart,
    int totalWeeks,
    ThemeData theme,
  ) {
    String lastMonth = '';
    final children = <Widget>[];

    for (int w = 0; w < totalWeeks; w++) {
      final weekSunday = gridStart.add(Duration(days: w * 7));
      final monthStr = DateFormat('MMM').format(weekSunday);

      if (monthStr != lastMonth) {
        lastMonth = monthStr;
        children.add(
          SizedBox(
            width: _colWidth,
            child: Text(
              monthStr,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        );
      } else {
        children.add(const SizedBox(width: _colWidth));
      }
    }

    return Row(children: children);
  }

  // ── Day-of-week labels ─────────────────────────────────────────────────────

  Widget _buildDayLabels(ThemeData theme) {
    final style = theme.textTheme.bodySmall?.copyWith(
      fontSize: 9,
      color: theme.hintColor,
    );

    // Push down by the height of the month label row (text + 4 px gap).
    return Padding(
      padding: const EdgeInsets.only(top: 18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: _boxSize + _gap), // Sun — unlabelled
          SizedBox(
            height: _boxSize,
            child: Text('Mon', style: style),
          ),
          const SizedBox(height: _gap),
          SizedBox(height: _boxSize), // Tue — unlabelled
          const SizedBox(height: _gap),
          SizedBox(
            height: _boxSize,
            child: Text('Wed', style: style),
          ),
          const SizedBox(height: _gap),
          SizedBox(height: _boxSize), // Thu — unlabelled
          const SizedBox(height: _gap),
          SizedBox(
            height: _boxSize,
            child: Text('Fri', style: style),
          ),
          // Sat — unlabelled, no extra gap needed
        ],
      ),
    );
  }

  // ── Week column ────────────────────────────────────────────────────────────

  Widget _buildWeekColumn(
    BuildContext context,
    DateTime gridStart,
    int weekIndex,
    int maxCount,
    Color emptyColor,
    MaterialColor baseColor,
  ) {
    final weekStart = gridStart.add(Duration(days: weekIndex * 7));

    return Column(
      children: List.generate(7, (dayIndex) {
        final date = weekStart.add(Duration(days: dayIndex));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final count = dailyCounts[dateKey] ?? 0;
        final isFuture = date.isAfter(DateTime.now());

        return GestureDetector(
          onTap: () => onDaySelected(date),
          child: Container(
            margin: const EdgeInsets.only(bottom: _gap, right: _gap),
            width: _boxSize,
            height: _boxSize,
            decoration: BoxDecoration(
              color: isFuture
                  ? Colors.transparent
                  : _cellColor(count, maxCount, emptyColor, baseColor),
              borderRadius: BorderRadius.circular(2),
              border: isFuture
                  ? Border.all(color: emptyColor.withOpacity(0.3))
                  : null,
            ),
          ),
        );
      }),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _cellColor(
    int count,
    int maxCount,
    Color emptyColor,
    MaterialColor baseColor,
  ) {
    if (count == 0 || maxCount == 0) return emptyColor;
    if (maxCount < 3) return baseColor[500]!;
    final ratio = count / maxCount;
    if (ratio < 0.25) return baseColor[200]!;
    if (ratio < 0.50) return baseColor[400]!;
    if (ratio < 0.75) return baseColor[600]!;
    return baseColor[900]!;
  }

  static Widget _legendBox(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
