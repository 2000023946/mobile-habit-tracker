class PenaltyCalculator {
  const PenaltyCalculator();
  /// Heavy avoidance-streak violation penalty.
  /// It grows with the streak maturity and is deliberately uncapped.
  /// These values are initial game-balance defaults.
  int avoidanceViolationPenalty(int streakDays) {
    if (streakDays < 0) {
      throw ArgumentError.value(streakDays, 'streakDays');
    }
    return 25 + (streakDays * 4);
  }

  /// Penalty for missing a scheduled execution commitment.
  /// This is separate from an avoidance violation.
  int missedExecutionPenalty({required int weeklyTargetMinutes}) {
    if (weeklyTargetMinutes < 0) {
      throw ArgumentError.value(weeklyTargetMinutes, 'weeklyTargetMinutes');
    }
    return 10 + (weeklyTargetMinutes / 60).ceil();
  }
}
