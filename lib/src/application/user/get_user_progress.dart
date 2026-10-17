import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_progression_repository.dart';
import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_repository.dart';

import '../../domain/entities/user_progress.dart';

import '../common/validation.dart';

class GetUserProgress {
  final UserRepository userRepository;
  final UserProgressRepository userProgressRepository;

  const GetUserProgress({
    required this.userRepository,
    required this.userProgressRepository,
  });

  Future<UserProgress> execute({
    required String userId,
  }) async {
    requireNonBlank(userId, 'User ID');

    final user = await userRepository.findById(userId);

    if (user == null) {
      throw const NotFoundException('User not found.');
    }

    final progress =
        await userProgressRepository.findByUserId(userId);

    if (progress == null) {
      throw const NotFoundException(
        'User progression has not been initialized.',
      );
    }

    return progress;
  }
}