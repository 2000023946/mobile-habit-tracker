import 'package:aegis_habit_rpg_mvp/src/ports/repositories/habit_check_in_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/habit_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/steak_repository.dart';

import '../../ports/unit_of_work.dart';
import '../common/validation.dart';

class DeleteHabit {
  final HabitRepository habitRepository;
  final HabitCheckInRepository habitCheckInRepository;
  final StreakRepository streakRepository;
  final UnitOfWork unitOfWork;

  const DeleteHabit({
    required this.habitRepository,
    required this.habitCheckInRepository,
    required this.streakRepository,
    required this.unitOfWork,
  });

  Future<void> execute({
    required String userId,
    required String habitId,
  }) async {
    requireNonBlank(userId, 'User ID');
    requireNonBlank(habitId, 'Habit ID');

    return unitOfWork.runInTransaction(() async {
      final habit = await habitRepository.findByIdForUser(
        userId: userId,
        habitId: habitId,
      );

      if (habit == null) {
        throw const NotFoundException('Habit not found.');
      }

      await habitCheckInRepository.deleteByHabitId(habitId);
      await streakRepository.deleteByHabitId(habitId);

      await habitRepository.delete(
        userId: userId,
        habitId: habitId,
      );
    });
  }
}