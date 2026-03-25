import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:indulge/data/models/v1/activity_count/activity_count.dart';
import 'package:indulge/view/analysis/share/share_card_models.dart';
import 'package:indulge/view/common/share/share_card_theme.dart';
import 'package:intl/intl.dart';

// ── Monthly bar chart ─────────────────────────────────────────────────────────

class ShareMonthlyBarChart extends StatelessWidget {
  final Map<String, int> monthlyCounts;
  final DateTime? startDate;
  final DateTime? endDate;

  const ShareMonthlyBarChart({
    super.key,
    required this.monthlyCounts,
    required this.startDate,
    required this.endDate,
  });

  /// Generates a complete, contiguous list of "yyyy-MM" month keys from
  /// [from] to [to] (inclusive), so the chart always shows every month even
  /// when a month has zero events.
  static List<String> _fullMonthRange(DateTime from, DateTime to) {
    final months = <String>[];
    var cursor = DateTime(from.year, from.month, 1);
    final end = DateTime(to.year, to.month, 1);
    while (!cursor.isAfter(end)) {
      months.add(DateFormat('yyyy-MM').format(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final resolvedStart = startDate ?? DateTime(now.year, now.month - 11, 1);
    final resolvedEnd = endDate ?? now;

    final allMonths = _fullMonthRange(resolvedStart, resolvedEnd);

    if (allMonths.isEmpty) {
      return const Center(
        child: Text(
          'No data',
          style: TextStyle(color: ShareCardTheme.textMuted, fontSize: 16),
        ),
      );
    }

    double maxVal = 0;
    for (final k in allMonths) {
      final v = (monthlyCounts[k] ?? 0).toDouble();
      if (v > maxVal) maxVal = v;
    }
    final maxY = maxVal == 0 ? 5.0 : ((maxVal / 5).ceil() * 5).toDouble();

    // barWidth shrinks as more months are shown so all bars remain visible.
    final barWidth = allMonths.length > 24
        ? 10.0
        : allMonths.length > 18
        ? 13.0
        : allMonths.length > 12
        ? 17.0
        : 22.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= allMonths.length) return const SizedBox();
                final d = DateTime.parse('${allMonths[i]}-01');
                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    '${DateFormat('MMM').format(d)}\n\'${DateFormat('yy').format(d)}',
                    style: const TextStyle(
                      color: ShareCardTheme.textSecondary,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: maxY / 5 == 0 ? 1 : maxY / 5,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxY) return const SizedBox();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: ShareCardTheme.textSecondary,
                    fontSize: 17,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: ShareCardTheme.divider, width: 1),
            left: BorderSide(color: ShareCardTheme.divider, width: 1),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5 == 0 ? 1 : maxY / 5,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: ShareCardTheme.divider, strokeWidth: 0.8),
        ),
        barGroups: List.generate(allMonths.length, (i) {
          final val = (monthlyCounts[allMonths[i]] ?? 0).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                color: val == 0
                    ? ShareCardTheme.accent.withOpacity(0.2)
                    : ShareCardTheme.accent,
                width: barWidth,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Activity heatmap ──────────────────────────────────────────────────────────

class ShareActivityHeatmap extends StatelessWidget {
  final Map<String, int> dailyCounts;
  final DateTime startDate;
  final DateTime endDate;

  static const double _box = 12.0;
  static const double _gap = 4.0;
  static const double _col = _box + _gap;

  const ShareActivityHeatmap({
    super.key,
    required this.dailyCounts,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final clampedStart =
        endDate.subtract(const Duration(days: 364)).isAfter(startDate)
        ? endDate.subtract(const Duration(days: 364))
        : startDate;

    final startOffset = clampedStart.weekday % 7;
    final gridStart = clampedStart.subtract(Duration(days: startOffset));

    final daySpan = endDate.difference(gridStart).inDays + 1;
    final totalWeeks = (daySpan / 7).ceil().clamp(1, 54);

    int maxCount = 0;
    for (final v in dailyCounts.values) {
      if (v > maxCount) maxCount = v;
    }

    final fmt = DateFormat('yyyy-MM-dd');
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: SizedBox(
                width: 36,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: _col),
                    _dayLabel('Mon'),
                    SizedBox(height: _gap),
                    SizedBox(height: _box),
                    SizedBox(height: _gap),
                    _dayLabel('Wed'),
                    SizedBox(height: _gap),
                    SizedBox(height: _box),
                    SizedBox(height: _gap),
                    _dayLabel('Fri'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 22,
                    child: Row(
                      children: List.generate(totalWeeks, (w) {
                        final weekSun = gridStart.add(Duration(days: w * 7));
                        final isFirst = w == 0;
                        final prevSun = isFirst
                            ? null
                            : gridStart.add(Duration(days: (w - 1) * 7));
                        final showLabel =
                            isFirst ||
                            (prevSun != null && weekSun.month != prevSun.month);
                        return SizedBox(
                          width: _col,
                          child: showLabel
                              ? Text(
                                  DateFormat('MMM').format(weekSun),
                                  style: const TextStyle(
                                    color: ShareCardTheme.textMuted,
                                    fontSize: 17,
                                  ),
                                  overflow: TextOverflow.visible,
                                  softWrap: false,
                                )
                              : null,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(totalWeeks, (w) {
                      return Column(
                        children: List.generate(7, (d) {
                          final date = gridStart.add(Duration(days: w * 7 + d));
                          final isFuture = date.isAfter(today);
                          final isOutOfRange =
                              date.isBefore(clampedStart) ||
                              date.isAfter(endDate);
                          final count = isOutOfRange || isFuture
                              ? 0
                              : (dailyCounts[fmt.format(date)] ?? 0);
                          return Container(
                            margin: EdgeInsets.only(bottom: _gap, right: _gap),
                            width: _box,
                            height: _box,
                            decoration: BoxDecoration(
                              color: isOutOfRange || isFuture
                                  ? Colors.transparent
                                  : _cellColor(count, maxCount),
                              borderRadius: BorderRadius.circular(2.5),
                              border: isOutOfRange || isFuture
                                  ? Border.all(
                                      color: ShareCardTheme.divider.withOpacity(
                                        0.25,
                                      ),
                                      width: 0.5,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text(
              'Less',
              style: TextStyle(color: ShareCardTheme.textMuted, fontSize: 16),
            ),
            const SizedBox(width: 6),
            ...[0, 1, 2, 3, 4].map(
              (level) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _legendColor(level),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'More',
              style: TextStyle(color: ShareCardTheme.textMuted, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _dayLabel(String text) => SizedBox(
    height: _box,
    child: Text(
      text,
      style: const TextStyle(color: ShareCardTheme.textMuted, fontSize: 13),
    ),
  );

  static Color _cellColor(int count, int maxCount) {
    if (count == 0 || maxCount == 0) return ShareCardTheme.surfaceHigh;
    final ratio = count / maxCount;
    if (maxCount < 3) return ShareCardTheme.accent;
    if (ratio < 0.25) return const Color(0xFF3D3472);
    if (ratio < 0.50) return const Color(0xFF5A4FA8);
    if (ratio < 0.75) return const Color(0xFF7C6FCD);
    return const Color(0xFFAD9FE8);
  }

  static Color _legendColor(int level) {
    switch (level) {
      case 0:
        return ShareCardTheme.surfaceHigh;
      case 1:
        return const Color(0xFF3D3472);
      case 2:
        return const Color(0xFF5A4FA8);
      case 3:
        return const Color(0xFF7C6FCD);
      case 4:
        return const Color(0xFFAD9FE8);
      default:
        return ShareCardTheme.surfaceHigh;
    }
  }
}

// ── Time-of-day horizontal bar chart ─────────────────────────────────────────

class ShareTimeOfDayChart extends StatelessWidget {
  final Map<ShareTimeOfDay, int> counts;

  const ShareTimeOfDayChart({super.key, required this.counts});

  static const _buckets = [
    ShareTimeOfDay.morning,
    ShareTimeOfDay.afternoon,
    ShareTimeOfDay.evening,
    ShareTimeOfDay.night,
  ];

  static const _labels = {
    ShareTimeOfDay.morning: 'Morning',
    ShareTimeOfDay.afternoon: 'Afternoon',
    ShareTimeOfDay.evening: 'Evening',
    ShareTimeOfDay.night: 'Night',
  };

  static const _sublabels = {
    ShareTimeOfDay.morning: '4 am – 12 pm',
    ShareTimeOfDay.afternoon: '12 pm – 5 pm',
    ShareTimeOfDay.evening: '5 pm – 11 pm',
    ShareTimeOfDay.night: '11 pm – 4 am',
  };

  static const _icons = {
    ShareTimeOfDay.morning: '🌅',
    ShareTimeOfDay.afternoon: '☀️',
    ShareTimeOfDay.evening: '🌆',
    ShareTimeOfDay.night: '🌙',
  };

  static const _colors = {
    ShareTimeOfDay.morning: Color(0xFFFFA726),
    ShareTimeOfDay.afternoon: Color(0xFFFFCC02),
    ShareTimeOfDay.evening: Color(0xFF7C6FCD),
    ShareTimeOfDay.night: Color(0xFF4FC3F7),
  };

  @override
  Widget build(BuildContext context) {
    final maxCount = _buckets
        .map((b) => counts[b] ?? 0)
        .fold(0, (a, b) => a > b ? a : b);
    final total = _buckets.fold(0, (s, b) => s + (counts[b] ?? 0));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final bucket in _buckets) ...[
          _buildRow(bucket, counts[bucket] ?? 0, maxCount, total),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildRow(ShareTimeOfDay bucket, int count, int maxCount, int total) {
    final fraction = maxCount > 0 ? count / maxCount : 0.0;
    final pct = total > 0 ? (count / total * 100).round() : 0;
    final color = _colors[bucket]!;

    return Row(
      children: [
        // Icon + label
        SizedBox(
          width: 160,
          child: Row(
            children: [
              Text(_icons[bucket]!, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labels[bucket]!,
                      style: const TextStyle(
                        color: ShareCardTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _sublabels[bucket]!,
                      style: const TextStyle(
                        color: ShareCardTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 20, color: ShareCardTheme.surfaceHigh),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Count + pct
        SizedBox(
          width: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: ShareCardTheme.textMuted,
                  fontSize: 17,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Day-of-week bar chart ─────────────────────────────────────────────────────

class ShareDayOfWeekChart extends StatelessWidget {
  /// averages maps weekday int (1=Mon..7=Sun) → average events per that weekday.
  final Map<int, double> averages;

  const ShareDayOfWeekChart({super.key, required this.averages});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final values = List.generate(7, (i) => averages[i + 1] ?? 0.0);
    final maxVal = values.fold(0.0, (a, b) => a > b ? a : b);
    // Guard against insufficient data - fl_chart requires valid non-zero maxY
    if (maxVal <= 0 || maxVal.isNaN || maxVal.isInfinite) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Insufficient data',
            style: TextStyle(
              color: ShareCardTheme.textMuted,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    final safeMaxVal = maxVal < 1.0 ? 1.0 : maxVal;
    final maxY = ((safeMaxVal * 10).ceil() / 10).clamp(1.0, double.infinity);
    final busiest = values.fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= 7) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _dayLabels[i],
                    style: TextStyle(
                      color: values[i] == busiest && busiest > 0
                          ? ShareCardTheme.accent
                          : ShareCardTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: values[i] == busiest && busiest > 0
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1.0,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxY) return const SizedBox();
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: ShareCardTheme.textSecondary,
                    fontSize: 15,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: ShareCardTheme.divider, width: 1),
            left: BorderSide(color: ShareCardTheme.divider, width: 1),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: ShareCardTheme.divider, strokeWidth: 0.8),
        ),
        barGroups: List.generate(7, (i) {
          final val = values[i];
          final isBusiest = val == busiest && busiest > 0;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                color: isBusiest
                    ? ShareCardTheme.accent
                    : ShareCardTheme.accent.withOpacity(0.45),
                width: 28,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Role breakdown chart ─────────────────────────────────────────────────────

class ShareRoleBreakdownChart extends StatelessWidget {
  final Map<ActivityRole, int> roleCounts;

  const ShareRoleBreakdownChart({super.key, required this.roleCounts});

  static const _colors = {
    ActivityRole.give: Color(0xFF42A5F5), // blue
    ActivityRole.receive: Color(0xFFAB47BC), // purple
    ActivityRole.both: Color(0xFF26A69A), // teal
    ActivityRole.participated: Color(0xFF78909C), // grey
  };

  static const _labels = {
    ActivityRole.give: 'Gave',
    ActivityRole.receive: 'Received',
    ActivityRole.both: 'Both',
    ActivityRole.participated: 'Participated',
  };

  @override
  Widget build(BuildContext context) {
    final total = roleCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final role in ActivityRole.values) ...[
          _buildRow(role, roleCounts[role] ?? 0, total),
          if (role != ActivityRole.participated) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildRow(ActivityRole role, int count, int total) {
    final fraction = total > 0 ? count / total : 0.0;
    final pct = (fraction * 100).round();
    final color = _colors[role]!;

    return Row(
      children: [
        // Label
        SizedBox(
          width: 120,
          child: Text(
            _labels[role]!,
            style: const TextStyle(
              color: ShareCardTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 18, color: ShareCardTheme.surfaceHigh),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Count + pct
        SizedBox(
          width: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: ShareCardTheme.textMuted,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
