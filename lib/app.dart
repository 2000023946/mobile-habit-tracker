
import 'package:aegis_habit_rpg_mvp/src/api/habit_rpg_api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aegis_habit_rpg_mvp/src/domain/entities/user.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class HabitRpgFlutterApp extends StatefulWidget {
  const HabitRpgFlutterApp({
    super.key,
    required this.api,
    required this.preferences,
  });

  final HabitRpgApi api;
  final SharedPreferences preferences;

  @override
  State<HabitRpgFlutterApp> createState() =>
      _HabitRpgFlutterAppState();
}

class _HabitRpgFlutterAppState extends State<HabitRpgFlutterApp> {
  static const _userIdKey = 'active_user_id';

  User? _activeUser;
  bool _loadingSession = true;
  bool _signingIn = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final userId = widget.preferences.getString(_userIdKey);

      if (userId != null && userId.isNotEmpty) {
        final user = await widget.api.getUser(userId);

        if (mounted) {
          setState(() => _activeUser = user);
        }
      }
    } catch (_) {
      await widget.preferences.remove(_userIdKey);
    } finally {
      if (mounted) {
        setState(() => _loadingSession = false);
      }
    }
  }

  Future<void> _continueWithUsername(String username) async {
    if (_signingIn) return;

    setState(() => _signingIn = true);

    try {
      final normalizedUsername = username.trim();

      if (normalizedUsername.isEmpty) {
        throw ArgumentError('Enter a username to continue.');
      }

      // This method must be implemented by HabitRpgApi.
      // It returns null when no account has that username.
      final existingUser = await widget.api.getUserByUsername(
        normalizedUsername,
      );

      final user = (existingUser ??
          await widget.api.createUser(username: normalizedUsername)) as User;

      await widget.preferences.setString(_userIdKey, user.id);

      if (!mounted) return;

      setState(() {
        _activeUser = user as User?;
        _signingIn = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _signingIn = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not continue: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await widget.preferences.remove(_userIdKey);

    if (!mounted) return;

    setState(() => _activeUser = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF52796F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F6),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E6E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E6E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF52796F),
              width: 1.5,
            ),
          ),
        ),
      ),
      home: _loadingSession
          ? const _LoadingScreen()
          : _activeUser == null
              ? LoginScreen(
                  onContinue: _continueWithUsername,
                  isLoading: _signingIn,
                )
              : HomeScreen(
                  api: widget.api,
                  user: _activeUser!,
                  onSignOut: _signOut,
                ),
    );
  }
}



class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
