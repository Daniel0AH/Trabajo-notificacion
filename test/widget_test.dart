import 'package:flutter_test/flutter_test.dart';
import 'package:waiwareminders/app/app.dart';

void main() {
  testWidgets('muestra el estado inicial de recordatorios', (tester) async {
    await tester.pumpWidget(const ReminderApp());
    await tester.pumpAndSettle();

    expect(find.text('Mis recordatorios'), findsOneWidget);
    expect(find.text('Tu día está despejado'), findsOneWidget);
    expect(find.text('Crear recordatorio'), findsOneWidget);
  });
}
