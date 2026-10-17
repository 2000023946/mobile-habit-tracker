
/// Returns the calendar date at midnight.
///
/// Preserves the DateTime's local/UTC mode.
DateTime calendarDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Returns whether two DateTime values fall on the same calendar date.
///
/// This compares year, month, and day rather than the time of day.
bool isSameCalendarDate(DateTime a, DateTime b) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}
