import 'package:aegis_habit_rpg_mvp/src/ports/repositories/habit_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_repository.dart';

import '../../domain/entities/habit.dart';
import '../../ports/id_generator.dart';
import '../common/validation.dart';

class CreateHabit {
  final HabitRepository habitRepository;
  final UserRepository userRepository;
  final IdGenerator idGenerator;

  const CreateHabit({
    required this.habitRepository,
    required this.userRepository,
    required this.idGenerator,
  });

  Future<Habit> execute({
    required String userId,
    required Habit habit,
  }) async {
    requireNonBlank(userId, 'User ID');
    requireNonBlank(habit.name, 'Habit name');

    if (habit.userId != userId) {
      throw const AuthorizationException(
        'Cannot create a habit for another user.',
      );
    }

    final user = await userRepository.findById(userId);

    if (user == null) {
      throw const NotFoundException('User not found.');
    }

    _validateHabit(habit);

    final newHabit = _copyWithId(
      habit,
      idGenerator.newId(),
    );

    await habitRepository.save(newHabit);

    return newHabit;
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

    throw const ValidationException(
      'Unsupported habit type.',
    );
  }

  Habit _copyWithId(Habit habit, String id) {
    if (habit is ExecutionHabit) {
      return ExecutionHabit(
        id: id,
        userId: habit.userId,
        name: habit.name.trim(),
        category: habit.category,
        scheduledDays: Set<Weekday>.unmodifiable(
          habit.scheduledDays,
        ),
        weeklyTargetMinutes: habit.weeklyTargetMinutes,
      );
    }

    if (habit is AvoidanceHabit) {
      return AvoidanceHabit(
        id: id,
        userId: habit.userId,
        name: habit.name.trim(),
        category: habit.category,
        target: habit.target,
        targetType: habit.targetType,
      );
    }

    throw const ValidationException(
      'Unsupported habit type.',
    );
  }
}