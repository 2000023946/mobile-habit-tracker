

import 'package:aegis_habit_rpg_mvp/src/domain/entities/experience_transaction.dart';

abstract interface class ExperienceTransactionRepository {
  Future<void> save(ExperienceTransaction transaction);

  Future<List<ExperienceTransaction>> findByUserId({
    required String userId,
    int limit = 50,
    int offset = 0,
  });

  Future<List<ExperienceTransaction>> findByHabitId({
    required String habitId,
    int limit = 50,
    int offset = 0,
  });

  Future<List<ExperienceTransaction>> findByCategory({
    required String userId,
    required String categoryProgressKey,
    int limit = 50,
    int offset = 0,
  });

  Future<int> sumLifetimeExp(String userId);

  Future<void> deleteByHabitId(String habitId);

  Future<Object?> hasTransactionForHabitDate({required String habitId, required DateTime date, required ExperienceTransactionType type}) async {
    return null;
  }
}
