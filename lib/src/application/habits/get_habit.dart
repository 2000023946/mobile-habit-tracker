import 'package:aegis_habit_rpg_mvp/src/ports/repositories/habit_repository.dart';

import '../../domain/entities/habit.dart';
import '../common/validation.dart';

class GetHabit {
  final HabitRepository habitRepository;

  const GetHabit({
    required this.habitRepository,
  });

  Future<Habit> execute({
    required String userId,
    required String habitId,
  }) async {
    requireNonBlank(userId, 'User ID');
    requireNonBlank(habitId, 'Habit ID');

    final habit = await habitRepository.findByIdForUser(
      userId: userId,
      habitId: habitId,
    );

    if (habit == null) {
      throw const NotFoundException('Habit not found.');
    }

    return habit;
  }
}