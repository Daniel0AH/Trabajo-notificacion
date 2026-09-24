import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waiwareminders/app/app.dart';
import 'package:waiwareminders/models/reminder.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('muestra el estado inicial de recordatorios', (tester) async {
    await tester.pumpWidget(const ReminderApp());
    await tester.pumpAndSettle();

    expect(find.text('Mis recordatorios'), findsOneWidget);
    expect(find.text('Tu día está despejado'), findsOneWidget);
    expect(find.text('Crear recordatorio'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('crear, editar, completar y eliminar actualiza el calendario', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final alarm = Reminder(
      id: 1,
      title: 'Alarma diaria',
      dateTime: DateTime(now.year, now.month, now.day - 1, 8),
      reminderInterval: const Duration(days: 1),
    );
    SharedPreferences.setMockInitialValues({
      'reminders': [jsonEncode(alarm.toJson())],
    });
    await tester.pumpWidget(const ReminderApp());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add), findsOneWidget);

    // The central action remains available after the first reminder.
    await tester.tap(find.text('Crear recordatorio'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Nueva alarma',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Horas'), '0');
    await tester.enterText(find.widgetWithText(TextFormField, 'Minutos'), '1');
    await tester.ensureVisible(find.text('Guardar recordatorio'));
    await tester.tap(find.text('Guardar recordatorio'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva alarma'), findsOneWidget);
    expect(find.text('Cada 1 minuto'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.text('Calendario'));
    await tester.pumpAndSettle();
    // A reminder that started yesterday appears at today's occurrence.
    await tester.ensureVisible(find.text('Alarma diaria'));
    await tester.tap(find.text('Alarma diaria'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Alarma editada',
    );
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('Alarma diaria'), findsNothing);
    expect(find.text('Alarma editada'), findsOneWidget);

    await tester.tap(find.text('Alarma editada'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    // Editing after completion must preserve the current completion state.
    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('Alarma editada'), findsNothing);

    // Remove the new alarm using the shared state and check the calendar.
    await tester.tap(find.text('Tareas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva alarma'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendario'));
    await tester.pumpAndSettle();
    expect(find.text('No hay recordatorios para este día.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
