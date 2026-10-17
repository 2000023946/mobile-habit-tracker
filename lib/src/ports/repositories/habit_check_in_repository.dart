

import 'package:aegis_habit_rpg_mvp/src/domain/entities/habit_check_in.dart';

abstract interface class HabitCheckInRepository {
  Future<void> save(HabitCheckIn checkIn);

  Future<HabitCheckIn?> findById(String checkInId);

  Future<HabitCheckIn?> findByHabitAndDate({
    required String habitId,
    required DateTime date,
  });

  Future<List<HabitCheckIn>> findByHabitId({
    required String habitId,
    DateTime? from,
    DateTime? through,
    int limit = 50,
    int offset = 0,
  });

  Future<List<HabitCheckIn>> findByUserId({
    required String userId,
    DateTime? from,
    DateTime? through,
    int limit = 50,
    int offset = 0,
  });

  Future<void> deleteByHabitId(String habitId);
}
