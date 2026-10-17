import 'package:aegis_habit_rpg_mvp/src/ports/id_generator.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_progression_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_repository.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/user_progress.dart';

import '../../ports/unit_of_work.dart';
import '../common/validation.dart';

class CreateUser {
  final UserRepository userRepository;
  final UserProgressRepository userProgressRepository;
  final UnitOfWork unitOfWork;
  final IdGenerator idGenerator;

  const CreateUser({
    required this.userRepository,
    required this.userProgressRepository,
    required this.unitOfWork,
    required this.idGenerator,
  });

  Future<User> execute({
    required String username,
  }) async {
    requireNonBlank(username, 'Username');

    final normalizedUsername = username.trim();

    return unitOfWork.runInTransaction(() async {
      final exists =
          await userRepository.existsByUsername(normalizedUsername);

      if (exists) {
        throw const ConflictException(
          'A user with this username already exists.',
        );
      }

      final user = User(
        id: idGenerator.newId(),
        username: normalizedUsername,
      );

      final progress = UserProgress(userId: user.id);

      await userRepository.save(user);
      await userProgressRepository.save(progress);

      return user;
    });
  }
}
