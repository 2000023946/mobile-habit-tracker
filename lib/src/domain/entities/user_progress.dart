import 'category_progress.dart';
import 'habit.dart';

class UserProgress {
  final String userId;
  final Map<HabitCategory, CategoryProgress> categories;

  UserProgress({required this.userId})
      : categories = {
          for (final category in HabitCategory.values)
            category: CategoryProgress(category: category),
        };

  int get totalLifetimeExp =>
      categories.values.fold(0, (sum, progress) => sum + progress.lifetimeExp);

  /// Arithmetic mean of category levels; may be fractional.
  double get overallLevel {
    if (categories.isEmpty) return 1;
    final total = categories.values.fold<int>(
      0,
      (sum, progress) => sum + progress.level,
    );
    return total / categories.length;
  }

  CategoryProgress forCategory(HabitCategory category) {
    final progress = categories[category];
    if (progress == null) {
      throw ArgumentError('No progression configured for $category.');
    }
    return progress;
  }

  void award(Habit habit, int exp) {
    if (habit.userId != userId) {
      throw ArgumentError('Habit belongs to a different user.');
    }
    forCategory(habit.category).awardForHabit(habit, exp);
  }

  void penalize(Habit habit, int exp) {
    if (habit.userId != userId) {
      throw ArgumentError('Habit belongs to a different user.');
    }
    forCategory(habit.category).penalizeForHabit(habit, exp);
  }
}
