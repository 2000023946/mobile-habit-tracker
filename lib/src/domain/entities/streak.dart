class Streak {
  final String habitId;
  int currentDays;
  int longestDays;
  DateTime? lastSuccessfulDate;

  Streak({
    required this.habitId,
    this.currentDays = 0,
    this.longestDays = 0,
    this.lastSuccessfulDate, required String userId,
  });

  /// Records a successful day once. Duplicate same-day calls do not grow streak.
  /// Dates should already be normalized to local calendar dates by the caller.
  void recordSuccess(DateTime date) {
    final day = _dateOnly(date);
    final previous = lastSuccessfulDate == null
        ? null
        : _dateOnly(lastSuccessfulDate!);

    if (previous != null && _sameDay(previous, day)) {
      return;
    }

    if (previous != null && day.isBefore(previous)) {
      throw ArgumentError('Cannot record a streak date before the last success.');
    }

    if (previous != null && day.difference(previous).inDays == 1) {
      currentDays++;
    } else {
      // A gap breaks continuity. A missed day should also be recorded as a
      // violation/miss by the application service if a penalty is required.
      currentDays = 1;
    }

    lastSuccessfulDate = day;
    if (currentDays > longestDays) {
      longestDays = currentDays;
    }
  }

  /// Resets the active streak but preserves the longest-ever record.
  void breakStreak() {
    currentDays = 0;
    lastSuccessfulDate = null;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
