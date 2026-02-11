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

  @override
  Widget build(BuildContext context) {
    // Determine the date range to display
    // We want to start on a Sunday to align the grid properly
    // weekday: 1 (Mon) -> 7 (Sun)
    // We want to shift back so that the start date is a Sunday
    // If startDate is Sunday (7), we shift 0? No, usually heatmaps start Sunday.
    // Let's assume row 0 is Sunday.
    // If startDate.weekday is 7 (Sunday), offset is 0.
    // If startDate.weekday is 1 (Monday), offset is 1 (to go back to Sunday).
    // offset = startDate.weekday % 7.
    final startOffset = startDate.weekday % 7;
    final displayDate = startDate.subtract(Duration(days: startOffset));

    // Calculate total weeks needed
    final daysDifference = endDate.difference(displayDate).inDays + 1;
    final totalWeeks = (daysDifference / 7).ceil();

    // Determine max count for color scaling
    int maxCount = 0;
    for (var count in dailyCounts.values) {
      if (count > maxCount) maxCount = count;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Base colors
    final emptyColor = isDark ? Colors.white10 : Colors.grey[200]!;
    const baseColor = Colors.purple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
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
                    _buildLegendBox(emptyColor),
                    _buildLegendBox(baseColor[200]!),
                    _buildLegendBox(baseColor[400]!),
                    _buildLegendBox(baseColor[600]!),
                    _buildLegendBox(baseColor[900]!),
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

        // Scrollable Heatmap
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse:
              true, // Show newest dates on the right? usually left-to-right is std, but "end" is right.
          // GitHub shows Jan -> Dec (Left -> Right).
          // We usually want to see the end date (today) visible.
          // "reverse: true" on a row with left-to-right logic puts the START on the right. That's confusing.
          // We want standard LTR, but maybe initial scroll position at the end.
          // Since we can't easily control initial scroll without a controller, let's just stick to standard LTR.
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day Labels Column (Mon, Wed, Fri)
              _buildDayLabels(theme),
              const SizedBox(width: 8),
              // Weeks
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Labels Row
                  _buildMonthLabels(displayDate, totalWeeks, theme),
                  const SizedBox(height: 4),
                  // Grid
                  Row(
                    children: List.generate(totalWeeks, (weekIndex) {
                      return _buildWeekColumn(
                        context,
                        displayDate,
                        weekIndex,
                        maxCount,
                        emptyColor,
                        baseColor,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendBox(Color color) {
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

  Widget _buildDayLabels(ThemeData theme) {
    const double boxHeight = 12.0;
    const double gap = 3.0;
    final style = theme.textTheme.bodySmall?.copyWith(
      fontSize: 9,
      color: theme.hintColor,
    );

    // Padding top to align with the grid (which has month labels above it now)
    // Actually the Month labels are in the main column, so we need to push Day labels down
    // by the height of month labels text + gap.
    return Padding(
      padding: const EdgeInsets.only(
        top: 18.0,
      ), // Approximate height of month text
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Sunday (Index 0) - Usually empty or 'S'
          const SizedBox(height: boxHeight + gap), // Skip Sun
          SizedBox(
            height: boxHeight,
            child: Text('Mon', style: style),
          ),
          const SizedBox(height: gap),
          const SizedBox(height: boxHeight), // Skip Tue
          const SizedBox(height: gap),
          SizedBox(
            height: boxHeight,
            child: Text('Wed', style: style),
          ),
          const SizedBox(height: gap),
          const SizedBox(height: boxHeight), // Skip Thu
          const SizedBox(height: gap),
          SizedBox(
            height: boxHeight,
            child: Text('Fri', style: style),
          ),
          // Skip Sat
        ],
      ),
    );
  }

  Widget _buildMonthLabels(
    DateTime startDate,
    int totalWeeks,
    ThemeData theme,
  ) {
    // We want to place month labels roughly over the week where the month starts.
    final List<Widget> monthWidgets = [];
    String lastMonth = '';

    for (int i = 0; i < totalWeeks; i++) {
      final weekStartDate = startDate.add(Duration(days: i * 7));
      // Look ahead to see if the month changes within this week or if it's the first week
      // A week has days 0..6.
      // If any day in this week is the 1st of a month, label it.
      // Or simply: if the month of the first day of this week is different from prev week.

      final monthName = DateFormat('MMM').format(weekStartDate);

      if (monthName != lastMonth) {
        monthWidgets.add(
          SizedBox(
            width: (12.0 + 3.0) * 4, // Span roughly 4 weeks of space
            child: Text(
              monthName,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              overflow: TextOverflow.visible,
              softWrap: false,
            ),
          ),
        );
        lastMonth = monthName;
      } else {
        // Filler to maintain spacing if we haven't switched months?
        // No, `Row` doesn't work like a grid for arbitrary placement easily unless we use width.
        // Better approach: Just iterate weeks and add either Text or SizedBox width.
      }
    }

    // This simplistic approach might bunch up labels.
    // A better approach for the Row of months:
    // Iterate weeks. If a week starts a month, put Text. Else put SizedBox(width: boxWidth).
    List<Widget> children = [];
    String currentMonth = '';

    for (int i = 0; i < totalWeeks; i++) {
      // Check the first day of the week, and maybe the last day of the week to see if month changed.
      // Usually we label the month above the column where the 1st appears.
      // Or just simply label every time the month index changes for the Sunday of that week.

      final weekStart = startDate.add(Duration(days: i * 7));

      // Logic: if this week contains the 1st, or if it's the very first week, show label.
      // But avoid showing label if it's too close to the end?
      // Let's use the Sunday month.
      final monthStr = DateFormat(
        'MMM',
      ).format(weekStart.add(const Duration(days: 0))); // Sunday

      if (monthStr != currentMonth) {
        currentMonth = monthStr;
        children.add(
          Container(
            width:
                (12.0 + 3.0) *
                2, // Give it some width to span at least 2 columns
            alignment: Alignment.bottomLeft,
            child: Text(
              monthStr,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              overflow: TextOverflow.visible,
              softWrap: false,
            ),
          ),
        );
        // We consumed 2 columns worth of width (conceptually) but we are in a Row of separate items.
        // Wait, the visual alignment must match the grid below.
        // The grid below is strictly `totalWeeks` columns of fixed width.
        // The Month row must effectively match that structure.
      } else {
        // If we didn't add a label, we still need to occupy the space of one week column?
        // No, the month labels row is independent.
        // BUT, for them to align, the easiest way is to build a Row of `totalWeeks` items,
        // where each item is the width of a column.
      }
    }

    // Correct approach for alignment:
    List<Widget> alignedChildren = [];
    String trackingMonth = '';

    for (int i = 0; i < totalWeeks; i++) {
      final weekStart = startDate.add(Duration(days: i * 7));

      // Let's look at the Sunday (start of week).
      final sundayMonth = DateFormat('MMM').format(weekStart);

      Widget content;
      if (sundayMonth != trackingMonth) {
        trackingMonth = sundayMonth;
        content = Text(
          sundayMonth,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          softWrap: false,
          overflow: TextOverflow.visible,
        );
      } else {
        content = const SizedBox.shrink();
      }

      alignedChildren.add(
        SizedBox(
          width: 12.0 + 3.0, // Box width + Gap
          child: content,
        ),
      );
    }

    return Row(children: alignedChildren);
  }

  Widget _buildWeekColumn(
    BuildContext context,
    DateTime gridStartDate,
    int weekIndex,
    int maxCount,
    Color emptyColor,
    MaterialColor baseColor,
  ) {
    final weekStartDate = gridStartDate.add(Duration(days: weekIndex * 7));

    return Column(
      children: List.generate(7, (dayIndex) {
        final date = weekStartDate.add(Duration(days: dayIndex));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final count = dailyCounts[dateKey] ?? 0;

        // Don't show future days or days before actual start?
        // The grid is rectangular, so we have to show something.
        // If date is > endDate or < actual startDate passed in props (if we care), we could hide it.
        // But usually we just show empty boxes.
        // Let's just color them normally (0).

        final bool isFuture = date.isAfter(DateTime.now());

        return GestureDetector(
          onTap: () {
            // Only navigate if there is data or it's a valid date
            // (Even 0 count is valid to search, shows empty results)
            onDaySelected(date);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 3.0, right: 3.0),
            width: 12.0,
            height: 12.0,
            decoration: BoxDecoration(
              color: isFuture
                  ? Colors.transparent
                  : _getColor(count, maxCount, emptyColor, baseColor),
              borderRadius: BorderRadius.circular(2),
              border: isFuture
                  ? Border.all(color: emptyColor.withOpacity(0.3))
                  : null,
            ),
            child: count > 0
                ? null // Maybe tooltip?
                : null,
          ),
        );
      }),
    );
  }

  Color _getColor(
    int count,
    int maxCount,
    Color emptyColor,
    MaterialColor baseColor,
  ) {
    if (count == 0) return emptyColor;
    if (maxCount == 0) return emptyColor;

    // Simple scale
    // If max is small (e.g. 1 or 2), we shouldn't subdivide too much.
    if (maxCount < 3) {
      return baseColor[500]!; // Just show fully active
    }

    final double ratio = count / maxCount;
    if (ratio < 0.25) return baseColor[200]!;
    if (ratio < 0.50) return baseColor[400]!;
    if (ratio < 0.75) return baseColor[600]!;
    return baseColor[900]!;
  }
}
