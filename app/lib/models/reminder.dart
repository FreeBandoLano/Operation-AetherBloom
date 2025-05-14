import 'package:flutter/material.dart';

/// Represents a medication reminder with customizable settings
class Reminder {
  final String id;
  final String title;
  final String description;
  final TimeOfDay time;
  final List<bool> weekdays; // Index 0 is Monday, 6 is Sunday
  final ReminderPriority priority;
  final bool isEnabled;
  final String? medicationId;
  final int? dosage;
  final String? unit;
  final int? remainingDoses;
  final int? refillThreshold;
  final DateTime? lastTaken;
  final int? adherenceScore;

  const Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.weekdays,
    this.priority = ReminderPriority.normal,
    this.isEnabled = true,
    this.medicationId,
    this.dosage,
    this.unit,
    this.remainingDoses,
    this.refillThreshold,
    this.lastTaken,
    this.adherenceScore,
  });

  /// Create a Reminder from JSON data
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      time: TimeOfDay(
        hour: (json['time'] as Map<String, dynamic>)['hour'] as int,
        minute: (json['time'] as Map<String, dynamic>)['minute'] as int,
      ),
      weekdays: (json['weekdays'] as List).cast<bool>(),
      priority: ReminderPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => ReminderPriority.normal,
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
      medicationId: json['medicationId'],
      dosage: json['dosage'],
      unit: json['unit'],
      remainingDoses: json['remainingDoses'],
      refillThreshold: json['refillThreshold'],
      lastTaken: json['lastTaken'] != null 
          ? DateTime.parse(json['lastTaken'])
          : null,
      adherenceScore: json['adherenceScore'],
    );
  }

  /// Convert Reminder to JSON format for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time': {'hour': time.hour, 'minute': time.minute},
      'weekdays': weekdays,
      'priority': priority.toString(),
      'isEnabled': isEnabled,
      'medicationId': medicationId,
      'dosage': dosage,
      'unit': unit,
      'remainingDoses': remainingDoses,
      'refillThreshold': refillThreshold,
      'lastTaken': lastTaken?.toIso8601String(),
      'adherenceScore': adherenceScore,
    };
  }

  /// Create a copy of this Reminder with some fields replaced
  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    TimeOfDay? time,
    List<bool>? weekdays,
    ReminderPriority? priority,
    bool? isEnabled,
    String? medicationId,
    int? dosage,
    String? unit,
    int? remainingDoses,
    int? refillThreshold,
    DateTime? lastTaken,
    int? adherenceScore,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      weekdays: weekdays ?? List.from(this.weekdays),
      priority: priority ?? this.priority,
      isEnabled: isEnabled ?? this.isEnabled,
      medicationId: medicationId ?? this.medicationId,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      remainingDoses: remainingDoses ?? this.remainingDoses,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      lastTaken: lastTaken ?? this.lastTaken,
      adherenceScore: adherenceScore ?? this.adherenceScore,
    );
  }

  /// Get the next occurrence of this reminder
  DateTime? getNextOccurrence() {
    final now = DateTime.now();
    final currentTime = TimeOfDay.now();
    
    // Convert weekdays to DateTime weekday format (1-7, Monday-Sunday)
    final List<int> activeDays = [];
    for (int i = 0; i < weekdays.length; i++) {
      if (weekdays[i]) activeDays.add(i + 1);
    }
    
    if (activeDays.isEmpty) return null;

    // Check today first if the time hasn't passed
    if (weekdays[now.weekday - 1] && 
        (time.hour > currentTime.hour || 
         (time.hour == currentTime.hour && time.minute > currentTime.minute))) {
      return DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
    }

    // Look for the next active day
    var checkDate = now.add(const Duration(days: 1));
    for (int i = 0; i < 7; i++) {
      if (weekdays[checkDate.weekday - 1]) {
        return DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          time.hour,
          time.minute,
        );
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    return null;
  }

  /// Check if reminder should trigger on a given weekday
  bool _shouldRemindToday(int weekday) {
    // Convert from DateTime weekday (1-7, starting Monday) to our array index (0-6)
    final index = weekday - 1;
    return weekdays[index];
  }

  /// Format time as string
  String get timeString {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get weekday names where reminder is active
  List<String> get activeWeekdays {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return [
      for (int i = 0; i < weekdays.length; i++)
        if (weekdays[i]) days[i]
    ];
  }

  /// Get color based on priority
  Color get priorityColor {
    switch (priority) {
      case ReminderPriority.low:
        return Colors.green;
      case ReminderPriority.normal:
        return Colors.orange;
      case ReminderPriority.high:
        return Colors.red;
      case ReminderPriority.urgent:
        return Colors.purple;
    }
  }

  /// Get icon based on priority
  IconData get priorityIcon {
    switch (priority) {
      case ReminderPriority.low:
        return Icons.low_priority;
      case ReminderPriority.normal:
        return Icons.notifications;
      case ReminderPriority.high:
        return Icons.priority_high;
      case ReminderPriority.urgent:
        return Icons.warning_amber_rounded;
    }
  }

  bool needsRefill() {
    if (remainingDoses == null || refillThreshold == null) return false;
    return remainingDoses! <= refillThreshold!;
  }

  double getAdherencePercentage() {
    if (adherenceScore == null) return 0.0;
    // Calculate based on the last 30 days
    return (adherenceScore! / 30) * 100;
  }

  bool get isScheduledForToday {
    final today = DateTime.now().weekday - 1;
    return weekdays[today];
  }

  bool isScheduledForDate(DateTime date) {
    final weekday = date.weekday - 1;
    return weekdays[weekday];
  }

  int compareTo(Reminder other) {
    if (priority != other.priority) {
      return other.priority.index - priority.index;
    }
    final timeComparison = (time.hour * 60 + time.minute) - (other.time.hour * 60 + other.time.minute);
    if (timeComparison != 0) {
      return timeComparison;
    }
    return title.compareTo(other.title);
  }
}

/// Priority levels for reminders
enum ReminderPriority {
  low,
  normal,
  high,
  urgent,
} 