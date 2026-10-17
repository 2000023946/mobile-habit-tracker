import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/habit_check_in.dart';
import '../../ports/repositories/habit_check_in_repository.dart';
import '../database/app_database.dart';

class SqliteHabitCheckInRepository
    implements HabitCheckInRepository {
  final AppDatabase appDatabase;

  const SqliteHabitCheckInRepository(this.appDatabase);

  Database get _db => appDatabase.database;

  String _dateKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Future<void> save(HabitCheckIn checkIn) async {
    _db.execute(
      '''
      INSERT INTO habit_check_ins (
        id, habit_id, user_id, actual_value, occurred_at, occurred_date
      )
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        actual_value = excluded.actual_value,
        occurred_at = excluded.occurred_at,
        occurred_date = excluded.occurred_date
      ''',
      [
        checkIn.id,
        checkIn.habitId,
        checkIn.userId,
        checkIn.actualValue,
        checkIn.occurredAt.millisecondsSinceEpoch,
        _dateKey(checkIn.occurredAt),
      ],
    );
  }

  @override
  Future<HabitCheckIn?> findById(String checkInId) async {
    final rows = _db.select(
      'SELECT * FROM habit_check_ins WHERE id = ?',
      [checkInId],
    );

    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<HabitCheckIn?> findByHabitAndDate({
    required String habitId,
    required DateTime date,
  }) async {
    final rows = _db.select(
      '''
      SELECT * FROM habit_check_ins
      WHERE habit_id = ? AND occurred_date = ?
      LIMIT 1
      ''',
      [habitId, _dateKey(date)],
    );

    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<HabitCheckIn>> findByHabitId({
    required String habitId,
    DateTime? from,
    DateTime? through,
    int? limit,
    int? offset,
  }) async {
    final conditions = <String>['habit_id = ?'];
    final parameters = <Object?>[habitId];

    if (from != null) {
      conditions.add('occurred_at >= ?');
      parameters.add(from.millisecondsSinceEpoch);
    }

    if (through != null) {
      conditions.add('occurred_at <= ?');
      parameters.add(through.millisecondsSinceEpoch);
    }

    var sql =
        'SELECT * FROM habit_check_ins WHERE ${conditions.join(' AND ')} '
        'ORDER BY occurred_at DESC';

    if (limit != null) {
      sql += ' LIMIT ?';
      parameters.add(limit);
    } else if (offset != null && offset > 0) {
      sql += ' LIMIT -1';
    }

    if (offset != null) {
      sql += ' OFFSET ?';
      parameters.add(offset);
    }

    return _db.select(sql, parameters).map(_fromRow).toList();
  }

  @override
  Future<List<HabitCheckIn>> findByUserId({
    required String userId,
    DateTime? from,
    DateTime? through,
    int? limit,
    int? offset,
  }) async {
    final conditions = <String>['user_id = ?'];
    final parameters = <Object?>[userId];

    if (from != null) {
      conditions.add('occurred_at >= ?');
      parameters.add(from.millisecondsSinceEpoch);
    }

    if (through != null) {
      conditions.add('occurred_at <= ?');
      parameters.add(through.millisecondsSinceEpoch);
    }

    var sql =
        'SELECT * FROM habit_check_ins WHERE ${conditions.join(' AND ')} '
        'ORDER BY occurred_at DESC';

    if (limit != null) {
      sql += ' LIMIT ?';
      parameters.add(limit);
    } else if (offset != null && offset > 0) {
      sql += ' LIMIT -1';
    }

    if (offset != null) {
      sql += ' OFFSET ?';
      parameters.add(offset);
    }

    return _db.select(sql, parameters).map(_fromRow).toList();
  }

  @override
  Future<void> deleteByHabitId(String habitId) async {
    _db.execute(
      'DELETE FROM habit_check_ins WHERE habit_id = ?',
      [habitId],
    );
  }

  HabitCheckIn _fromRow(Row row) {
    return HabitCheckIn(
      id: row['id'] as String,
      habitId: row['habit_id'] as String,
      userId: row['user_id'] as String,
      actualValue: (row['actual_value'] as num).toDouble(),
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        row['occurred_at'] as int,
      ),
    );
  }
}