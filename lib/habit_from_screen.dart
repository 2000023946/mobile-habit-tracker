
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../src/domain/entities/habit.dart';

import '../src/api/habit_rpg_api.dart';

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({
    super.key,
    required this.api,
    required this.userId,
    this.habit,
  });

  final HabitRpgApi api;
  final String userId;
  final Habit? habit;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();

  HabitCategory _category = HabitCategory.physicalActivity;
  bool _isExecution = true;
  AvoidanceTargetType _targetType = AvoidanceTargetType.timeLimit;
  final Set<Weekday> _days = {};
  bool _saving = false;

  static const _weekdays = Weekday.values;

  bool get _editing => widget.habit != null;

  @override
  void initState() {
    super.initState();

    final habit = widget.habit;
    if (habit == null) return;

    _nameController.text = habit.name;
    _category = habit.category;

    if (habit is ExecutionHabit) {
      _isExecution = true;
      _days.addAll(habit.scheduledDays);
      _targetController.text = habit.weeklyTargetMinutes.toString();
    } else if (habit is AvoidanceHabit) {
      _isExecution = false;
      _targetType = habit.targetType;
      _targetController.text = habit.target.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  String _label(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceFirst(value[0], value[0].toUpperCase());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isExecution && _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one day.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      final id = widget.habit?.id ?? const Uuid().v4();

      final Habit updatedHabit;

      if (_isExecution) {
        updatedHabit = ExecutionHabit(
          id: id,
          userId: widget.userId,
          name: name,
          category: _category,
          scheduledDays: Set<Weekday>.from(_days),
          weeklyTargetMinutes: int.parse(_targetController.text.trim()),
        );
      } else {
        updatedHabit = AvoidanceHabit(
          id: id,
          userId: widget.userId,
          name: name,
          category: _category,
          target: double.parse(_targetController.text.trim()),
          targetType: _targetType,
        );
      }

      if (_editing) {
        await widget.api.updateHabit(
          userId: widget.userId,
          habitId: widget.habit!.id,
          updatedHabit: updatedHabit,
        );
      } else {
        await widget.api.createHabit(
          userId: widget.userId,
          habit: updatedHabit,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save habit: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Habit' : 'Create Habit'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  hintText: 'e.g. Read for 20 minutes',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Enter a habit name.'
                        : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<HabitCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: HabitCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(_label(category.name)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Habit type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Build a habit'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Track a limit'),
                    icon: Icon(Icons.tune),
                  ),
                ],
                selected: {_isExecution},
                onSelectionChanged: (selection) {
                  setState(() {
                    _isExecution = selection.first;
                    _targetController.clear();
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_isExecution) ...[
                const Text(
                  'Scheduled days',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _weekdays.map((day) {
                    final selected = _days.contains(day);
                    return FilterChip(
                      label: Text(_label(day.name).substring(0, 3)),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _days.add(day);
                          } else {
                            _days.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weekly target (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final number = int.tryParse(value ?? '');
                    if (number == null || number <= 0) {
                      return 'Enter a number greater than zero.';
                    }
                    return null;
                  },
                ),
              ] else ...[
                DropdownButtonFormField<AvoidanceTargetType>(
                  value: _targetType,
                  decoration: const InputDecoration(
                    labelText: 'Limit type',
                    border: OutlineInputBorder(),
                  ),
                  items: AvoidanceTargetType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_label(type.name)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _targetType = value);
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _targetType == AvoidanceTargetType.timeLimit
                        ? 'Time limit'
                        : 'Quantity limit',
                    helperText: 'Enter a value greater than zero.',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final number = double.tryParse(value ?? '');
                    if (number == null || !number.isFinite || number <= 0) {
                      return 'Enter a valid number greater than zero.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _saving
                      ? const CircularProgressIndicator()
                      : Text(_editing ? 'Save Changes' : 'Create Habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
