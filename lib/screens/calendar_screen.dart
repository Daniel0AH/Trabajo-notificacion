import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reminder.dart';
import '../utils/date_utils.dart';
import '../utils/reminder_schedule.dart';

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
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
      _selected = DateTime(
        _month.year,
        _month.month,
        _selected.day.clamp(1, lastDay),
      );
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  List<({Reminder reminder, DateTime dateTime})> get _selectedOccurrences {
    final end = DateTime(_selected.year, _selected.month, _selected.day + 1);
    return [
      for (final reminder in widget.reminders)
        for (final date in occurrencesBetween(reminder, _selected, end))
          (reminder: reminder, dateTime: date),
    ]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  bool _hasOccurrence(DateTime date) {
    final end = DateTime(date.year, date.month, date.day + 1);
    return widget.reminders.any((reminder) {
      final first = firstOccurrenceOnOrAfter(reminder, date);
      return first != null && first.isBefore(end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = _month.weekday - 1;
    final occurrences = _selectedOccurrences;
    final colors = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Mes anterior',
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Flexible(
                      child: Text(
                        DateFormat('MMMM yyyy', 'es').format(_month),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mes siguiente',
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: _goToToday,
                    child: const Text('Hoy'),
                  ),
                ),
                Row(
                  children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                    mainAxisExtent: 48,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemBuilder: (context, index) {
                    if (index < offset) return const SizedBox();
                    final day = index - offset + 1;
                    final date = DateTime(_month.year, _month.month, day);
                    final selected = date == _selected;
                    final hasReminder = _hasOccurrence(date);
                    final today = DateUtils.isSameDay(date, DateTime.now());
                    return Semantics(
                      label:
                          '${DateFormat('d MMMM yyyy', 'es').format(date)}'
                          '${hasReminder ? ', con alarmas' : ''}',
                      selected: selected,
                      button: true,
                      child: InkWell(
                        key: ValueKey(date),
                        onTap: () => setState(() => _selected = date),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? colors.primary
                                : Colors.transparent,
                            border: today
                                ? Border.all(color: colors.primary)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  color: selected ? colors.onPrimary : null,
                                  fontWeight: selected || today
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                              if (hasReminder)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? colors.onPrimary
                                        : colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  DateFormat('EEEE d MMMM', 'es').format(_selected),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (occurrences.isEmpty)
                  const Text('No hay recordatorios para este día.'),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.builder(
            itemCount: occurrences.length,
            itemBuilder: (context, index) {
              final occurrence = occurrences[index];
              return ListTile(
                onTap: () => widget.onReminderTap(occurrence.reminder),
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  formatReminderTime(occurrence.dateTime),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                title: Text(occurrence.reminder.title),
                trailing: const Icon(Icons.circle_outlined, size: 18),
              );
            },
          ),
        ),
      ],
    );
  }
}
