import 'dart:math' as math;

import '../entities/streak.dart';

class RestraintScorer {
  const RestraintScorer();
  static const int peakDay = 20;
  static const double plateauReward = 12;
  static const double peakReward = 30;

  /// Reward rises to day 20, then exponentially declines toward a non-zero
  /// plateau. Day 1 begins with a modest reward.
  int scoreForSuccessfulDay(Streak streak) {
    final day = math.max(1, streak.currentDays);

    if (day <= peakDay) {
      // Day 1 = 6, day 20 = 30.
      return (6 + (peakReward - 6) * (day - 1) / (peakDay - 1)).round();
    }

    // Starts at the peak after day 20, then approaches the plateau.
    final reward = plateauReward +
        (peakReward - plateauReward) *
            math.exp(-(day - peakDay) / 7.0);
    return reward.round();
  }
}
