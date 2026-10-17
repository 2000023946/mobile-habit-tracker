
abstract interface class UnitOfWork {
  Future<T> runInTransaction<T>(
    Future<T> Function() action,
  );
}
