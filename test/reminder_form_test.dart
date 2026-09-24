import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:waiwareminders/models/reminder.dart';
import 'package:waiwareminders/widgets/reminder_form.dart';

/// Inicializa la localización en español y ejecuta las pruebas del formulario.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  /// Busca un campo de formulario identificado por su etiqueta.
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  /// Hace visible y selecciona el botón indicado para guardar el formulario.
  Future<void> save(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// Comprueba que se pueda crear una alarma con un intervalo de un minuto
  /// sin seleccionar opciones prefijadas.
  testWidgets('crea una alarma de un minuto sin opciones prefijadas', (
    tester,
  ) async {
    Reminder? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReminderForm(onSave: (value) => saved = value)),
      ),
    );
    await tester.enterText(field('Título'), 'Tomar agua');
    await tester.enterText(field('Horas'), '0');
    await tester.enterText(field('Minutos'), '1');
    await save(tester, 'Guardar recordatorio');
    expect(saved?.reminderInterval, const Duration(minutes: 1));
    expect(saved?.dateTime.second, 0);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  /// Comprueba que la edición conserve el intervalo inicial y que los minutos
  /// ingresados se sumen correctamente al intervalo existente.
  testWidgets('edita una combinación conservando todos sus minutos', (
    tester,
  ) async {
    final initial = Reminder(
      id: 7,
      title: 'Revisión',
      dateTime: DateTime(2026, 9, 23, 8),
      reminderInterval: const Duration(days: 2, hours: 1, minutes: 15),
    );
    Reminder? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReminderForm(
            initial: initial,
            onSave: (value) => saved = value,
          ),
        ),
      ),
    );
    await save(tester, 'Guardar cambios');
    expect(saved?.reminderInterval, initial.reminderInterval);
    expect(saved?.id, 7);
    await tester.enterText(field('Minutos'), '90');
    await save(tester, 'Guardar cambios');
    expect(
      saved?.reminderInterval,
      const Duration(days: 2, hours: 2, minutes: 30),
    );
  });

  /// Comprueba que el formulario rechace intervalos inválidos sin generar
  /// excepciones durante el ingreso o el guardado.
  testWidgets('rechaza cero, negativos, decimales y valores fuera de rango', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReminderForm(onSave: (_) => saved = true)),
      ),
    );
    await tester.enterText(field('Título'), 'Alarma');
    await tester.enterText(field('Horas'), '0');
    for (final invalid in [
      '0',
      '',
      '-1',
      '1.5',
      'abc',
      '99999999999999999999999',
      '9223372036854775807',
    ]) {
      await tester.ensureVisible(field('Minutos'));
      await tester.enterText(field('Minutos'), invalid);
      await save(tester, 'Guardar recordatorio');
      expect(saved, isFalse, reason: 'No debe guardar "$invalid"');
      expect(tester.takeException(), isNull);
    }
  });
}