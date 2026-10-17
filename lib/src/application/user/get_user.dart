import 'package:aegis_habit_rpg_mvp/src/ports/repositories/user_repository.dart';

import '../../domain/entities/user.dart';
import '../common/validation.dart';

class GetUser {
  final UserRepository userRepository;

  const GetUser({
    required this.userRepository,
  });

  Future<User> execute({
    required String userId,
  }) async {
    requireNonBlank(userId, 'User ID');

    final user = await userRepository.findById(userId);

    if (user == null) {
      throw const NotFoundException('User not found.');
    }

    return user;
  }
}