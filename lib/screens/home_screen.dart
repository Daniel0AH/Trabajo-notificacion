import 'package:flutter/material.dart';

import '../models/reminder.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/reminder_card.dart';
import 'add_reminder_screen.dart';
import 'calendar_screen.dart';
import 'reminder_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _notifications = NotificationService();
  List<Reminder> _reminders = [];
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reminders = await _storage.loadReminders();
    if (!mounted) return;
    setState(() => _reminders = reminders);
    for (final reminder in reminders.where((reminder) => !reminder.completed)) {
      await _notifications.schedule(reminder);
    }
  }

  Future<void> _save(List<Reminder> reminders) async {
    setState(() => _reminders = reminders);
    await _storage.saveReminders(reminders);
  }

  Future<void> _openEditor([Reminder? reminder]) async {
    final result = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(builder: (_) => AddReminderScreen(initial: reminder)),
    );
    if (result == null || !mounted) return;
    final saved = result.id == null
        ? result.copyWith(id: DateTime.now().millisecondsSinceEpoch)
        : result;
    final reminders = [
      ..._reminders.where((item) => item.id != saved.id),
      saved,
    ]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _save(reminders);
    if (!saved.completed) await _notifications.schedule(saved);
  }

  Future<void> _toggle(Reminder reminder, bool completed) async {
    final updated = reminder.copyWith(completed: completed);
    await _save(
      _reminders
          .map((item) => item.id == reminder.id ? updated : item)
          .toList(),
    );
    if (completed) {
      await _notifications.cancel(updated);
    } else {
      await _notifications.schedule(updated);
    }
  }

  Future<void> _delete(Reminder reminder) async {
    await _notifications.cancel(reminder);
    await _save(_reminders.where((item) => item.id != reminder.id).toList());
  }

  Future<void> _openDetail(Reminder reminder) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReminderDetailScreen(
          reminder: reminder,
          onEdit: () {
            Navigator.pop(context);
            _openEditor(
              _reminders.firstWhere((item) => item.id == reminder.id),
            );
          },
          onDelete: () => _delete(reminder),
          onToggle: (value) => _toggle(reminder, value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = [..._reminders.where((reminder) => !reminder.completed)]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Mis recordatorios' : 'Calendario'),
      ),
      body: _tab == 1
          ? CalendarScreen(reminders: _reminders, onReminderTap: _openDetail)
          : active.isEmpty
          ? EmptyState(onAdd: () => _openEditor())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
              children: [
                const Text(
                  'PRÓXIMOS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear recordatorio'),
                  ),
                ),
                const SizedBox(height: 12),
                ...active.map(
                  (reminder) => ReminderCard(
                    reminder: reminder,
                    onToggle: (value) => _toggle(reminder, value),
                    onTap: () => _openDetail(reminder),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
        ],
      ),
    );
  }
}
