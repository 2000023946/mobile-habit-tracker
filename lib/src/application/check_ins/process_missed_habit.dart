import '../../domain/entities/experience_transaction.dart';
import '../../domain/entities/habit.dart';
import '../../domain/services/habit_progression_service.dart';
import '../../ports/id_generator.dart';
import '../../ports/repositories/experience_transaction_repository.dart';
import '../../ports/repositories/habit_check_in_repository.dart';
import '../../ports/repositories/habit_repository.dart';
import '../../ports/repositories/user_progression_repository.dart';
import '../../ports/repositories/user_repository.dart';
import '../../ports/unit_of_work.dart';
import '../common/date_utils.dart';
import '../common/validation.dart';

class ProcessMissedHabit {
  final UserRepository userRepository;
  final HabitRepository habitRepository;
  final HabitCheckInRepository checkInRepository;
  final UserProgressRepository progressRepository;
  final ExperienceTransactionRepository transactionRepository;
  final HabitProgressionService progressionService;
  final UnitOfWork unitOfWork;
  final IdGenerator idGenerator;

  const ProcessMissedHabit({
    required this.userRepository,
    required this.habitRepository,
    required this.checkInRepository,
    required this.progressRepository,
    required this.transactionRepository,
    required this.progressionService,
    required this.unitOfWork,
    required this.idGenerator,
  });

  Future<void> execute({
    required String userId,
    required String habitId,
    required DateTime missedDate,
  }) async {
    requireNonBlank(userId, 'User ID');
    requireNonBlank(habitId, 'Habit ID');

    final date = calendarDate(missedDate);

    if (!date.isBefore(calendarDate(DateTime.now()))) {
      throw const ValidationException(
        'A habit can only be marked missed after its scheduled day ends.',
      );
    }

    await unitOfWork.runInTransaction(() async {
      final user = await userRepository.findById(userId);

      if (user == null) {
        throw const NotFoundException('User not found.');
      }

      final habit = await habitRepository.findByIdForUser(
        userId: userId,
        habitId: habitId,
      );

      if (habit == null) {
        throw const NotFoundException('Habit not found.');
      }

      if (habit is! ExecutionHabit) {
        throw const ValidationException(
          'Missed-commitment penalties only apply to execution habits.',
        );
      }

      if (!habit.isScheduledOn(_weekdayFor(date))) {
        throw const ValidationException(
          'This habit was not scheduled for the selected day.',
        );
      }

      final checkIn = await checkInRepository.findByHabitAndDate(
        habitId: habitId,
        date: date,
      );

      if (checkIn != null) {
        throw const ConflictException(
          'This habit already has a check-in for the selected day.',
        );
      }

      final existingPenalty =
          await transactionRepository.hasTransactionForHabitDate(
        habitId: habitId,
        date: date,
        type: ExperienceTransactionType.missedCommitmentPenalty,
      );

      if (existingPenalty != null) {
        throw const ConflictException(
          'This missed commitment has already been processed.',
        );
      }

      final progress =
          await progressRepository.findByUserId(userId);

      if (progress == null) {
        throw const NotFoundException(
          'User progression has not been initialized.',
        );
      }

      final eventId = idGenerator.newId();

      final result = progressionService.processMissedExecution(
        habit: habit,
        userProgress: progress,
        checkInOrEventId: eventId,
        missedDate: date,
      );

      final transaction = ExperienceTransaction(
        id: eventId,
        userId: userId,
        habitId: habitId,
        category: habit.category,
        categoryProgressKey: habit.category.name,
        amount: result.expDelta,
        type: ExperienceTransactionType.missedCommitmentPenalty,
        description: result.description,
        createdAt: DateTime.now(),
      );

      await progressRepository.save(progress);
      await transactionRepository.save(transaction);
    });
  }

  Weekday _weekdayFor(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return Weekday.monday;
      case DateTime.tuesday:
        return Weekday.tuesday;
      case DateTime.wednesday:
        return Weekday.wednesday;
      case DateTime.thursday:
        return Weekday.thursday;
      case DateTime.friday:
        return Weekday.friday;
      case DateTime.saturday:
        return Weekday.saturday;
      case DateTime.sunday:
        return Weekday.sunday;
      default:
        throw StateError('Unexpected weekday: ${date.weekday}');
    }
  }
}