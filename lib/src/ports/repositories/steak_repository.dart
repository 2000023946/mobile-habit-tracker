
import 'package:aegis_habit_rpg_mvp/src/domain/entities/streak.dart';


abstract interface class StreakRepository {
  Future<void> save(Streak streak);

  Future<Streak?> findByHabitId(String habitId);

  Future<List<Streak>> findByHabitIds(List<String> habitIds);

  Future<void> deleteByHabitId(String habitId);
}
