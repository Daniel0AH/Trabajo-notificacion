import 'package:flutter_test/flutter_test.dart';
import 'package:waiwareminders/models/reminder.dart';
import 'package:waiwareminders/utils/date_utils.dart';
import 'package:waiwareminders/utils/reminder_schedule.dart';

/// Ejecuta las pruebas de cálculo y presentación de las recurrencias.
void main() {
  /// Crea un recordatorio con la fecha de inicio y el intervalo indicados.
  Reminder reminder(DateTime start, Duration interval) =>
      Reminder(title: 'Alarma', dateTime: start, reminderInterval: interval);

  /// Comprueba que las ocurrencias de un intervalo de un minuto crucen
  /// correctamente la medianoche y respeten los límites del día consultado.
  test('un minuto cruza medianoche y respeta los límites del día', () {
    final alarm = reminder(
      DateTime(2026, 1, 31, 23, 59),
      const Duration(minutes: 1),
    );
    final dates = occurrencesBetween(
      alarm,
      DateTime(2026, 2, 1),
      DateTime(2026, 2, 2),
    ).toList();
    expect(dates.length, 1440);
    expect(dates.first, DateTime(2026, 2, 1));
    expect(dates.last, DateTime(2026, 2, 1, 23, 59));
  });

  /// Comprueba que la siguiente ocurrencia sea posterior al momento actual,
  /// incluso cuando este coincide exactamente con una alarma.
  test('la siguiente alarma siempre queda después de ahora', () {
    final alarm = reminder(
      DateTime(2026, 1, 1, 10),
      const Duration(minutes: 1),
    );
    expect(
      nextOccurrenceAfter(alarm, DateTime(2026, 1, 1, 10)),
      DateTime(2026, 1, 1, 10, 1),
    );
    expect(
      nextOccurrenceAfter(alarm, DateTime(2026, 1, 1, 10, 1, 30)),
      DateTime(2026, 1, 1, 10, 2),
    );
    expect(
      nextOccurrenceAfter(alarm, DateTime(2026, 1, 1, 10, 2)),
      DateTime(2026, 1, 1, 10, 3),
    );
  });

  /// Comprueba que un intervalo combinado conserve su frecuencia al pasar
  /// de un año a otro y al consultar un rango sin ocurrencias.
  test('un intervalo combinado mantiene su frecuencia entre años', () {
    final alarm = reminder(
      DateTime(2025, 12, 31, 23),
      const Duration(days: 1, hours: 1, minutes: 30),
    );
    expect(
      firstOccurrenceOnOrAfter(alarm, DateTime(2026, 1, 1)),
      DateTime(2026, 1, 2, 0, 30),
    );
    expect(
      occurrencesBetween(alarm, DateTime(2025, 1, 1), DateTime(2025, 1, 2)),
      isEmpty,
    );
  });

  /// Comprueba que se incluya el 29 de febrero y que el cálculo pueda avanzar
  /// directamente desde una fecha de inicio antigua.
  test(
    'incluye el 29 de febrero y salta directamente desde fechas antiguas',
    () {
      final alarm = reminder(DateTime(2000), const Duration(days: 1));
      expect(
        firstOccurrenceOnOrAfter(alarm, DateTime(2028, 2, 29)),
        DateTime(2028, 2, 29),
      );
    },
  );

  /// Comprueba que los recordatorios completados o con intervalos inválidos
  /// no produzcan ocurrencias.
  test('no genera alarmas completadas ni frecuencias inválidas', () {
    for (final interval in [
      Duration.zero,
      const Duration(minutes: -1),
      const Duration(seconds: 30),
    ]) {
      expect(
        nextOccurrenceAfter(reminder(DateTime(2026), interval), DateTime(2026)),
        isNull,
      );
    }
    final completed = reminder(
      DateTime(2026),
      const Duration(minutes: 1),
    ).copyWith(completed: true);
    expect(
      occurrencesBetween(completed, DateTime(2026), DateTime(2026, 1, 2)),
      isEmpty,
    );
  });

  /// Comprueba que los intervalos se presenten en minutos, horas y días
  /// sin descartar los minutos de combinaciones.
  test('presenta minutos y combinaciones sin truncarlos a horas', () {
    expect(formatInterval(const Duration(minutes: 1)), 'Cada 1 minuto');
    expect(formatInterval(const Duration(hours: 1)), 'Cada 1 hora');
    expect(
      formatInterval(const Duration(minutes: 90)),
      'Cada 1 hora 30 minutos',
    );
    expect(
      formatInterval(const Duration(days: 2, hours: 3, minutes: 4)),
      'Cada 2 días 3 horas 4 minutos',
    );
  });
}