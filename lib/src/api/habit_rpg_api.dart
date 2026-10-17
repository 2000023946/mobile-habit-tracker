
import 'package:aegis_habit_rpg_mvp/src/application/check_ins/submit_habit_check_ins.dart';
import 'package:aegis_habit_rpg_mvp/src/application/user/get_user_by_username.dart';

import '../domain/entities/experience_transaction.dart';
import '../domain/entities/habit.dart';
import '../domain/entities/habit_check_in.dart';
import '../domain/entities/user.dart';
import '../domain/entities/user_progress.dart';
import '../domain/services/habit_progression_service.dart';

import '../application/user/create_user.dart';
import '../application/user/delete_user.dart';
import '../application/user/get_user.dart';
import '../application/user/get_user_progress.dart';

import '../application/habits/create_habit.dart';
import '../application/habits/get_habit.dart';
import '../application/habits/get_user_habits.dart';
import '../application/habits/update_habit.dart';
import '../application/habits/delete_habit.dart';

import '../application/check_ins/get_habit_check_ins.dart';
import '../application/check_ins/get_user_check_ins.dart';
import '../application/check_ins/process_missed_habit.dart';

import '../ports/repositories/experience_transaction_repository.dart';

class HabitRpgApi {
  final CreateUser _createUser;
  final GetUser _getUser;
  final GetUserProgress _getUserProgress;
  final DeleteUser _deleteUser;
  final GetUserByUsername _getUserByUsername;

  final CreateHabit _createHabit;
  final GetHabit _getHabit;
  final GetUserHabits _getUserHabits;
  final UpdateHabit _updateHabit;
  final DeleteHabit _deleteHabit;

  final SubmitHabitCheckIn _submitHabitCheckIn;
  final GetHabitCheckIns _getHabitCheckIns;
  final GetUserCheckIns _getUserCheckIns;
  final ProcessMissedHabit _processMissedHabit;

  final ExperienceTransactionRepository _transactionRepository;

  const HabitRpgApi({
    required CreateUser createUser,
    required GetUser getUser,
    required GetUserProgress getUserProgress,
    required DeleteUser deleteUser,
    required GetUserByUsername getUserByUsername,
    required CreateHabit createHabit,
    required GetHabit getHabit,
    required GetUserHabits getUserHabits,
    required UpdateHabit updateHabit,
    required DeleteHabit deleteHabit,
    required SubmitHabitCheckIn submitHabitCheckIn,
    required GetHabitCheckIns getHabitCheckIns,
    required GetUserCheckIns getUserCheckIns,
    required ProcessMissedHabit processMissedHabit,
    required ExperienceTransactionRepository transactionRepository,
  })  : _createUser = createUser,
        _getUser = getUser,
        _getUserProgress = getUserProgress,
        _deleteUser = deleteUser,
        _getUserByUsername = getUserByUsername,
        _createHabit = createHabit,
        _getHabit = getHabit,
        _getUserHabits = getUserHabits,
        _updateHabit = updateHabit,
        _deleteHabit = deleteHabit,
        _submitHabitCheckIn = submitHabitCheckIn,
        _getHabitCheckIns = getHabitCheckIns,
        _getUserCheckIns = getUserCheckIns,
        _processMissedHabit = processMissedHabit,
        _transactionRepository = transactionRepository;

  // ---------------------------------------------------------------------------
  // USERS
  // ---------------------------------------------------------------------------

  Future<User> createUser({
    required String username,
  }) {
    return _createUser.execute(username: username);
  }

  Future<User?> getUser(String userId) {
    return _getUser.execute(userId: userId);
  }

  Future<UserProgress?> getUserProgress({
    required String userId,
  }) {
    return _getUserProgress.execute(userId: userId);
  }

  Future<void> deleteUser({
    required String userId,
  }) {
    return _deleteUser.execute(userId: userId);
  }

  // ---------------------------------------------------------------------------
  // HABITS
  // ---------------------------------------------------------------------------

  Future<Habit> createHabit({
    required String userId,
    required Habit habit,
  }) {
    return _createHabit.execute(
      userId: userId,
      habit: habit,
    );
  }

  Future<Habit> getHabit({
    required String userId,
    required String habitId,
  }) {
    return _getHabit.execute(
      userId: userId,
      habitId: habitId,
    );
  }

  Future<List<Habit>> getUserHabits({
    required String userId,
    HabitCategory? category,
  }) {
    return _getUserHabits.execute(
      userId: userId,
      category: category,
    );
  }

  Future<Habit> updateHabit({
    required String userId,
    required String habitId,
    required Habit updatedHabit,
  }) {
    return _updateHabit.execute(
      userId: userId,
      habitId: habitId,
      updatedHabit: updatedHabit,
    );
  }

  Future<void> deleteHabit({
    required String userId,
    required String habitId,
  }) {
    return _deleteHabit.execute(
      userId: userId,
      habitId: habitId,
    );
  }

  // ---------------------------------------------------------------------------
  // CHECK-INS AND PROGRESSION
  // ---------------------------------------------------------------------------

  Future<HabitProgressionResult> submitHabitCheckIn({
    required String userId,
    required String habitId,
    required double actualValue,
    DateTime? occurredAt,
  }) {
    return _submitHabitCheckIn.execute(
      userId: userId,
      habitId: habitId,
      actualValue: actualValue,
      occurredAt: occurredAt,
    );
  }

  Future<List<HabitCheckIn>> getHabitCheckIns({
    required String userId,
    required String habitId,
    DateTime? from,
    DateTime? through,
    int limit = 50,
    int offset = 0,
  }) {
    return _getHabitCheckIns.execute(
      userId: userId,
      habitId: habitId,
      from: from,
      through: through,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<HabitCheckIn>> getUserCheckIns({
    required String userId,
    DateTime? from,
    DateTime? through,
    int limit = 50,
    int offset = 0,
  }) {
    return _getUserCheckIns.execute(
      userId: userId,
      from: from,
      through: through,
      limit: limit,
      offset: offset,
    );
  }

  Future<void> processMissedHabit({
    required String userId,
    required String habitId,
    required DateTime missedDate,
  }) {
    return _processMissedHabit.execute(
      userId: userId,
      habitId: habitId,
      missedDate: missedDate,
    );
  }

  // ---------------------------------------------------------------------------
  // EXPERIENCE HISTORY
  // ---------------------------------------------------------------------------

  Future<List<ExperienceTransaction>> getExperienceHistory({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) {
    return _transactionRepository.findByUserId(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<ExperienceTransaction>> getHabitExperienceHistory({
    required String habitId,
    int limit = 50,
    int offset = 0,
  }) {
    return _transactionRepository.findByHabitId(
      habitId: habitId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<ExperienceTransaction>> getCategoryExperienceHistory({
    required String userId,
    required String categoryProgressKey,
    int limit = 50,
    int offset = 0,
  }) {
    return _transactionRepository.findByCategory(
      userId: userId,
      categoryProgressKey: categoryProgressKey,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> getLifetimeExp({
    required String userId,
  }) {
    return _transactionRepository.sumLifetimeExp(userId);
  }

  Future<Object?> getUserByUsername(String normalizedUsername) async {
    return _getUserByUsername.execute(
      username: normalizedUsername,
    );
  }
}
