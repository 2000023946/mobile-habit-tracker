import 'package:aegis_habit_rpg_mvp/src/domain/entities/habit.dart';

enum ExperienceTransactionType {
  executionReward,
  avoidanceReward,
  avoidanceViolationPenalty,
  missedCommitmentPenalty,
  adjustment,
}

class ExperienceTransaction {
  final String id;
  final String userId;
  final String habitId;
  final String categoryProgressKey;
  /// Positive for a reward; negative for a penalty.
  final int amount;
  final ExperienceTransactionType type;
  final String description;
  final DateTime createdAt;

  const ExperienceTransaction({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.categoryProgressKey,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt, required HabitCategory category,
  });
}
