import 'package:intl/intl.dart';

/// Date utility functions used by the analysis calculators.

/// Returns a week key in ISO 8601 format (yyyy-Www)
String getWeekKey(DateTime date) {
  // ISO 8601 week date calculation
  final dayOfYear = _dayOfYear(date);
  final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday

  // Calculate week number
  final week = ((dayOfYear - dayOfWeek + 10) / 7).floor();

  // Handle edge cases for year boundaries
  if (week == 0) {
    // This date belongs to the last week of the previous year
    return getWeekKey(DateTime(date.year - 1, 12, 28));
  } else if (week == 53) {
    // Check if this week belongs to next year
    final dec31 = DateTime(date.year, 12, 31);
    if (dec31.weekday < 4) {
      return '${date.year + 1}-W01';
    }
  }

  return '${date.year}-W${week.toString().padLeft(2, '0')}';
}

int _dayOfYear(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  return date.difference(firstDayOfYear).inDays + 1;
}

/// Formats a [DateTime] as a date key string (yyyy-MM-dd).
String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// Formats a [DateTime] as a month key string (yyyy-MM).
String monthKey(DateTime date) => DateFormat('yyyy-MM').format(date);
