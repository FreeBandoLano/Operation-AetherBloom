/// Medication management model definitions
/// 
/// This file contains the core data structures used to represent medications,
/// including their dosage information, scheduling, and adherence tracking.
import 'package:flutter/material.dart';

/// Represents the unit of measurement for medication dosages
/// 
/// Used to properly display dosage information in a user-friendly format
/// and to ensure consistency in dosage tracking
enum DosageUnit {
  pill,
  ml,
  mg,
  puff,
  drop,
  unit,
}

/// Defines the frequency at which a medication should be taken
/// 
/// Used to determine scheduling of reminders and adherence tracking
enum MedicationFrequency {
  daily,    // Medication taken every day
  weekly,   // Medication taken on specific days of the week
  asNeeded, // PRN (pro re nata) medication taken only when needed
  custom,   // Custom schedule defined by the user
}

/// Core medication model class
/// 
/// Represents a single medication with all its properties:
/// - Basic information (name, description, dosage)
/// - Inventory tracking (current quantity, refill threshold)
/// - Scheduling information (frequency, times, weekdays)
/// - Adherence tracking (log of taken/missed doses)
/// - Visual properties (color for UI representation)
class Medication {
  final String id;               // Unique identifier
  final String name;             // Medication name
  final String description;      // Additional details/notes
  final double dosage;           // Amount to take per dose
  final String unit;             // Unit of measurement (from DosageUnit)
  final int currentQuantity;     // Current inventory count
  final int refillThreshold;     // Level at which refill is needed
  final MedicationFrequency frequency;  // How often medication is taken
  final List<TimeOfDay> scheduledTimes; // Times to take medication each day
  final List<bool> weekdays;     // Days of week (Sunday=0 to Saturday=6)
  final DateTime lastRefillDate; // Date of most recent refill
  final int refillAmount;        // Standard amount added during refill
  final Map<DateTime, bool> adherenceLog; // History of medication adherence
  final Color color;             // Color for UI representation

  /// Creates a new Medication instance with all required properties
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

  /// Determines if the medication needs to be refilled
  /// 
  /// Returns true if current quantity is at or below the refill threshold
  bool get needsRefill => currentQuantity <= refillThreshold;

  /// Calculates the adherence rate for this medication
  /// 
  /// Returns a value between 0.0 (no doses taken) and 1.0 (all doses taken)
  /// If no doses are logged yet, returns 0.0
  double get adherenceRate {
    if (adherenceLog.isEmpty) return 0.0;
    final takenCount = adherenceLog.values.where((taken) => taken).length;
    return takenCount / adherenceLog.length;
  }

  /// Estimates days until a refill will be needed
  /// 
  /// Calculation based on:
  /// - Current inventory minus refill threshold
  /// - Scheduled doses per day
  /// - Active days in the weekly schedule
  /// 
  /// Returns -1 for "as needed" medications since usage rate is unpredictable
  int get daysUntilRefillNeeded {
    if (frequency == MedicationFrequency.asNeeded) return -1;
    
    final dailyDoses = scheduledTimes.length;
    final activeDaysPerWeek = weekdays.where((day) => day).length;
    final dosesPerWeek = dailyDoses * activeDaysPerWeek;
    final remainingDoses = currentQuantity - refillThreshold;
    
    return (remainingDoses / (dosesPerWeek / 7)).floor();
  }

  /// Creates a copy of this medication with optionally updated properties
  /// 
  /// Any parameter that is null will keep the original value
  /// Useful for updating specific fields without redefining all properties
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

  /// Converts medication to a JSON-serializable Map
  /// 
  /// Used for persistent storage and API communication
  /// Handles special types like TimeOfDay, DateTime, and Color
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

  /// Creates a Medication instance from JSON data
  /// 
  /// Factory constructor that deserializes JSON data into a Medication object
  /// Handles conversion of specialized types like TimeOfDay and DateTime
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

  /// Formatted text representation of the dosage with unit
  /// 
  /// Example: "2.5 mg" or "1 pill"
  String get dosageText => '$dosage $unit';

  /// Determines if medication is scheduled for the current day of the week
  /// 
  /// Uses the weekdays list to check if current day is an active dose day
  bool get isScheduledForToday {
    final today = DateTime.now().weekday - 1;
    return weekdays[today];
  }

  /// Determines if medication is scheduled for a specific date
  /// 
  /// Used for checking schedule on any arbitrary date
  bool isScheduledForDate(DateTime date) {
    final weekday = date.weekday - 1;
    return weekdays[weekday];
  }

  /// Calculates adherence rate for a specific date range
  /// 
  /// @param start Optional start date for filtering (inclusive)
  /// @param end Optional end date for filtering (inclusive)
  /// @return Adherence rate between 0.0 and 1.0 for the specified period
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

  /// User-friendly text representation of the medication frequency
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

  /// Determines the next upcoming scheduled dose time
  /// 
  /// @return A string representation of when the next dose is due
  ///         Example: "Today at 8:00 PM" or "Tomorrow at 9:00 AM"
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

  /// Helper method to format TimeOfDay in a user-friendly format
  /// 
  /// @param time The TimeOfDay to format
  /// @return Formatted time string (e.g., "8:30 PM")
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
} 