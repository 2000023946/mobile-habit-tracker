import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/streak.dart';
import '../../ports/repositories/steak_repository.dart';
import '../database/app_database.dart';

class SqliteStreakRepository implements StreakRepository {
  final AppDatabase appDatabase;

  const SqliteStreakRepository(this.appDatabase);

  Database get _db => appDatabase.database;

  @override
  Future<void> save(Streak streak) async {
    final habitRows = _db.select(
      'SELECT user_id FROM habits WHERE id = ?',
      [streak.habitId],
    );

    if (habitRows.isEmpty) {
      throw StateError(
        'Cannot save a streak for missing habit "${streak.habitId}".',
      );
    }

    final userId = habitRows.first['user_id'] as String;

    _db.execute(
      '''
      INSERT INTO streaks (
        habit_id, user_id, current_days, longest_days,
        last_successful_date
      )
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(habit_id) DO UPDATE SET
        user_id = excluded.user_id,
        current_days = excluded.current_days,
        longest_days = excluded.longest_days,
        last_successful_date = excluded.last_successful_date
      ''',
      [
        streak.habitId,
        userId,
        streak.currentDays,
        streak.longestDays,
        streak.lastSuccessfulDate == null
            ? null
            : _dateKey(streak.lastSuccessfulDate!),
      ],
    );
  }

  @override
  Future<Streak?> findByHabitId(String habitId) async {
    final rows = _db.select(
      'SELECT * FROM streaks WHERE habit_id = ?',
      [habitId],
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    final lastDate = row['last_successful_date'] as String?;

    return Streak(
      habitId: row['habit_id'] as String,
      userId: row['user_id'] as String,
      currentDays: row['current_days'] as int,
      longestDays: row['longest_days'] as int,
      lastSuccessfulDate:
          lastDate == null ? null : DateTime.parse(lastDate),
    );
  }

  @override
  Future<void> deleteByHabitId(String habitId) async {
    _db.execute(
      'DELETE FROM streaks WHERE habit_id = ?',
      [habitId],
    );
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Future<List<Streak>> findByHabitIds(List<String> habitIds) {
    // TODO: implement findByHabitIds
    throw UnimplementedError();
  }
}