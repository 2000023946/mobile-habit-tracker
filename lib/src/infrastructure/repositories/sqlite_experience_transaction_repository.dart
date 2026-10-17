
import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/experience_transaction.dart';
import '../../domain/entities/habit.dart';
import '../../ports/repositories/experience_transaction_repository.dart';
import '../database/app_database.dart';

class SqliteExperienceTransactionRepository
    implements ExperienceTransactionRepository {
  final AppDatabase appDatabase;

  const SqliteExperienceTransactionRepository(this.appDatabase);

  Database get _db => appDatabase.database;

  @override
  Future<void> save(ExperienceTransaction transaction) async {
    final category = HabitCategory.values.byName(
      transaction.categoryProgressKey,
    );

    _db.execute(
      '''
      INSERT INTO experience_transactions (
        id,
        user_id,
        habit_id,
        category,
        category_progress_key,
        amount,
        type,
        description,
        created_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        user_id = excluded.user_id,
        habit_id = excluded.habit_id,
        category = excluded.category,
        category_progress_key = excluded.category_progress_key,
        amount = excluded.amount,
        type = excluded.type,
        description = excluded.description,
        created_at = excluded.created_at
      ''',
      [
        transaction.id,
        transaction.userId,
        transaction.habitId,
        category.name,
        transaction.categoryProgressKey,
        transaction.amount,
        transaction.type.name,
        transaction.description,
        transaction.createdAt.millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<List<ExperienceTransaction>> findByUserId({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    return _queryTransactions(
      where: 'user_id = ?',
      parameters: [userId],
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List<ExperienceTransaction>> findByHabitId({
    required String habitId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (limit < 0) {
      throw ArgumentError.value(limit, 'limit', 'Must not be negative.');
    }
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Must not be negative.');
    }

    final rows = _db.select(
      '''
      SELECT *
      FROM experience_transactions
      WHERE habit_id = ?
      ORDER BY created_at DESC, id DESC
      LIMIT ? OFFSET ?
      ''',
      [habitId, limit, offset],
    );

    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<ExperienceTransaction>> findByCategory({
    required String userId,
    required String categoryProgressKey,
    int? limit,
    int? offset,
  }) async {
    return _queryTransactions(
      where: 'user_id = ? AND category_progress_key = ?',
      parameters: [userId, categoryProgressKey],
      limit: limit,
      offset: offset,
    );
  }

  Future<List<ExperienceTransaction>> _queryTransactions({
    required String where,
    required List<Object?> parameters,
    int? limit,
    int? offset,
  }) async {
    if (limit != null && limit < 0) {
      throw ArgumentError.value(limit, 'limit', 'Must not be negative.');
    }
    if (offset != null && offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Must not be negative.');
    }

    var sql = '''
      SELECT *
      FROM experience_transactions
      WHERE $where
      ORDER BY created_at DESC, id DESC
    ''';

    final queryParameters = <Object?>[...parameters];

    if (limit != null) {
      sql += ' LIMIT ?';
      queryParameters.add(limit);
    } else if (offset != null) {
      // SQLite requires LIMIT when OFFSET is specified independently.
      sql += ' LIMIT -1';
    }

    if (offset != null) {
      sql += ' OFFSET ?';
      queryParameters.add(offset);
    }

    final rows = _db.select(sql, queryParameters);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<int> sumLifetimeExp(String userId) async {
    final rows = _db.select(
      '''
      SELECT COALESCE(
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END),
        0
      ) AS total
      FROM experience_transactions
      WHERE user_id = ?
      ''',
      [userId],
    );

    return rows.first['total'] as int;
  }

  @override
  Future<ExperienceTransaction?> hasTransactionForHabitDate({
    required String habitId,
    required DateTime date,
    required ExperienceTransactionType type,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final rows = _db.select(
      '''
      SELECT *
      FROM experience_transactions
      WHERE habit_id = ?
        AND type = ?
        AND created_at >= ?
        AND created_at < ?
      ORDER BY created_at DESC
      LIMIT 1
      ''',
      [
        habitId,
        type.name,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<void> deleteByHabitId(String habitId) async {
    // Intentionally do not delete historical EXP transactions when
    // a habit is deleted. The ledger should remain available for history.
    //
    // If your port contract explicitly requires deletion, replace this
    // body with the DELETE statement below:
    //
    // _db.execute(
    //   'DELETE FROM experience_transactions WHERE habit_id = ?',
    //   [habitId],
    // );
  }

  ExperienceTransaction _fromRow(Row row) {
    final category = HabitCategory.values.byName(
      row['category'] as String,
    );

    return ExperienceTransaction(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      habitId: row['habit_id'] as String,
      category: category,
      categoryProgressKey: row['category_progress_key'] as String,
      amount: row['amount'] as int,
      type: ExperienceTransactionType.values.byName(
        row['type'] as String,
      ),
      description: row['description'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
      ),
    );
  }
}
