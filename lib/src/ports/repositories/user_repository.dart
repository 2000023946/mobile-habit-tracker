

import 'package:aegis_habit_rpg_mvp/src/domain/entities/user.dart';

abstract interface class UserRepository {
  Future<void> save(User user);

  Future<User?> findById(String userId);

  Future<User?> findByUsername(String username);

  Future<bool> existsByUsername(String username);

  Future<void> delete(String userId);
}
