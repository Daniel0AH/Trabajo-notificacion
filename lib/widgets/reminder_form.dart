import 'package:flutter/material.dart';

import '../models/reminder.dart';
import '../utils/date_utils.dart';

class ReminderForm extends StatefulWidget {
  const ReminderForm({super.key, this.initial, required this.onSave});

  final Reminder? initial;
  final ValueChanged<Reminder> onSave;

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _dateTime;
  late final TextEditingController _daysController;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title);
    _descriptionController = TextEditingController(text: initial?.description);
    final date =
        initial?.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    _dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
    );
    final interval = initial?.reminderInterval ?? const Duration(hours: 4);
    _daysController = TextEditingController(text: '${interval.inDays}');
    _hoursController = TextEditingController(text: '${interval.inHours % 24}');
    _minutesController = TextEditingController(
      text: '${interval.inMinutes % 60}',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: _dateTime.isBefore(DateTime.now())
          ? _dateTime
          : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) {
      setState(
        () => _dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dateTime.hour,
          _dateTime.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (picked != null && mounted) {
      setState(
        () => _dateTime = DateTime(
          _dateTime.year,
          _dateTime.month,
          _dateTime.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      Reminder(
        id: widget.initial?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: _dateTime,
        reminderInterval: Duration(
          days: _number(_daysController.text),
          hours: _number(_hoursController.text),
          minutes: _number(_minutesController.text),
        ),
        completed: widget.initial?.completed ?? false,
      ),
    );
  }

  int _number(String value) => int.tryParse(value.trim()) ?? 0;

  String? _validateInterval(String? value) {
    final text = value?.trim() ?? '';
    if (text.isNotEmpty &&
        (!RegExp(r'^\d+$').hasMatch(text) || int.tryParse(text) == null)) {
      return 'Usa un entero positivo o 0';
    }
    final values = [
      _number(_daysController.text),
      _number(_hoursController.text),
      _number(_minutesController.text),
    ];
    if (values.every((value) => value == 0)) {
      return 'Indica al menos 1 minuto';
    }
    // Keep all 60 scheduled occurrences within DateTime's supported range.
    final maxMinutes =
        (8640000000000000 - _dateTime.millisecondsSinceEpoch) ~/ 60000 ~/ 60;
    if (values.any((value) => value > maxMinutes) ||
        values[0] * 1440 + values[1] * 60 + values[2] > maxMinutes) {
      return 'Frecuencia fuera del rango admitido';
    }
    return null;
  }

  Widget _intervalField(String label, TextEditingController controller) =>
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, errorMaxLines: 3),
        validator: _validateInterval,
      );

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextFormField(
          controller: _titleController,
          autofocus: widget.initial == null,
          decoration: const InputDecoration(
            labelText: 'Título',
            hintText: '¿Qué necesitas recordar?',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Escribe un título'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: 'Añade algún detalle (opcional)',
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Cuándo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(formatReminderDate(_dateTime)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(formatReminderTime(_dateTime)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Recordar cada',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _intervalField('Días', _daysController)),
            const SizedBox(width: 10),
            Expanded(child: _intervalField('Horas', _hoursController)),
            const SizedBox(width: 10),
            Expanded(child: _intervalField('Minutos', _minutesController)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Combina días, horas y minutos. Mínimo: 1 minuto.'),
        const SizedBox(height: 30),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.initial == null ? 'Guardar recordatorio' : 'Guardar cambios',
          ),
        ),
      ],
    ),
  );
}
