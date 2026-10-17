
import 'package:flutter/material.dart';

import '../src/api/habit_rpg_api.dart';
import '../src/domain/entities/habit.dart';
import 'habit_details_screen.dart';

class DailyHabitsScreen extends StatefulWidget {
  const DailyHabitsScreen({
    super.key,
    required this.api,
    required this.userId,
  });

  final HabitRpgApi api;
  final String userId;

  @override
  State<DailyHabitsScreen> createState() => _DailyHabitsScreenState();
}

class _DailyHabitsScreenState extends State<DailyHabitsScreen> {
  late Future<List<Habit>> _habitsFuture;

  // IDs of habits completed today, loaded from saved check-ins.
  Set<String> _completedHabitIds = {};

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _habitsFuture = _loadHabits();
  }

  Future<List<Habit>> _loadHabits() async {
    final now = DateTime.now();

    // Load each result separately so Dart preserves its type.
    final List<Habit> habits = await widget.api.getUserHabits(
      userId: widget.userId,
    );

    final checkIns = await widget.api.getUserCheckIns(
      userId: widget.userId,
    );

    final completedIds = <String>{};

    for (final checkIn in checkIns) {
      final date = checkIn.occurredAt.toLocal();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        completedIds.add(checkIn.habitId);
      }
    }

    if (mounted) {
      setState(() {
        _completedHabitIds = completedIds;
      });
    }

    return habits;
  }

  String _label(String value) {
    return value.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]}',
    );
  }

  Future<void> _refresh() async {
    final future = _loadHabits();

    setState(() {
      _habitsFuture = future;
    });

    await future;
  }

  Future<void> _completeHabit(Habit habit) async {
    if (_saving || _completedHabitIds.contains(habit.id)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final result = await widget.api.submitHabitCheckIn(
        userId: widget.userId,
        habitId: habit.id,
        actualValue: 1,
      );

      if (!mounted) return;

      setState(() {
        _completedHabitIds.add(habit.id);
      });

      final exp = result.expDelta;
      final expText = exp > 0
          ? '+$exp EXP'
          : exp < 0
              ? '$exp EXP'
              : 'No EXP change';

      final levelText = result.levelChanged
          ? '\nLevel up! ${result.levelBefore} → ${result.levelAfter}'
          : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Habit completed! $expText$levelText'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not complete habit: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _openDetails(Habit habit) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HabitDetailsScreen(
          api: widget.api,
          userId: widget.userId,
          habit: habit,
        ),
      ),
    );

    if (!mounted) return;

    if (deleted == true) {
      setState(() {
        _completedHabitIds.remove(habit.id);
      });
    }

    await _refresh();
  }

  Widget _sectionTitle(
    String title,
    int count, {
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count'),
          ),
        ],
      ),
    );
  }

  Widget _habitCard(
    Habit habit, {
    required bool completed,
  }) {
    final subtitle = habit is ExecutionHabit
        ? 'Weekly target: ${habit.weeklyTargetMinutes} minutes'
        : habit is AvoidanceHabit
            ? 'Limit: ${habit.target}'
            : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        leading: Checkbox(
          value: completed,
          onChanged: completed || _saving
              ? null
              : (_) => _completeHabit(habit),
        ),
        title: Text(
          habit.name,
          style: TextStyle(
            decoration:
                completed ? TextDecoration.lineThrough : null,
            color: completed ? Colors.grey : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${_label(habit.category.name)}'
            '${subtitle.isNotEmpty ? '\n$subtitle' : ''}',
          ),
        ),
        isThreeLine: subtitle.isNotEmpty,
        trailing: Icon(
          completed ? Icons.check_circle : Icons.circle_outlined,
          color: completed ? Colors.green : null,
        ),
        onTap: () => _openDetails(habit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = Weekday.values[DateTime.now().weekday - 1];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Habits'),
        actions: [
          IconButton(
            tooltip: 'Refresh habits',
            onPressed: _saving ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Habit>>(
        future: _habitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load your habits.'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final habits = (snapshot.data ?? []).where((habit) {
            if (habit is ExecutionHabit) {
              return habit.scheduledDays.contains(today);
            }
            return true;
          }).toList();

          final todoHabits = habits
              .where(
                (habit) => !_completedHabitIds.contains(habit.id),
              )
              .toList();

          final completedHabits = habits
              .where(
                (habit) => _completedHabitIds.contains(habit.id),
              )
              .toList();

          final progress = habits.isEmpty
              ? 0.0
              : completedHabits.length / habits.length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  MaterialLocalizations.of(context).formatFullDate(
                    DateTime.now(),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${completedHabits.length} of ${habits.length} habits completed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (habits.isNotEmpty)
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                if (_saving) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 6),
                  const Text('Saving completion...'),
                ],
                const SizedBox(height: 12),
                _sectionTitle(
                  'To Do',
                  todoHabits.length,
                  icon: Icons.radio_button_unchecked,
                ),
                if (todoHabits.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('You have finished all your habits!'),
                  )
                else
                  ...todoHabits.map(
                    (habit) => _habitCard(
                      habit,
                      completed: false,
                    ),
                  ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),
                _sectionTitle(
                  'Completed',
                  completedHabits.length,
                  icon: Icons.check_circle_outline,
                ),
                if (completedHabits.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Completed habits will appear here.',
                    ),
                  )
                else
                  ...completedHabits.map(
                    (habit) => _habitCard(
                      habit,
                      completed: true,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
