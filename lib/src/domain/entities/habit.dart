enum HabitCategory {
  physicalActivity,
  studyAndLearning,
  mindAndFocus,
  mindfulnessAndWellbeing,
}

enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

abstract class Habit {
  final String id;
  final String userId;
  final String name;
  final HabitCategory category;

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
  });
}

/// A habit where the user performs an activity.
/// `weeklyTargetMinutes` is the planned total time across scheduled days.
/// The current scorer uses the reported minutes per check-in, capped at 120
/// minutes for reward calculation.
class ExecutionHabit extends Habit {
  final Set<Weekday> scheduledDays;
  final int weeklyTargetMinutes;

  const ExecutionHabit({
    required super.id,
    required super.userId,
    required super.name,
    required super.category,
    required this.scheduledDays,
    required this.weeklyTargetMinutes,
  });

  bool isScheduledOn(Weekday day) => scheduledDays.contains(day);
}

/// A habit where the user tries to stay at or below a daily limit.
/// `target` means the maximum allowed value per day.
/// `timeLimit` uses minutes; `quantityLimit` uses the relevant item count.
class AvoidanceHabit extends Habit {
  final double target;
  final AvoidanceTargetType targetType;

  const AvoidanceHabit({
    required super.id,
    required super.userId,
    required super.name,
    required super.category,
    required this.target,
    required this.targetType,
  });

  bool isWithinLimit(double actualValue) => actualValue <= target;
}

enum AvoidanceTargetType {
  timeLimit,
  quantityLimit,
}
