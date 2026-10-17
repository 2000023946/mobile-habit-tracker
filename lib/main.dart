
import 'package:aegis_habit_rpg_mvp/src/api/habit_rpg_api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aegis_habit_rpg_mvp/src/bootstrap/bootstrap.dart';
// Change this import if your HabitRpgApi is located elsewhere.

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final backend = await HabitRpgApp.bootstrap();
  final api = HabitRpgApi(
    createUser: backend.createUser,
    getUser: backend.getUser,
    getUserProgress: backend.getUserProgress,
    deleteUser: backend.deleteUser,
    createHabit: backend.createHabit,
    getHabit: backend.getHabit,
    getUserHabits: backend.getUserHabits,
    updateHabit: backend.updateHabit,
    deleteHabit: backend.deleteHabit,
    submitHabitCheckIn: backend.submitHabitCheckIn,
    getHabitCheckIns: backend.getHabitCheckIns,
    getUserCheckIns: backend.getUserCheckIns,
    processMissedHabit: backend.processMissedHabit,
    transactionRepository: backend.transactionRepository, 
    getUserByUsername: backend.getUserByUsername,
  );

  final preferences = await SharedPreferences.getInstance();

  runApp(
    HabitRpgFlutterApp(
      api: api,
      preferences: preferences,
    ),
  );
}
