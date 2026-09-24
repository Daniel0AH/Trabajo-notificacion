import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';
import '../utils/reminder_schedule.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!_supported) return;
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
    if (!_supported) return;
    await cancel(reminder);
    final first = nextOccurrenceAfter(reminder, DateTime.now());
    if (first == null) return;
    var next = first;
    final usedIds = (await _plugin.pendingNotificationRequests())
        .map((notification) => notification.id)
        .toSet();
    var notificationId = (reminder.id ?? reminder.hashCode).abs() % 0x80000000;
    for (var occurrence = 0; occurrence < 60; occurrence++) {
      // Keep IDs within Android's 32-bit range without replacing another alarm.
      while (usedIds.contains(notificationId)) {
        notificationId = (notificationId + 1) % 0x80000000;
      }
      await _plugin.zonedSchedule(
        notificationId,
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
        payload: _payload(reminder),
      );
      usedIds.add(notificationId);
      next = next.add(reminder.reminderInterval);
    }
  }

  Future<void> cancel(Reminder reminder) async {
    if (!_supported) return;
    final pending = await _plugin.pendingNotificationRequests();
    final legacyBase = (reminder.id ?? reminder.hashCode).abs() * 1000;
    for (final notification in pending) {
      final isLegacy =
          notification.payload == null &&
          notification.id >= legacyBase &&
          notification.id < legacyBase + 60;
      if (notification.payload == _payload(reminder) || isLegacy) {
        await _plugin.cancel(notification.id);
      }
    }
  }

  String _payload(Reminder reminder) =>
      'reminder:${reminder.id ?? reminder.hashCode}';
}
