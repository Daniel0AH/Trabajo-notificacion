import 'package:flutter/material.dart';

import '../models/reminder.dart';
import '../utils/date_utils.dart';

class ReminderDetailScreen extends StatelessWidget {
  const ReminderDetailScreen({
    super.key,
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Editar',
        ),
        IconButton(
          onPressed: () {
            onDelete();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Eliminar',
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          reminder.title,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (reminder.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            reminder.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: 28),
        _DetailRow(
          icon: Icons.event_outlined,
          label: 'Fecha',
          value:
              '${formatReminderDate(reminder.dateTime)} · ${formatReminderTime(reminder.dateTime)}',
        ),
        _DetailRow(
          icon: Icons.autorenew,
          label: 'Frecuencia',
          value: formatInterval(reminder.reminderInterval),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Completado'),
          value: reminder.completed,
          onChanged: onToggle,
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label, style: Theme.of(context).textTheme.labelLarge),
    subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
  );
}
