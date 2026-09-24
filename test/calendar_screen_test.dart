import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:waiwareminders/models/reminder.dart';
import 'package:waiwareminders/screens/calendar_screen.dart';

/// Inicializa la localización en español y ejecuta las pruebas del calendario.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  /// Comprueba que avanzar al mes siguiente también actualice el día seleccionado
  /// y que el botón «Hoy» vuelva a seleccionar la fecha actual.
  testWidgets('el mes y el día seleccionado avanzan juntos y Hoy regresa', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarScreen(reminders: const [], onReminderTap: (_) {}),
        ),
      ),
    );
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    await tester.tap(find.byKey(ValueKey(lastDay)));
    await tester.pump();
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pump();
    final nextMonth = DateTime(now.year, now.month + 1);
    final nextDay = DateTime(
      now.year,
      now.month + 1,
      lastDay.day.clamp(1, DateTime(now.year, now.month + 2, 0).day),
    );
    expect(
      find.text(DateFormat('MMMM yyyy', 'es').format(nextMonth)),
      findsOneWidget,
    );
    expect(
      find.text(DateFormat('EEEE d MMMM', 'es').format(nextDay)),
      findsOneWidget,
    );
    await tester.tap(find.text('Hoy'));
    await tester.pump();
    expect(
      find.text(DateFormat('EEEE d MMMM', 'es').format(now)),
      findsOneWidget,
    );
  });

  /// Comprueba que se muestren las horas de una alarma recurrente y que,
  /// al seleccionar una de ellas, se devuelva la alarma original.
  testWidgets('muestra horas recurrentes y abre la alarma original', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final alarm = Reminder(
      id: 9,
      title: 'Repetición',
      dateTime: DateTime(now.year, now.month, now.day - 1),
      reminderInterval: const Duration(hours: 8),
    );
    Reminder? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarScreen(
            reminders: [alarm],
            onReminderTap: (value) => tapped = value,
          ),
        ),
      ),
    );
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('16:00'), findsOneWidget);
    await tester.tap(find.text('08:00'));
    expect(tapped, same(alarm));
    expect(find.bySemanticsLabel(RegExp('con alarmas')), findsWidgets);
  });

  /// Comprueba que una alarma con intervalo de un minuto cree solo las filas
  /// visibles y que su título aparezca al desplazarse por la lista.
  testWidgets('una alarma por minuto construye solo las filas visibles', (
    tester,
  ) async {
    final now = DateTime.now();
    final alarm = Reminder(
      title: 'Cada minuto',
      dateTime: DateTime(now.year, now.month, now.day),
      reminderInterval: const Duration(minutes: 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarScreen(reminders: [alarm], onReminderTap: (_) {}),
        ),
      ),
    );
    expect(find.byType(ListTile).evaluate().length, lessThan(30));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Cada minuto'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}