class Reminder {
  Reminder({
    this.id,
    required this.title,
    this.description = '',
    required this.dateTime,
    required this.reminderInterval,
    this.completed = false,
  });

  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final Duration reminderInterval;
  final bool completed;

  Reminder copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dateTime,
    Duration? reminderInterval,
    bool? completed,
  }) => Reminder(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    dateTime: dateTime ?? this.dateTime,
    reminderInterval: reminderInterval ?? this.reminderInterval,
    completed: completed ?? this.completed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dateTime': dateTime.toIso8601String(),
    'intervalMinutes': reminderInterval.inMinutes,
    'completed': completed,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as int?,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    dateTime: DateTime.parse(json['dateTime'] as String),
    reminderInterval: Duration(minutes: json['intervalMinutes'] as int? ?? 240),
    completed: json['completed'] as bool? ?? false,
  );
}
