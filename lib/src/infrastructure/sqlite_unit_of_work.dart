
import '../ports/unit_of_work.dart';
import 'database/app_database.dart';

class SqliteUnitOfWork implements UnitOfWork {
  final AppDatabase appDatabase;

  const SqliteUnitOfWork(this.appDatabase);

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function() action,
  ) {
    return appDatabase.transaction(action);
  }
}
