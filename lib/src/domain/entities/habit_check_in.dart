class HabitCheckIn {
  final String id;
  final String habitId;
  final String userId;

  /// Execution: minutes completed.
  /// Avoidance: actual daily minutes or quantity consumed.
  final double actualValue;

  /// The local calendar date for which this check-in applies.
  /// The application layer should normalize this to a date-only value.
  final DateTime occurredAt;

  const HabitCheckIn({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.actualValue,
    required this.occurredAt,
  });
}
