import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_progression_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_repository.dart';

import '../../ports/unit_of_work.dart';
import '../common/validation.dart';

class DeleteUser {
  final UserRepository userRepository;
  final UserProgressRepository userProgressRepository;
  final UnitOfWork unitOfWork;

  const DeleteUser({
    required this.userRepository,
    required this.userProgressRepository,
    required this.unitOfWork,
  });

  Future<void> execute({
    required String userId,
  }) async {
    requireNonBlank(userId, 'User ID');

    return unitOfWork.runInTransaction(() async {
      final user = await userRepository.findById(userId);

      if (user == null) {
        throw const NotFoundException('User not found.');
      }

      await userProgressRepository.deleteByUserId(userId);
      await userRepository.delete(userId);
    });
  }
}