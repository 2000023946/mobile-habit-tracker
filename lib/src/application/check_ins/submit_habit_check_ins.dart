import 'package:aegis_habit_rpg_mvp/src/ports/repositories/experience_transaction_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/habit_check_in_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/habit_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/steak_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_progression_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/id_generator.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/unit_of_work.dart';

import '../../domain/entities/experience_transaction.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_check_in.dart';
import '../../domain/entities/streak.dart';
import '../../domain/services/habit_progression_service.dart';
import '../common/validation.dart';

class SubmitHabitCheckIn {
  final UserRepository userRepository;
  final HabitRepository habitRepository;
  final HabitCheckInRepository checkInRepository;
  final UserProgressRepository progressRepository;
  final StreakRepository streakRepository;
  final ExperienceTransactionRepository transactionRepository;
  final HabitProgressionService progressionService;
  final IdGenerator idGenerator;
  final UnitOfWork unitOfWork;

  const SubmitHabitCheckIn({
    required this.userRepository,
    required this.habitRepository,
    required this.checkInRepository,
    required this.progressRepository,
    required this.streakRepository,
    required this.transactionRepository,
    required this.progressionService,
    required this.idGenerator,
    required this.unitOfWork,
  });

  Future<HabitProgressionResult> execute({
    required String userId,
    required String habitId,
    required double actualValue,
    DateTime? occurredAt,
  }) async {
    requireNonBlank(userId, 'User ID');
    requireNonBlank(habitId, 'Habit ID');

    if (!actualValue.isFinite || actualValue < 0) {
      throw const ValidationException(
        'Actual value must be a finite, non-negative number.',
      );
    }

    final timestamp = occurredAt ?? DateTime.now();

    return unitOfWork.runInTransaction(() async {
      final user = await userRepository.findById(userId);
      if (user == null) {
        throw NotFoundException('User "$userId" was not found.');
      }

      final habit = await habitRepository.findByIdForUser(
        userId: userId,
        habitId: habitId,
      );

      if (habit == null) {
        throw NotFoundException(
          'Habit "$habitId" was not found for this user.',
        );
      }

      // Prevent duplicate check-ins for the same habit and calendar date.
      final existingCheckIn =
          await checkInRepository.findByHabitAndDate(
        habitId: habitId,
        date: timestamp,
      );

      if (existingCheckIn != null) {
        throw const ConflictException(
          'A check-in already exists for this habit on this date.',
        );
      }

      // Execution habits record completed minutes. Avoidance habits record
      // the actual usage or quantity being tracked.
      if (habit is ExecutionHabit && actualValue <= 0) {
        throw const ValidationException(
          'Execution check-ins must record a value greater than zero.',
        );
      }

      final checkIn = HabitCheckIn(
        id: idGenerator.newId(),
        habitId: habit.id,
        userId: userId,
        actualValue: actualValue,
        occurredAt: timestamp,
      );

      final progress = await progressRepository.findByUserId(userId);
      if (progress == null) {
        throw NotFoundException(
          'Progress for user "$userId" was not found.',
        );
      }

      Streak? streak;

      if (habit is AvoidanceHabit) {
        streak = await streakRepository.findByHabitId(habit.id);

        if (streak == null) {
          streak = Streak(
            habitId: habit.id,
            userId: userId,
          );

          await streakRepository.save(streak);
        }
      }

      final result = progressionService.processCheckIn(
        habit: habit,
        checkIn: checkIn,
        userProgress: progress,
        streak: streak,
      );

      await checkInRepository.save(checkIn);
      await progressRepository.save(progress);

      if (streak != null) {
        await streakRepository.save(streak);
      }

      final ExperienceTransactionType transactionType;

      if (habit is ExecutionHabit) {
        transactionType = ExperienceTransactionType.executionReward;
      } else if (result.successful) {
        transactionType = ExperienceTransactionType.avoidanceReward;
      } else {
        transactionType =
            ExperienceTransactionType.avoidanceViolationPenalty;
      }

      final transaction = ExperienceTransaction(
        id: idGenerator.newId(),
        userId: userId,
        habitId: habitId,
        category: habit.category,
        categoryProgressKey: habit.category.name,
        amount: result.expDelta,
        type: transactionType,
        description: result.description,
        createdAt: DateTime.now(),
      );

      await transactionRepository.save(transaction);

      return result;
    });
  }
}