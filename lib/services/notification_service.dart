import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> schedule(Reminder reminder) async {
    await cancel(reminder);
    var next = reminder.dateTime;
    final now = DateTime.now();
    if (next.isBefore(now)) {
      final elapsed = now.difference(next).inMinutes;
      final steps = (elapsed / reminder.reminderInterval.inMinutes).ceil();
      next = next.add(reminder.reminderInterval * steps);
    }
    final baseId = (reminder.id ?? reminder.hashCode).abs() * 1000;
    for (var occurrence = 0; occurrence < 60; occurrence++) {
      if (!next.isAfter(now)) break;
      await _plugin.zonedSchedule(
        baseId + occurrence,
        reminder.title,
        reminder.description.isEmpty
            ? 'Tienes un recordatorio pendiente'
            : reminder.description,
        tz.TZDateTime.from(next, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders',
            'Recordatorios',
            channelDescription: 'Notificaciones de recordatorios',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      next = next.add(reminder.reminderInterval);
    }
  }

  Future<void> cancel(Reminder reminder) async {
    final baseId = (reminder.id ?? reminder.hashCode).abs() * 1000;
    for (var occurrence = 0; occurrence < 60; occurrence++) {
      await _plugin.cancel(baseId + occurrence);
    }
  }
}
