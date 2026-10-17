import '../../domain/entities/habit_check_in.dart';
import '../../ports/repositories/habit_check_in_repository.dart';
import '../../ports/repositories/habit_repository.dart';
import '../common/date_utils.dart';
import '../common/validation.dart';

class GetHabitCheckIns {
  final HabitRepository habitRepository;
  final HabitCheckInRepository checkInRepository;

  const GetHabitCheckIns({
    required this.habitRepository,
    required this.checkInRepository,
  });

  Future<List<HabitCheckIn>> execute({
    required String userId,
    required String habitId,
    DateTime? from,
    DateTime? through,
    int limit = 50,
    int offset = 0,
  }) async {
    requireNonBlank(userId, 'User ID');
    requireNonBlank(habitId, 'Habit ID');

    _validatePagination(limit, offset);
    _validateDateRange(from, through);

    final habit = await habitRepository.findByIdForUser(
      userId: userId,
      habitId: habitId,
    );

    if (habit == null) {
      throw const NotFoundException('Habit not found.');
    }

    final checkIns = await checkInRepository.findByHabitId(
      habitId: habitId,
      from: from == null ? null : calendarDate(from),
      through: through == null ? null : calendarDate(through),
      limit: limit,
      offset: offset,
    );

    return List<HabitCheckIn>.unmodifiable(checkIns);
  }

  void _validatePagination(int limit, int offset) {
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
  }

  void _validateDateRange(DateTime? from, DateTime? through) {
    if (from != null &&
        through != null &&
        calendarDate(from).isAfter(calendarDate(through))) {
      throw const ValidationException(
        'The start date cannot be after the end date.',
      );
    }
  }
}