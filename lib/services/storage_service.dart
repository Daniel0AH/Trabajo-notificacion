import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder.dart';

class StorageService {
  static const _key = 'reminders';

  Future<List<Reminder>> loadReminders() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_key) ?? [];
    return values
        .map(
          (value) =>
              Reminder.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key,
      reminders.map((reminder) => jsonEncode(reminder.toJson())).toList(),
    );
  }
}
