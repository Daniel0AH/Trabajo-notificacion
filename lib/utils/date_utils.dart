import 'package:intl/intl.dart';

String formatReminderDate(DateTime value) {
  final today = DateTime.now();
  final date = DateTime(value.year, value.month, value.day);
  final current = DateTime(today.year, today.month, today.day);
  if (date == current) return 'Hoy';
  if (date == current.add(const Duration(days: 1))) return 'Mañana';
  return DateFormat('d MMM', 'es').format(value);
}

String formatReminderTime(DateTime value) => DateFormat('HH:mm').format(value);

String formatInterval(Duration interval) {
  if (interval.inHours >= 24 && interval.inHours % 24 == 0) {
    return 'Cada ${interval.inHours ~/ 24} ${interval.inHours ~/ 24 == 1 ? 'día' : 'días'}';
  }
  return 'Cada ${interval.inHours} horas';
}
