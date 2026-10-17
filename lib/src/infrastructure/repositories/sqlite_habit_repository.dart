import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/habit.dart';
import '../../ports/repositories/habit_repository.dart';
import '../database/app_database.dart';

class SqliteHabitRepository implements HabitRepository {
  final AppDatabase appDatabase;

  const SqliteHabitRepository(this.appDatabase);

  Database get _db => appDatabase.database;

  @override
  Future<void> save(Habit habit) async {
    final isExecution = habit is ExecutionHabit;

    if (!isExecution && habit is! AvoidanceHabit) {
      throw ArgumentError('Unsupported habit type: ${habit.runtimeType}');
    }

    final scheduledDays = isExecution
        ? (habit).scheduledDays
            .map((day) => day.name)
            .join(',')
        : null;

    final weeklyTargetMinutes = isExecution
        ? (habit).weeklyTargetMinutes
        : null;

    final target =
        habit is AvoidanceHabit ? habit.target : null;

    final targetType =
        habit is AvoidanceHabit ? habit.targetType.name : null;

    final now = DateTime.now().millisecondsSinceEpoch;

    _db.execute(
      '''
      INSERT INTO habits (
        id, user_id, name, category, habit_type,
        scheduled_days, weekly_target_minutes,
        target, target_type, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        user_id = excluded.user_id,
        name = excluded.name,
        category = excluded.category,
        habit_type = excluded.habit_type,
        scheduled_days = excluded.scheduled_days,
        weekly_target_minutes = excluded.weekly_target_minutes,
        target = excluded.target,
        target_type = excluded.target_type,
        updated_at = excluded.updated_at
      ''',
      [
        habit.id,
        habit.userId,
        habit.name,
        habit.category.name,
        isExecution ? 'execution' : 'avoidance',
        scheduledDays,
        weeklyTargetMinutes,
        target,
        targetType,
        now,
        now,
      ],
    );
  }

  @override
  Future<Habit?> findById(String habitId) async {
    final rows = _db.select(
      'SELECT * FROM habits WHERE id = ?',
      [habitId],
    );

    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<Habit?> findByIdForUser({
    required String userId,
    required String habitId,
  }) async {
    final rows = _db.select(
      'SELECT * FROM habits WHERE id = ? AND user_id = ?',
      [habitId, userId],
    );

    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<Habit>> findByUserId({
    required String userId,
    HabitCategory? category,
  }) async {
    final rows = category == null
        ? _db.select(
            'SELECT * FROM habits WHERE user_id = ? ORDER BY name',
            [userId],
          )
        : _db.select(
            '''
            SELECT * FROM habits
            WHERE user_id = ? AND category = ?
            ORDER BY name
            ''',
            [userId, category.name],
          );

    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Habit>> findByUserAndCategory({
    required String userId,
    required HabitCategory category,
  }) async {
    final rows = _db.select(
      '''
      SELECT * FROM habits
      WHERE user_id = ? AND category = ?
      ORDER BY name
      ''',
      [userId, category.name],
    );

    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> delete({
    required String userId,
    required String habitId,
  }) async {
    _db.execute(
      'DELETE FROM habits WHERE id = ? AND user_id = ?',
      [habitId, userId],
    );
  }

  @override
  Future<bool> exists({
    required String userId,
    required String habitId,
  }) async {
    final rows = _db.select(
      'SELECT 1 FROM habits WHERE id = ? AND user_id = ? LIMIT 1',
      [habitId, userId],
    );
    return rows.isNotEmpty;
  }

  Habit _fromRow(Row row) {
    final id = row['id'] as String;
    final userId = row['user_id'] as String;
    final name = row['name'] as String;
    final category = HabitCategory.values.byName(
      row['category'] as String,
    );

    if (row['habit_type'] == 'execution') {
      final encodedDays = row['scheduled_days'] as String;
      final days = encodedDays.isEmpty
          ? <Weekday>{}
          : encodedDays
              .split(',')
              .map((name) => Weekday.values.byName(name))
              .toSet();

      return ExecutionHabit(
        id: id,
        userId: userId,
        name: name,
        category: category,
        scheduledDays: days,
        weeklyTargetMinutes: row['weekly_target_minutes'] as int,
      );
    }

    return AvoidanceHabit(
      id: id,
      userId: userId,
      name: name,
      category: category,
      target: (row['target'] as num).toDouble(),
      targetType: AvoidanceTargetType.values.byName(
        row['target_type'] as String,
      ),
    );
  }
}