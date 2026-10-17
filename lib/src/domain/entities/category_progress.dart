import 'habit.dart';

class CategoryProgress {
  final HabitCategory category;
  int level;
  int currentExp;
  int lifetimeExp;

  CategoryProgress({
    required this.category,
    this.level = 1,
    this.currentExp = 0,
    this.lifetimeExp = 0,
  }) {
    if (level < 1 || currentExp < 0 || lifetimeExp < 0) {
      throw ArgumentError('Progress values cannot be negative and level starts at 1.');
    }
  }

  /// EXP required to advance from this level to the next level.
  /// Initial rule: 100 * level^2.
  int get expRequiredForNextLevel => 100 * level * level;

  /// Adds a reward and automatically handles one or more level-ups.
  void addExp(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Reward must be non-negative.');
    }
    lifetimeExp += amount;
    currentExp += amount;

    while (currentExp >= expRequiredForNextLevel) {
      currentExp -= expRequiredForNextLevel;
      level++;
    }
  }

  
  /// Applies a penalty to current progression.
  /// Lifetime EXP is never reduced by penalties.
  /// Level cannot fall below 1, and level-one EXP floors at zero.
  void removeExp(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Penalty must be non-negative.',
      );
    }

    var remaining = amount;

    while (remaining > 0) {
      if (level == 1 && currentExp == 0) {
        return;
      }

      if (remaining <= currentExp) {
        currentExp -= remaining;
        return;
      }

      remaining -= currentExp;
      currentExp = 0;

      if (level == 1) {
        return;
      }

      level--;

      // Restore the previous level's progress bar to its final EXP
      // point, then continue subtracting the remaining penalty.
      currentExp = expRequiredForNextLevel - 1;
    }
  }


  /// Validates that a habit is awarded to its own category, then applies reward.
  void awardForHabit(Habit habit, int exp) {
    if (habit.category != category) {
      throw ArgumentError('Habit category does not match this progress category.');
    }
    addExp(exp);
  }

  /// Validates category before applying a penalty associated with a habit.
  void penalizeForHabit(Habit habit, int exp) {
    if (habit.category != category) {
      throw ArgumentError('Habit category does not match this progress category.');
    }
    removeExp(exp);
  }
}
