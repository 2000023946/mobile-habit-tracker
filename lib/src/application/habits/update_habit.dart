
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/habit_repository.dart';

import '../../domain/entities/habit.dart';
import '../common/validation.dart';

class UpdateHabit {
  final HabitRepository habitRepository;

  const UpdateHabit({
    required this.habitRepository,
  });

  Future<Habit> execute({
    required String userId,
    required String habitId,
    required Habit updatedHabit,
  }) async {
    requireNonBlank(userId, 'User ID');
    requireNonBlank(habitId, 'Habit ID');
    requireNonBlank(updatedHabit.name, 'Habit name');

    if (updatedHabit.id != habitId ||
        updatedHabit.userId != userId) {
      throw const AuthorizationException(
        'The updated habit ID and owner must match the requested habit.',
      );
    }

    final existingHabit = await habitRepository.findByIdForUser(
      userId: userId,
      habitId: habitId,
    );

    if (existingHabit == null) {
      throw const NotFoundException('Habit not found.');
    }

    _validateHabit(updatedHabit);

    final habitToSave = _copyHabit(
      updatedHabit,
      name: updatedHabit.name.trim(),
    );

    await habitRepository.save(habitToSave);

    return habitToSave;
  }

  void _validateHabit(Habit habit) {
    if (habit is ExecutionHabit) {
      if (habit.scheduledDays.isEmpty) {
        throw const ValidationException(
          'An execution habit must have at least one scheduled day.',
        );
      }

      if (habit.weeklyTargetMinutes <= 0) {
        throw const ValidationException(
          'Weekly target minutes must be greater than zero.',
        );
      }

      return;
    }

    if (habit is AvoidanceHabit) {
      requirePositiveNumber(habit.target, 'Habit target');
      return;
    }

    throw const ValidationException('Unsupported habit type.');
  }

  Habit _copyHabit(
    Habit habit, {
    required String name,
  }) {
    if (habit is ExecutionHabit) {
      return ExecutionHabit(
        id: habit.id,
        userId: habit.userId,
        name: name,
        category: habit.category,
        scheduledDays: Set<Weekday>.unmodifiable(
          habit.scheduledDays,
        ),
        weeklyTargetMinutes: habit.weeklyTargetMinutes,
      );
    }

    if (habit is AvoidanceHabit) {
      return AvoidanceHabit(
        id: habit.id,
        userId: habit.userId,
        name: name,
        category: habit.category,
        target: habit.target,
        targetType: habit.targetType,
      );
    }

    throw const ValidationException('Unsupported habit type.');
  }
}
