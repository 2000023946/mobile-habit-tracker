
import '../../domain/entities/user.dart';
import '../../ports/repositories/user_repository.dart';

class GetUserByUsername {
  const GetUserByUsername({
    required UserRepository userRepository,
  }) : _userRepository = userRepository;

  final UserRepository _userRepository;

  Future<User?> execute({
    required String username,
  }) {
    return _userRepository.findByUsername(
      username,
    );
  }
}
