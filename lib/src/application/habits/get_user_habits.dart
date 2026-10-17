import 'package:aegis_habit_rpg_mvp/src/ports/repositories/habit_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_repository.dart';

import '../../domain/entities/habit.dart';

import '../common/validation.dart';

class GetUserHabits {
  final HabitRepository habitRepository;
  final UserRepository userRepository;

  const GetUserHabits({
    required this.habitRepository,
    required this.userRepository,
  });

  Future<List<Habit>> execute({
    required String userId,
    HabitCategory? category,
  }) async {
    requireNonBlank(userId, 'User ID');

    final user = await userRepository.findById(userId);

    if (user == null) {
      throw const NotFoundException('User not found.');
    }

    final habits = await habitRepository.findByUserId(
      userId: userId,
      category: category,
    );

    return List<Habit>.unmodifiable(habits);
  }
}