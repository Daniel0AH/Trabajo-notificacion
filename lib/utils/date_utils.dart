import 'package:intl/intl.dart';

String formatReminderDate(DateTime value) {
  final today = DateTime.now();
  final date = DateTime(value.year, value.month, value.day);
  final current = DateTime(today.year, today.month, today.day);
  if (date == current) return 'Hoy';
  if (date == DateTime(today.year, today.month, today.day + 1)) return 'Mañana';
  return DateFormat('d MMM', 'es').format(value);
}

String formatReminderTime(DateTime value) => DateFormat('HH:mm').format(value);

String formatInterval(Duration interval) {
  final parts = <String>[];
  final days = interval.inDays;
  final hours = interval.inHours % 24;
  final minutes = interval.inMinutes % 60;
  if (days > 0) parts.add('$days ${days == 1 ? 'día' : 'días'}');
  if (hours > 0) parts.add('$hours ${hours == 1 ? 'hora' : 'horas'}');
  if (minutes > 0) {
    parts.add('$minutes ${minutes == 1 ? 'minuto' : 'minutos'}');
  }
  return 'Cada ${parts.join(' ')}';
}
