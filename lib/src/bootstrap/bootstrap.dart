
import 'package:aegis_habit_rpg_mvp/src/application/check_ins/submit_habit_check_ins.dart';
import 'package:aegis_habit_rpg_mvp/src/application/user/create_user.dart';
import 'package:aegis_habit_rpg_mvp/src/application/user/delete_user.dart';
import 'package:aegis_habit_rpg_mvp/src/application/user/get_user.dart';
import 'package:aegis_habit_rpg_mvp/src/application/user/get_user_by_username.dart';
import 'package:aegis_habit_rpg_mvp/src/application/user/get_user_progress.dart';

import '../application/habits/create_habit.dart';
import '../application/habits/get_habit.dart';
import '../application/habits/get_user_habits.dart';
import '../application/habits/update_habit.dart';
import '../application/habits/delete_habit.dart';

import '../application/check_ins/get_habit_check_ins.dart';
import '../application/check_ins/get_user_check_ins.dart';
import '../application/check_ins/process_missed_habit.dart';

import '../domain/services/habit_progression_service.dart';

import '../infrastructure/database/app_database.dart';
import '../infrastructure/id_generator.dart';
import '../infrastructure/repositories/sqlite_user_repository.dart';
import '../infrastructure/repositories/sqlite_habit_repository.dart';
import '../infrastructure/repositories/sqlite_user_progress_repository.dart';
import '../infrastructure/repositories/sqlite_habit_check_in_repository.dart';
import '../infrastructure/repositories/sqlite_streak_repository.dart';
import '../infrastructure/repositories/sqlite_experience_transaction_repository.dart';
import '../infrastructure/sqlite_unit_of_work.dart';

class HabitRpgApp {
  final AppDatabase database;

  final SqliteUserRepository userRepository;
  final SqliteHabitRepository habitRepository;
  final SqliteUserProgressRepository progressRepository;
  final SqliteHabitCheckInRepository checkInRepository;
  final SqliteStreakRepository streakRepository;
  final SqliteExperienceTransactionRepository transactionRepository;

  final UuidIdGenerator idGenerator;
  final SqliteUnitOfWork unitOfWork;
  final HabitProgressionService progressionService;

  late final CreateUser createUser;
  late final GetUser getUser;
  late final GetUserProgress getUserProgress;
  late final DeleteUser deleteUser;
  late final GetUserByUsername getUserByUsername;

  late final CreateHabit createHabit;
  late final GetHabit getHabit;
  late final GetUserHabits getUserHabits;
  late final UpdateHabit updateHabit;
  late final DeleteHabit deleteHabit;

  late final SubmitHabitCheckIn submitHabitCheckIn;
  late final GetHabitCheckIns getHabitCheckIns;
  late final GetUserCheckIns getUserCheckIns;
  late final ProcessMissedHabit processMissedHabit;

  HabitRpgApp._({
    required this.database,
    required this.userRepository,
    required this.habitRepository,
    required this.progressRepository,
    required this.checkInRepository,
    required this.streakRepository,
    required this.transactionRepository,
    required this.idGenerator,
    required this.unitOfWork,
    required this.progressionService,
  }) {
    createUser = CreateUser(
      userRepository: userRepository,
      userProgressRepository: progressRepository,
      unitOfWork: unitOfWork,
      idGenerator: idGenerator,
    );

    getUser = GetUser(
      userRepository: userRepository,
    );

    getUserByUsername = GetUserByUsername(
      userRepository: userRepository,
    );

    getUserProgress = GetUserProgress(
      userRepository: userRepository,
      userProgressRepository: progressRepository,
    );

    deleteUser = DeleteUser(
      userRepository: userRepository,
      userProgressRepository: progressRepository,
      unitOfWork: unitOfWork,
    );

    createHabit = CreateHabit(
      habitRepository: habitRepository,
      userRepository: userRepository,
      idGenerator: idGenerator,
    );

    getHabit = GetHabit(
      habitRepository: habitRepository,
    );

    getUserHabits = GetUserHabits(
      habitRepository: habitRepository,
      userRepository: userRepository,
    );

    updateHabit = UpdateHabit(
      habitRepository: habitRepository,
    );

    deleteHabit = DeleteHabit(
      habitRepository: habitRepository,
      habitCheckInRepository: checkInRepository,
      streakRepository: streakRepository,
      unitOfWork: unitOfWork,
    );

    submitHabitCheckIn = SubmitHabitCheckIn(
      userRepository: userRepository,
      habitRepository: habitRepository,
      checkInRepository: checkInRepository,
      progressRepository: progressRepository,
      streakRepository: streakRepository,
      transactionRepository: transactionRepository,
      progressionService: progressionService,
      idGenerator: idGenerator,
      unitOfWork: unitOfWork,
    );

    getHabitCheckIns = GetHabitCheckIns(
      habitRepository: habitRepository,
      checkInRepository: checkInRepository,
    );

    getUserCheckIns = GetUserCheckIns(
      userRepository: userRepository,
      checkInRepository: checkInRepository,
    );

    processMissedHabit = ProcessMissedHabit(
      userRepository: userRepository,
      habitRepository: habitRepository,
      checkInRepository: checkInRepository,
      progressRepository: progressRepository,
      transactionRepository: transactionRepository,
      progressionService: progressionService,
      unitOfWork: unitOfWork,
      idGenerator: idGenerator,
    );
  }

  /// Opens the persistent database unless one is injected.
  static Future<HabitRpgApp> bootstrap({
    AppDatabase? database,
  }) async {
    final db = database ?? await AppDatabase.open();

    try {
      final users = SqliteUserRepository(db);
      final habits = SqliteHabitRepository(db);
      final progress = SqliteUserProgressRepository(db);
      final checkIns = SqliteHabitCheckInRepository(db);
      final streaks = SqliteStreakRepository(db);
      final transactions = SqliteExperienceTransactionRepository(db);

      const ids = UuidIdGenerator();
      final unitOfWork = SqliteUnitOfWork(db);
      const progressionService = HabitProgressionService();

      return HabitRpgApp._(
        database: db,
        userRepository: users,
        habitRepository: habits,
        progressRepository: progress,
        checkInRepository: checkIns,
        streakRepository: streaks,
        transactionRepository: transactions,
        idGenerator: ids,
        unitOfWork: unitOfWork,
        progressionService: progressionService,
      );
    } catch (_) {
      // Only close a database created by this bootstrap call.
      if (database == null) {
        db.close();
      }
      rethrow;
    }
  }

  void close() {
    database.close();
  }
}
