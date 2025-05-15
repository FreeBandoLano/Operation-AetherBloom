import 'package:flutter/material.dart';

enum DosageUnit {
  pill,
  ml,
  mg,
  puff,
  drop,
  unit,
}

enum MedicationFrequency {
  daily,
  weekly,
  asNeeded,
  custom,
}

class Medication {
  final String id;
  final String name;
  final String description;
  final double dosage;
  final String unit;
  final int currentQuantity;
  final int refillThreshold;
  final MedicationFrequency frequency;
  final List<TimeOfDay> scheduledTimes;
  final List<bool> weekdays;
  final DateTime lastRefillDate;
  final int refillAmount;
  final Map<DateTime, bool> adherenceLog;
  final Color color;

  const Medication({
    required this.id,
    required this.name,
    required this.description,
    required this.dosage,
    required this.unit,
    required this.currentQuantity,
    required this.refillThreshold,
    required this.frequency,
    required this.scheduledTimes,
    required this.weekdays,
    required this.lastRefillDate,
    required this.refillAmount,
    required this.adherenceLog,
    required this.color,
  });

  bool get needsRefill => currentQuantity <= refillThreshold;

  double get adherenceRate {
    if (adherenceLog.isEmpty) return 0.0;
    final takenCount = adherenceLog.values.where((taken) => taken).length;
    return takenCount / adherenceLog.length;
  }

  int get daysUntilRefillNeeded {
    if (frequency == MedicationFrequency.asNeeded) return -1;
    
    final dailyDoses = scheduledTimes.length;
    final activeDaysPerWeek = weekdays.where((day) => day).length;
    final dosesPerWeek = dailyDoses * activeDaysPerWeek;
    final remainingDoses = currentQuantity - refillThreshold;
    
    return (remainingDoses / (dosesPerWeek / 7)).floor();
  }

  Medication copyWith({
    String? id,
    String? name,
    String? description,
    double? dosage,
    String? unit,
    int? currentQuantity,
    int? refillThreshold,
    MedicationFrequency? frequency,
    List<TimeOfDay>? scheduledTimes,
    List<bool>? weekdays,
    DateTime? lastRefillDate,
    int? refillAmount,
    Map<DateTime, bool>? adherenceLog,
    Color? color,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      frequency: frequency ?? this.frequency,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      weekdays: weekdays ?? this.weekdays,
      lastRefillDate: lastRefillDate ?? this.lastRefillDate,
      refillAmount: refillAmount ?? this.refillAmount,
      adherenceLog: adherenceLog ?? this.adherenceLog,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dosage': dosage,
      'unit': unit,
      'currentQuantity': currentQuantity,
      'refillThreshold': refillThreshold,
      'frequency': frequency.toString(),
      'scheduledTimes': scheduledTimes
          .map((time) => {'hour': time.hour, 'minute': time.minute})
          .toList(),
      'weekdays': weekdays,
      'lastRefillDate': lastRefillDate.toIso8601String(),
      'refillAmount': refillAmount,
      'adherenceLog': adherenceLog.map(
        (key, value) => MapEntry(key.toIso8601String(), value),
      ),
      'color': color.value,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      dosage: json['dosage'] as double,
      unit: json['unit'] as String,
      currentQuantity: json['currentQuantity'] as int,
      refillThreshold: json['refillThreshold'] as int,
      frequency: MedicationFrequency.values.firstWhere(
        (e) => e.toString() == json['frequency'],
      ),
      scheduledTimes: (json['scheduledTimes'] as List)
          .map((time) => TimeOfDay(
                hour: time['hour'] as int,
                minute: time['minute'] as int,
              ))
          .toList(),
      weekdays: (json['weekdays'] as List).cast<bool>(),
      lastRefillDate: DateTime.parse(json['lastRefillDate'] as String),
      refillAmount: json['refillAmount'] as int,
      adherenceLog: (json['adherenceLog'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(DateTime.parse(key), value as bool),
      ),
      color: Color(json['color'] as int),
    );
  }

  String get dosageText => '$dosage $unit';

  bool get isScheduledForToday {
    final today = DateTime.now().weekday - 1;
    return weekdays[today];
  }

  bool isScheduledForDate(DateTime date) {
    final weekday = date.weekday - 1;
    return weekdays[weekday];
  }

  double getAdherenceRate({DateTime? start, DateTime? end}) {
    final filteredLog = adherenceLog.entries.where((entry) {
      if (start != null && entry.key.isBefore(start)) return false;
      if (end != null && entry.key.isAfter(end)) return false;
      return true;
    });

    if (filteredLog.isEmpty) return 0.0;

    final takenCount = filteredLog.where((entry) => entry.value).length;
    return takenCount / filteredLog.length;
  }

  String get frequencyText {
    switch (frequency) {
      case MedicationFrequency.daily:
        return 'Daily';
      case MedicationFrequency.weekly:
        return 'Weekly';
      case MedicationFrequency.asNeeded:
        return 'As needed';
      case MedicationFrequency.custom:
        return 'Custom schedule';
    }
  }

  String get nextDoseTime {
    if (scheduledTimes.isEmpty) return 'No scheduled doses';
    
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    // Find the next scheduled time today
    for (final time in scheduledTimes) {
      final scheduleMinutes = time.hour * 60 + time.minute;
      if (scheduleMinutes > currentMinutes) {
        return 'Today at ${_formatTime(time)}';
      }
    }
    
    // If no more doses today, return the first dose tomorrow
    return 'Tomorrow at ${_formatTime(scheduledTimes.first)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
} 