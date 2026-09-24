import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:waiwareminders/models/reminder.dart';
import 'package:waiwareminders/services/notification_service.dart';

/// Configura los dobles del canal de notificaciones y ejecuta las pruebas
/// del servicio de notificaciones.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  final pending = <int, Map<String, dynamic>>{};

  /// Prepara la plataforma Android, instala el manejador simulado del canal
  /// y espera a que el servicio de notificaciones se inicialice.
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    pending.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'pendingNotificationRequests') {
            return pending.values.toList();
          }
          if (call.method == 'zonedSchedule') {
            final args = Map<String, dynamic>.from(call.arguments as Map);
            pending[args['id'] as int] = args;
          }
          if (call.method == 'cancel') pending.remove(call.arguments['id']);
          if (call.method == 'initialize' ||
              call.method == 'requestNotificationsPermission') {
            return true;
          }
          return null;
        });
    await NotificationService().initialize();
    calls.clear();
  });

  /// Restablece la plataforma y elimina el manejador simulado al terminar
  /// cada prueba.
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// Verifica que una alarma programe 60 avisos separados por un minuto,
  /// con identificadores válidos, y que se puedan cancelar todos.
  test('programa 60 avisos separados por un minuto con IDs válidos', () async {
    final now = DateTime.now();
    final alarm = Reminder(
      id: now.millisecondsSinceEpoch,
      title: 'Alarma',
      dateTime: now.add(const Duration(minutes: 2)),
      reminderInterval: const Duration(minutes: 1),
    );
    await NotificationService().schedule(alarm);
    final scheduled = calls
        .where((call) => call.method == 'zonedSchedule')
        .toList();
    expect(scheduled, hasLength(60));
    final dates = scheduled
        .map(
          (call) =>
              DateTime.parse(call.arguments['scheduledDateTime'] as String),
        )
        .toList();
    for (var index = 1; index < dates.length; index++) {
      expect(
        dates[index].difference(dates[index - 1]),
        const Duration(minutes: 1),
      );
    }
    final ids = scheduled.map((call) => call.arguments['id'] as int).toSet();
    expect(ids, hasLength(60));
    expect(ids.every((id) => id >= 0 && id <= 0x7fffffff), isTrue);
    calls.clear();
    await NotificationService().cancel(alarm);
    expect(
      calls
          .where((call) => call.method == 'cancel')
          .map((call) => call.arguments['id']),
      unorderedEquals(ids),
    );
  });

  /// Comprueba que completar una alarma cancele sus avisos pendientes
  /// y no programe nuevas repeticiones.
  test(
    'completar una alarma cancela y no programa nuevas repeticiones',
    () async {
      final alarm = Reminder(
        id: 1,
        title: 'Lista',
        dateTime: DateTime.now().add(const Duration(minutes: 2)),
        reminderInterval: const Duration(minutes: 1),
      );
      await NotificationService().schedule(alarm);
      calls.clear();
      await NotificationService().schedule(alarm.copyWith(completed: true));
      expect(calls.where((call) => call.method == 'cancel'), hasLength(60));
      expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
    },
  );

  /// Comprueba que dos alarmas con identificadores cercanos mantengan
  /// sus avisos separados y que cancelar una no afecte a la otra.
  test(
    'dos alarmas con IDs cercanos no reemplazan ni cancelan sus avisos',
    () async {
      final first = Reminder(
        id: 0x7fffffff,
        title: 'Primera',
        dateTime: DateTime.now().add(const Duration(minutes: 2)),
        reminderInterval: const Duration(minutes: 1),
      );
      final second = first.copyWith(id: 0, title: 'Segunda');
      await NotificationService().schedule(first);
      await NotificationService().schedule(second);
      expect(pending.length, 120);
      await NotificationService().cancel(first);
      expect(pending.length, 60);
      expect(
        pending.values.every((request) => request['title'] == 'Segunda'),
        isTrue,
      );
    },
  );
}