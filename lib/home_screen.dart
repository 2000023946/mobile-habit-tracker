import 'package:aegis_habit_rpg_mvp/habit_from_screen.dart';
import 'package:aegis_habit_rpg_mvp/src/api/habit_rpg_api.dart';
import 'package:aegis_habit_rpg_mvp/src/domain/entities/habit.dart';
import 'package:aegis_habit_rpg_mvp/src/domain/entities/user.dart';
import 'package:aegis_habit_rpg_mvp/src/domain/entities/user_progress.dart';
import 'package:flutter/material.dart';
import 'daily_habits_screen.dart';
import 'habit_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final HabitRpgApi api;
  final User user;
  final VoidCallback onSignOut;

  const HomeScreen({
    super.key,
    required this.api,
    required this.user,
    required this.onSignOut,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> _habits = [];
  UserProgress? _progress;
  int _lifetimeExp = 0;

  Set<String> _todayCompletedHabitIds = {};

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final now = DateTime.now();

      final habits = await widget.api.getUserHabits(
        userId: widget.user.id,
      );

      final progress = await widget.api.getUserProgress(
        userId: widget.user.id,
      );

      final lifetimeExp = await widget.api.getLifetimeExp(
        userId: widget.user.id,
      );

      // Fetch saved check-ins, then filter using today's local date.
      // This avoids relying on UTC date boundaries.
      final allCheckIns = await widget.api.getUserCheckIns(
        userId: widget.user.id,
      );

      final todayCheckIns = allCheckIns.where((checkIn) {
        final date = checkIn.occurredAt.toLocal();

        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();

      final completedIds = todayCheckIns
          .map((checkIn) => checkIn.habitId)
          .toSet();

      if (!mounted) return;

      setState(() {
        _habits = habits;
        _progress = progress;
        _lifetimeExp = lifetimeExp;
        _todayCompletedHabitIds = completedIds;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  String _formatCategory(HabitCategory category) {
    switch (category) {
      case HabitCategory.physicalActivity:
        return 'Physical Activity';
      case HabitCategory.studyAndLearning:
        return 'Study & Learning';
      case HabitCategory.mindAndFocus:
        return 'Mind & Focus';
      case HabitCategory.mindfulnessAndWellbeing:
        return 'Mindfulness & Well-being';
    }
  }

  IconData _categoryIcon(HabitCategory category) {
    switch (category) {
      case HabitCategory.physicalActivity:
        return Icons.fitness_center;
      case HabitCategory.studyAndLearning:
        return Icons.menu_book;
      case HabitCategory.mindAndFocus:
        return Icons.psychology;
      case HabitCategory.mindfulnessAndWellbeing:
        return Icons.spa;
    }
  }

  bool _isScheduledToday(Habit habit) {
    if (habit is ExecutionHabit) {
      final today = Weekday.values[DateTime.now().weekday - 1];
      return habit.scheduledDays.contains(today);
    }

    // Avoidance habits are included in today's progress.
    return habit is AvoidanceHabit;
  }

  int get _todayHabitCount {
    return _habits.where(_isScheduledToday).length;
  }

  int get _todayCompletedCount {
    return _habits
        .where(_isScheduledToday)
        .where((habit) => _todayCompletedHabitIds.contains(habit.id))
        .length;
  }

  double get _todayProgress {
    if (_todayHabitCount == 0) return 0;

    return _todayCompletedCount / _todayHabitCount;
  }

  Future<void> _createHabit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(
          api: widget.api,
          userId: widget.user.id,
        ),
      ),
    );

    await _loadDashboard();
  }

  Future<void> _openDailyHabits() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyHabitsScreen(
          api: widget.api,
          userId: widget.user.id,
        ),
      ),
    );

    // Refresh saved completion records after returning.
    await _loadDashboard();
  }

  Future<void> _openHabitDetails(Habit habit) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitDetailsScreen(
          api: widget.api,
          userId: widget.user.id,
          habit: habit,
        ),
      ),
    );

    await _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        title: const Text(
          'My Habits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF5F7F2),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh dashboard',
          ),
          IconButton(
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createHabit,
        backgroundColor: const Color(0xFF326B4B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Habit'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 20),
                      _buildTodayProgressCard(),
                      const SizedBox(height: 20),
                      _buildExperienceCard(progress),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Category Progress',
                        'Your RPG stats',
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryProgress(progress),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Your Habits',
                        '${_habits.length} total',
                      ),
                      const SizedBox(height: 12),
                      if (_habits.isEmpty)
                        _buildEmptyHabits()
                      else
                        ..._habits.map(_buildHabitCard),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _openDailyHabits,
                        icon: const Icon(Icons.today),
                        label: const Text("View Today's Habits"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF326B4B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: Color(0xFF326B4B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load your dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF326B4B),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WELCOME BACK',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Build consistency. Earn experience. Level up.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgressCard() {
    final percentage = (_todayProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E9E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Today's Progress",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Color(0xFF326B4B),
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$_todayCompletedCount of $_todayHabitCount habits completed',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _todayProgress,
              minHeight: 12,
              backgroundColor: const Color(0xFFE7ECE5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF326B4B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openDailyHabits,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Open Today's Habits"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF326B4B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(UserProgress? progress) {
    final level = progress?.overallLevel ?? 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFF326B4B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLAYER LEVEL',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF326B4B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  level.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'LIFETIME EXP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$_lifetimeExp',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF326B4B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryProgress(UserProgress? progress) {
    return Column(
      children: HabitCategory.values.map((category) {
        final categoryProgress = progress?.categories[category];
        final level = categoryProgress?.level ?? 1;
        final currentExp = categoryProgress?.currentExp ?? 0;
        final requiredExp =
            categoryProgress?.expRequiredForNextLevel ?? 100;

        final fraction = requiredExp <= 0
            ? 0.0
            : (currentExp / requiredExp).clamp(0.0, 1.0).toDouble();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E9E1)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: const Color(0xFF326B4B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatCategory(category),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE7ECE5),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          Color(0xFF326B4B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$currentExp / $requiredExp EXP',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    'LVL $level',
                    style: const TextStyle(
                      color: Color(0xFF326B4B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyHabits() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 42,
            color: Color(0xFF326B4B),
          ),
          SizedBox(height: 12),
          Text(
            'No habits yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create your first habit to start earning EXP.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final completedToday = _todayCompletedHabitIds.contains(habit.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4E9E1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F0E6),
          child: Icon(
            _categoryIcon(habit.category),
            color: const Color(0xFF326B4B),
          ),
        ),
        title: Text(
          habit.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration:
                completedToday ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${_formatCategory(habit.category)}'
          '${completedToday ? ' • Completed today' : ''}',
        ),
        trailing: Icon(
          completedToday ? Icons.check_circle : Icons.chevron_right,
          color: completedToday
              ? const Color(0xFF326B4B)
              : Colors.black45,
        ),
        onTap: () => _openHabitDetails(habit),
      ),
    );
  }
}