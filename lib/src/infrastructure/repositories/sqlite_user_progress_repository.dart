import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/habit.dart';
import '../../domain/entities/user_progress.dart';
import '../../ports/repositories/user_progression_repository.dart';
import '../database/app_database.dart';

class SqliteUserProgressRepository implements UserProgressRepository {
  final AppDatabase appDatabase;

  const SqliteUserProgressRepository(this.appDatabase);

  Database get _db => appDatabase.database;

  @override
  Future<void> save(UserProgress progress) async {
    Future<void> persist() async {
      for (final category in HabitCategory.values) {
        final item = progress.forCategory(category);

        _db.execute(
          '''
          INSERT INTO category_progress (
            user_id, category, level, current_exp, lifetime_exp
          )
          VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(user_id, category) DO UPDATE SET
            level = excluded.level,
            current_exp = excluded.current_exp,
            lifetime_exp = excluded.lifetime_exp
          ''',
          [
            progress.userId,
            category.name,
            item.level,
            item.currentExp,
            item.lifetimeExp,
          ],
        );
      }
    }

    if (appDatabase.isInTransaction) {
      await persist();
    } else {
      await appDatabase.transaction(persist);
    }
  }

  @override
  Future<UserProgress?> findByUserId(String userId) async {
    final rows = _db.select(
      'SELECT * FROM category_progress WHERE user_id = ?',
      [userId],
    );

    if (rows.isEmpty) return null;

    final progress = UserProgress(userId: userId);

    for (final row in rows) {
      final category = HabitCategory.values.byName(
        row['category'] as String,
      );
      final item = progress.forCategory(category);

      item.level = row['level'] as int;
      item.currentExp = row['current_exp'] as int;
      item.lifetimeExp = row['lifetime_exp'] as int;
    }

    return progress;
  }

  @override
  Future<int?> findCategoryLevel({
    required String userId,
    required HabitCategory category,
  }) async {
    final rows = _db.select(
      '''
      SELECT level FROM category_progress
      WHERE user_id = ? AND category = ?
      ''',
      [userId, category.name],
    );

    if (rows.isEmpty) return null;
    return rows.first['level'] as int;
  }

  @override
  Future<int?> findCategoryCurrentExp({
    required String userId,
    required HabitCategory category,
  }) async {
    final rows = _db.select(
      '''
      SELECT current_exp FROM category_progress
      WHERE user_id = ? AND category = ?
      ''',
      [userId, category.name],
    );

    if (rows.isEmpty) return null;
    return rows.first['current_exp'] as int;
  }

  @override
  Future<int> findTotalLifetimeExp(String userId) async {
    final rows = _db.select(
      '''
      SELECT COALESCE(SUM(lifetime_exp), 0) AS total
      FROM category_progress
      WHERE user_id = ?
      ''',
      [userId],
    );

    return rows.first['total'] as int;
  }

  @override
  Future<void> deleteByUserId(String userId) async {
    _db.execute(
      'DELETE FROM category_progress WHERE user_id = ?',
      [userId],
    );
  }
}