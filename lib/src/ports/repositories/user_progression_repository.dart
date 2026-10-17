

import 'package:aegis_habit_rpg_mvp/src/domain/entities/habit.dart';
import 'package:aegis_habit_rpg_mvp/src/domain/entities/user_progress.dart';

abstract interface class UserProgressRepository {
  Future<void> save(UserProgress progress);

  Future<UserProgress?> findByUserId(String userId);

  Future<int?> findCategoryLevel({
    required String userId,
    required HabitCategory category,
  });

  Future<int?> findCategoryCurrentExp({
    required String userId,
    required HabitCategory category,
  });

  Future<int> findTotalLifetimeExp(String userId);

  Future<void> deleteByUserId(String userId);
}
