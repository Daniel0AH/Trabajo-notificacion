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
  late Duration _interval;
  bool _custom = false;
  final _customController = TextEditingController(text: '3');

  static const _presets = [2, 4, 6, 12, 24];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title);
    _descriptionController = TextEditingController(text: initial?.description);
    _dateTime =
        initial?.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    _interval = initial?.reminderInterval ?? const Duration(hours: 4);
    _custom = !_presets.contains(_interval.inHours);
    if (_custom) _customController.text = '${_interval.inHours}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null)
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (picked != null)
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final hours = _custom
        ? int.tryParse(_customController.text) ?? 0
        : _interval.inHours;
    if (hours <= 0) return;
    widget.onSave(
      Reminder(
        id: widget.initial?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: _dateTime,
        reminderInterval: Duration(hours: hours),
        completed: widget.initial?.completed ?? false,
      ),
    );
  }

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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._presets.map(
              (hours) => ChoiceChip(
                label: Text('$hours h'),
                selected: !_custom && _interval.inHours == hours,
                onSelected: (_) => setState(() {
                  _custom = false;
                  _interval = Duration(hours: hours);
                }),
              ),
            ),
            ChoiceChip(
              label: const Text('Personalizado'),
              selected: _custom,
              onSelected: (_) => setState(() => _custom = true),
            ),
          ],
        ),
        if (_custom) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Horas',
              suffixText: 'h',
            ),
            validator: (value) => int.tryParse(value ?? '') == null
                ? 'Introduce un número'
                : null,
          ),
        ],
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
