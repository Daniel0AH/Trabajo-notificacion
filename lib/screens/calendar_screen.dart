import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reminder.dart';
import '../utils/date_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.reminders,
    required this.onReminderTap,
  });
  final List<Reminder> reminders;
  final ValueChanged<Reminder> onReminderTap;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _selected = DateTime.now();
  }

  List<Reminder> get _selectedReminders =>
      widget.reminders
          .where(
            (reminder) =>
                reminder.dateTime.year == _selected.year &&
                reminder.dateTime.month == _selected.month &&
                reminder.dateTime.day == _selected.day,
          )
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = (firstDay.weekday - 1);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              DateFormat('MMMM yyyy', 'es').format(_month),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offset + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox();
            final day = index - offset + 1;
            final date = DateTime(_month.year, _month.month, day);
            final selected =
                date.year == _selected.year &&
                date.month == _selected.month &&
                date.day == _selected.day;
            final hasReminder = widget.reminders.any(
              (r) =>
                  r.dateTime.year == date.year &&
                  r.dateTime.month == date.month &&
                  r.dateTime.day == date.day,
            );
            return GestureDetector(
              onTap: () => setState(() => _selected = date),
              child: Container(
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight: selected ? FontWeight.bold : null,
                      ),
                    ),
                    if (hasReminder)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          DateFormat('EEEE d MMMM', 'es').format(_selected),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_selectedReminders.isEmpty)
          const Text('No hay recordatorios para este día.')
        else
          ..._selectedReminders.map(
            (reminder) => ListTile(
              onTap: () => widget.onReminderTap(reminder),
              contentPadding: EdgeInsets.zero,
              leading: Text(
                formatReminderTime(reminder.dateTime),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              title: Text(reminder.title),
              trailing: Icon(
                reminder.completed ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
              ),
            ),
          ),
      ],
    );
  }
}
