import '../models/reminder.dart';

/// The calendar and notifications use the same fixed-duration recurrence.
DateTime? firstOccurrenceOnOrAfter(Reminder reminder, DateTime from) {
  final interval = reminder.reminderInterval.inMicroseconds;
  if (reminder.completed || interval < Duration.microsecondsPerMinute) {
    return null;
  }
  final elapsed = from.difference(reminder.dateTime).inMicroseconds;
  if (elapsed <= 0) return reminder.dateTime;
  final steps = elapsed ~/ interval + (elapsed % interval == 0 ? 0 : 1);
  return reminder.dateTime.add(reminder.reminderInterval * steps);
}

DateTime? nextOccurrenceAfter(Reminder reminder, DateTime now) =>
    firstOccurrenceOnOrAfter(
      reminder,
      now.add(const Duration(microseconds: 1)),
    );

Iterable<DateTime> occurrencesBetween(
  Reminder reminder,
  DateTime start,
  DateTime end,
) sync* {
  final first = firstOccurrenceOnOrAfter(reminder, start);
  if (first == null) return;
  var next = first;
  while (next.isBefore(end)) {
    yield next;
    next = next.add(reminder.reminderInterval);
  }
}
