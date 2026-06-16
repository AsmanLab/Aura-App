class DateUtils {
  /// UTC calendar day as an int `yyyymmdd`. Matches firestore.rules `today()`
  /// (derived from `request.time`, which is UTC) so the daily-quota counter
  /// agrees on both sides. NOTE: the quota window resets at UTC midnight.
  static int currentDayKeyUtc() {
    final n = DateTime.now().toUtc();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  static String getCurrentWeekId() {
    final now = DateTime.now();
    final mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final mondayString = mondayOfWeek.toIso8601String().split('T')[0];
    return 'week_$mondayString';
  }

  static DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static DateTime getEndOfWeek(DateTime date) {
    return getStartOfWeek(date).add(const Duration(days: 6, hours: 23, minutes: 59));
  }

  static bool isSameWeek(DateTime date1, DateTime date2) {
    final start1 = getStartOfWeek(date1);
    final start2 = getStartOfWeek(date2);
    return start1.year == start2.year &&
           start1.month == start2.month &&
           start1.day == start2.day;
  }
}