import '../entities/habit.dart';
import '../entities/habit_check_in.dart';
import '../entities/streak.dart';
import '../entities/user_progress.dart';
import 'execution_scorer.dart';
import 'penalty_calculator.dart';
import 'restraint_scorer.dart';

class HabitProgressionResult {
  final int expDelta;
  final bool successful;
  final bool levelChanged;
  final int levelBefore;
  final int levelAfter;
  final int streakDays;
  final String description;

  const HabitProgressionResult({
    required this.expDelta,
    required this.successful,
    required this.levelChanged,
    required this.levelBefore,
    required this.levelAfter,
    required this.streakDays,
    required this.description,
  });

  int get expChange => expDelta;
}

/// Applies deterministic domain rules.
/// Persistence and duplicate protection belong in the application layer.
class HabitProgressionService {
  final ExecutionScorer executionScorer;
  final RestraintScorer restraintScorer;
  final PenaltyCalculator penaltyCalculator;

  const HabitProgressionService({
    this.executionScorer = const ExecutionScorer(),
    this.restraintScorer = const RestraintScorer(),
    this.penaltyCalculator = const PenaltyCalculator(),
  });

  HabitProgressionResult processCheckIn({
    required Habit habit,
    required HabitCheckIn checkIn,
    required UserProgress userProgress,
    Streak? streak,
  }) {
    if (checkIn.habitId != habit.id ||
        checkIn.userId != habit.userId) {
      throw ArgumentError('Check-in does not match the habit.');
    }

    if (userProgress.userId != habit.userId) {
      throw ArgumentError(
        'Progress belongs to a different user.',
      );
    }

    final category = userProgress.forCategory(habit.category);
    final before = category.level;

    if (habit is ExecutionHabit) {
      final exp = executionScorer.score(habit, checkIn);

      userProgress.award(habit, exp);

      return HabitProgressionResult(
        expDelta: exp,
        successful: exp > 0,
        levelChanged: category.level != before,
        levelBefore: before,
        levelAfter: category.level,
        streakDays: 0,
        description: exp > 0
            ? 'Execution habit completed.'
            : 'No EXP awarded for this execution.',
      );
    }

    if (habit is AvoidanceHabit) {
      if (streak == null || streak.habitId != habit.id) {
        throw ArgumentError(
          'A matching Streak is required for avoidance habits.',
        );
      }

      if (habit.isWithinLimit(checkIn.actualValue)) {
        streak.recordSuccess(checkIn.occurredAt);

        final exp = restraintScorer.scoreForSuccessfulDay(streak);
        userProgress.award(habit, exp);

        return HabitProgressionResult(
          expDelta: exp,
          successful: true,
          levelChanged: category.level != before,
          levelBefore: before,
          levelAfter: category.level,
          streakDays: streak.currentDays,
          description: 'Avoidance target maintained.',
        );
      }

      final penalty =
          penaltyCalculator.avoidanceViolationPenalty(
        streak.currentDays,
      );

      userProgress.penalize(habit, penalty);
      streak.breakStreak();

      return HabitProgressionResult(
        expDelta: -penalty,
        successful: false,
        levelChanged: category.level != before,
        levelBefore: before,
        levelAfter: category.level,
        streakDays: 0,
        description: 'Avoidance target exceeded.',
      );
    }

    throw UnsupportedError(
      'Unsupported habit type: ${habit.runtimeType}',
    );
  }

  /// Applies the penalty for a missed scheduled execution.
  ///
  /// Call only after the occurrence deadline has passed and no valid
  /// check-in exists. The application layer must prevent duplicate calls.
  HabitProgressionResult processMissedExecution({
    required ExecutionHabit habit,
    required UserProgress userProgress,
    required String checkInOrEventId,
    required DateTime missedDate,
  }) {
    if (userProgress.userId != habit.userId) {
      throw ArgumentError(
        'Progress belongs to a different user.',
      );
    }

    if (checkInOrEventId.trim().isEmpty) {
      throw ArgumentError(
        'A check-in or event ID is required.',
      );
    }

    final category = userProgress.forCategory(habit.category);
    final before = category.level;

    final penalty =
        penaltyCalculator.missedExecutionPenalty(
      weeklyTargetMinutes: habit.weeklyTargetMinutes,
    );

    userProgress.penalize(habit, penalty);

    return HabitProgressionResult(
      expDelta: -penalty,
      successful: false,
      levelChanged: category.level != before,
      levelBefore: before,
      levelAfter: category.level,
      streakDays: 0,
      description:
          'Scheduled execution missed on '
          '${missedDate.year}-'
          '${missedDate.month.toString().padLeft(2, '0')}-'
          '${missedDate.day.toString().padLeft(2, '0')}.',
    );
  }
}