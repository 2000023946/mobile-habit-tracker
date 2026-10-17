
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database_schema.dart';

class AppDatabase {
  AppDatabase._(this._database) {
    _database.execute('PRAGMA foreign_keys = ON;');
    DatabaseSchema.create(_database);
  }

  /// Creates a persistent SQLite database on the device.
  static Future<AppDatabase> open() async {
    final directory = await getApplicationSupportDirectory();
    final databasePath = p.join(directory.path, 'habit_rpg.db');

    final database = sqlite3.open(databasePath);

    return AppDatabase._(database);
  }

  /// Creates an in-memory database for tests.
  factory AppDatabase.inMemory() {
    return AppDatabase._(sqlite3.openInMemory());
  }

  final Database _database;

  bool _isClosed = false;
  bool _isInTransaction = false;

  Database get database {
    if (_isClosed) {
      throw StateError('The database has already been closed.');
    }
    return _database;
  }

  bool get isInTransaction => _isInTransaction;

  Future<T> transaction<T>(Future<T> Function() action) async {
    if (_isClosed) {
      throw StateError('The database has already been closed.');
    }

    if (_isInTransaction) {
      throw StateError(
        'Nested transactions are not supported by AppDatabase.',
      );
    }

    _database.execute('BEGIN IMMEDIATE;');
    _isInTransaction = true;

    try {
      final result = await action();
      _database.execute('COMMIT;');
      return result;
    } catch (_) {
      try {
        _database.execute('ROLLBACK;');
      } catch (_) {
        // Preserve the original operation error.
      }
      rethrow;
    } finally {
      _isInTransaction = false;
    }
  }

  void close() {
    if (_isClosed) return;

    if (_isInTransaction) {
      throw StateError(
        'Cannot close the database while a transaction is active.',
      );
    }

    _database.dispose();
    _isClosed = true;
  }
}
