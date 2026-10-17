import 'dart:math' as math;

import '../entities/habit.dart';
import '../entities/habit_check_in.dart';

class ExecutionScorer {
  const ExecutionScorer();
  static const int maxRewardedMinutesPerOccurrence = 120;

  /// Initial formula:
  /// - logarithmic duration reward, so longer sessions have diminishing returns
  /// - hard cap at 120 rewarded minutes per occurrence
  /// - small frequency multiplier based on scheduled days per week
  ///
  /// Formula values are balancing defaults and can be tuned independently.
  int score(ExecutionHabit habit, HabitCheckIn checkIn) {
    if (checkIn.habitId != habit.id || checkIn.userId != habit.userId) {
      throw ArgumentError('Check-in does not belong to this habit/user.');
    }
    if (checkIn.actualValue < 0) {
      throw ArgumentError('Completed duration cannot be negative.');
    }
    if (habit.scheduledDays.isEmpty) {
      return 0;
    }

    final minutes = math.min(
      checkIn.actualValue,
      maxRewardedMinutesPerOccurrence.toDouble(),
    );
    if (minutes == 0) return 0;

    final durationReward = 20 * math.log(1 + minutes / 10);
    final frequencyMultiplier =
        1 + (habit.scheduledDays.length - 1) * 0.05;

    return (durationReward * frequencyMultiplier).round();
  }
}
