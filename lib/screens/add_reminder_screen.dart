import 'package:flutter/material.dart';

import '../models/reminder.dart';
import '../widgets/reminder_form.dart';

class AddReminderScreen extends StatelessWidget {
  const AddReminderScreen({super.key, this.initial});

  final Reminder? initial;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        initial == null ? 'Nuevo recordatorio' : 'Editar recordatorio',
      ),
    ),
    body: ReminderForm(
      initial: initial,
      onSave: (reminder) => Navigator.pop(context, reminder),
    ),
  );
}
