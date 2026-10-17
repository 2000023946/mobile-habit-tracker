
import 'package:aegis_habit_rpg_mvp/habit_from_screen.dart';
import 'package:flutter/material.dart';

import '../src/api/habit_rpg_api.dart';
import '../src/domain/entities/habit.dart';

class HabitDetailsScreen extends StatefulWidget {
  const HabitDetailsScreen({
    super.key,
    required this.api,
    required this.userId,
    required this.habit,
  });

  final HabitRpgApi api;
  final String userId;
  final Habit habit;

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  late Habit _habit;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
  }

  String _label(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        );
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(
          api: widget.api,
          userId: widget.userId,
          habit: _habit,
        ),
      ),
    );

    if (changed != true || !mounted) return;

    try {
      final refreshed = await widget.api.getHabit(
        userId: widget.userId,
        habitId: _habit.id,
      );
      if (!mounted) return;
      setState(() => _habit = refreshed);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh habit: $error')),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'Are you sure you want to delete "${_habit.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);

    try {
      await widget.api.deleteHabit(
        userId: widget.userId,
        habitId: _habit.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete habit: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habit = _habit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Details'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _edit,
            tooltip: 'Edit habit',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _busy ? null : _delete,
            tooltip: 'Delete habit',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 32,
            child: Icon(
              habit is ExecutionHabit
                  ? Icons.check_circle_outline
                  : Icons.tune,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            habit.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _detail('Category', _label(habit.category.name)),
                  const Divider(),
                  _detail(
                    'Type',
                    habit is ExecutionHabit
                        ? 'Build a habit'
                        : 'Track a limit',
                  ),
                  if (habit is ExecutionHabit) ...[
                    const Divider(),
                    _detail(
                      'Scheduled days',
                      habit.scheduledDays
                          .map((day) => _label(day.name))
                          .join(', '),
                    ),
                    const Divider(),
                    _detail(
                      'Weekly target',
                      '${habit.weeklyTargetMinutes} minutes',
                    ),
                  ],
                  if (habit is AvoidanceHabit) ...[
                    const Divider(),
                    _detail('Limit type', _label(habit.targetType.name)),
                    const Divider(),
                    _detail('Target', habit.target.toString()),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _busy ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Habit'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Habit'),
          ),
        ],
      ),
    );
  }
}
