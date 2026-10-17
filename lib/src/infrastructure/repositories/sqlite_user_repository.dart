import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/user.dart';
import '../../ports/repositories/user_repository.dart';
import '../database/app_database.dart';

class SqliteUserRepository implements UserRepository {
  final AppDatabase appDatabase;

  const SqliteUserRepository(this.appDatabase);

  Database get _db => appDatabase.database;

  @override
  Future<void> save(User user) async {
    _db.execute(
      '''
      INSERT INTO users (id, username, created_at)
      VALUES (?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        username = excluded.username
      ''',
      [user.id, user.username, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<User?> findById(String userId) async {
    final rows = _db.select(
      'SELECT id, username FROM users WHERE id = ?',
      [userId],
    );

    if (rows.isEmpty) return null;

    return User(
      id: rows.first['id'] as String,
      username: rows.first['username'] as String,
    );
  }

  @override
  Future<User?> findByUsername(String username) async {
    final rows = _db.select(
      'SELECT id, username FROM users WHERE username = ? COLLATE NOCASE',
      [username.trim()],
    );

    if (rows.isEmpty) return null;

    return User(
      id: rows.first['id'] as String,
      username: rows.first['username'] as String,
    );
  }

  @override
  Future<bool> existsByUsername(String username) async {
    final rows = _db.select(
      'SELECT 1 FROM users WHERE username = ? COLLATE NOCASE LIMIT 1',
      [username.trim()],
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> delete(String userId) async {
    _db.execute('DELETE FROM users WHERE id = ?', [userId]);
  }
}