

import 'package:aegis_habit_rpg_mvp/src/domain/entities/habit.dart';

abstract interface class HabitRepository {
  Future<void> save(Habit habit);

  Future<Habit?> findById(String habitId);

  Future<Habit?> findByIdForUser({
    required String userId,
    required String habitId,
  });

  Future<List<Habit>> findByUserId({
    required String userId,
    HabitCategory? category,
  });

  Future<List<Habit>> findByUserAndCategory({
    required String userId,
    required HabitCategory category,
  });

  Future<void> delete({
    required String userId,
    required String habitId,
  });

  Future<bool> exists({
    required String userId,
    required String habitId,
  });
}
