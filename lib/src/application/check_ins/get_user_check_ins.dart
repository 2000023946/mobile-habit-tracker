import '../../domain/entities/habit_check_in.dart';
import '../../ports/repositories/habit_check_in_repository.dart';
import '../../ports/repositories/user_repository.dart';
import '../common/date_utils.dart';
import '../common/validation.dart';

class GetUserCheckIns {
  final UserRepository userRepository;
  final HabitCheckInRepository checkInRepository;

  const GetUserCheckIns({
    required this.userRepository,
    required this.checkInRepository,
  });

  Future<List<HabitCheckIn>> execute({
    required String userId,
    DateTime? from,
    DateTime? through,
    int limit = 50,
    int offset = 0,
  }) async {
    requireNonBlank(userId, 'User ID');

    if (limit < 1 || limit > 200) {
      throw const ValidationException(
        'Limit must be between 1 and 200.',
      );
    }

    if (offset < 0) {
      throw const ValidationException(
        'Offset cannot be negative.',
      );
    }

    if (from != null &&
        through != null &&
        calendarDate(from).isAfter(calendarDate(through))) {
      throw const ValidationException(
        'The start date cannot be after the end date.',
      );
    }

    final user = await userRepository.findById(userId);

    if (user == null) {
      throw const NotFoundException('User not found.');
    }

    final checkIns = await checkInRepository.findByUserId(
      userId: userId,
      from: from == null ? null : calendarDate(from),
      through: through == null ? null : calendarDate(through),
      limit: limit,
      offset: offset,
    );

    return List<HabitCheckIn>.unmodifiable(checkIns);
  }
}