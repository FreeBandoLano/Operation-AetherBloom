import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';
import '../models/reminder.dart';
import '../models/settings.dart';
import 'notification_service.dart';

class MedicationService {
  static const String _storageKey = 'medications';
  static const String _settingsKey = 'notification_settings';
  static final MedicationService _instance = MedicationService._();
  
  factory MedicationService() => _instance;
  
  final NotificationService _notificationService = NotificationService();
  late NotificationSettings _settings;
  List<Medication> _medications = [];

  MedicationService._();

  Future<void> initialize() async {
    await _loadSettings();
    await _loadMedications();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);
    
    if (jsonString != null) {
      final json = jsonDecode(jsonString);
      _settings = NotificationSettings.fromJson(json);
    } else {
      _settings = const NotificationSettings();
      await _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    _settings = settings;
    await _saveSettings();
    // Reschedule all medication reminders with new settings
    await _rescheduleAllReminders();
  }

  NotificationSettings get settings => _settings;

  Future<void> _loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString != null) {
      final jsonList = jsonDecode(jsonString) as List;
      _medications = jsonList
          .map((json) => Medication.fromJson(json))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      _medications.map((med) => med.toJson()).toList(),
    );
    await prefs.setString(_storageKey, jsonString);
  }

  List<Medication> get medications => List.unmodifiable(_medications);

  List<Medication> get medicationsNeedingRefill => 
      _medications.where((med) => med.needsRefill).toList();

  Future<void> addMedication(Medication medication) async {
    _medications.add(medication);
    await _saveMedications();
    await _scheduleReminders(medication);
  }

  Future<void> updateMedication(Medication medication) async {
    final index = _medications.indexWhere((med) => med.id == medication.id);
    if (index != -1) {
      _medications[index] = medication;
      await _saveMedications();
      await _rescheduleReminders(medication);
    }
  }

  Future<void> deleteMedication(String id) async {
    final medication = _medications.firstWhere((med) => med.id == id);
    _medications.removeWhere((med) => med.id == id);
    await _saveMedications();
    await _cancelReminders(medication);
  }

  Future<void> recordDoseTaken(String medicationId, DateTime timestamp) async {
    final index = _medications.indexWhere((med) => med.id == medicationId);
    if (index != -1) {
      final medication = _medications[index];
      final updatedMedication = medication.copyWith(
        currentQuantity: medication.currentQuantity - 1,
        adherenceLog: {
          ...medication.adherenceLog,
          timestamp: true,
        },
      );
      _medications[index] = updatedMedication;
      await _saveMedications();

      // Check if refill is needed
      if (updatedMedication.needsRefill) {
        await _notificationService.scheduleReminder(
          Reminder(
            id: 'refill_${medication.id}',
            title: 'Refill Needed',
            description: '${medication.name} needs to be refilled soon.',
            time: const TimeOfDay(hour: 9, minute: 0),
            weekdays: List.generate(7, (index) => true),
          ),
        );
      }
    }
  }

  Future<void> recordDoseSkipped(String medicationId, DateTime timestamp) async {
    final index = _medications.indexWhere((med) => med.id == medicationId);
    if (index != -1) {
      final medication = _medications[index];
      final updatedMedication = medication.copyWith(
        adherenceLog: {
          ...medication.adherenceLog,
          timestamp: false,
        },
      );
      _medications[index] = updatedMedication;
      await _saveMedications();
    }
  }

  Future<void> recordRefill(String medicationId) async {
    final index = _medications.indexWhere((med) => med.id == medicationId);
    if (index != -1) {
      final medication = _medications[index];
      final updatedMedication = medication.copyWith(
        currentQuantity: medication.currentQuantity + medication.refillAmount,
        lastRefillDate: DateTime.now(),
      );
      _medications[index] = updatedMedication;
      await _saveMedications();

      // Cancel refill reminder if it exists
      await _notificationService.cancelReminder(
        Reminder(
          id: 'refill_${medication.id}',
          title: '',
          description: '',
          time: const TimeOfDay(hour: 0, minute: 0),
          weekdays: [],
        ),
      );
    }
  }

  Future<void> _scheduleReminders(Medication medication) async {
    if (medication.frequency == MedicationFrequency.asNeeded) return;

    for (final time in medication.scheduledTimes) {
      final reminder = Reminder(
        id: '${medication.id}_${time.hour}_${time.minute}',
        title: 'Time to take ${medication.name}',
        description: 'Take ${medication.dosageText}',
        time: time,
        weekdays: medication.weekdays,
      );
      await _notificationService.scheduleReminder(reminder);
    }
  }

  Future<void> _rescheduleReminders(Medication medication) async {
    await _cancelReminders(medication);
    await _scheduleReminders(medication);
  }

  Future<void> _cancelReminders(Medication medication) async {
    for (final time in medication.scheduledTimes) {
      final reminder = Reminder(
        id: '${medication.id}_${time.hour}_${time.minute}',
        title: '',
        description: '',
        time: time,
        weekdays: [],
      );
      await _notificationService.cancelReminder(reminder);
    }
  }

  Future<void> _rescheduleAllReminders() async {
    for (final medication in _medications) {
      await _rescheduleReminders(medication);
    }
  }

  Map<DateTime, List<Medication>> getMedicationSchedule({
    DateTime? start,
    DateTime? end,
  }) {
    start ??= DateTime.now();
    end ??= start.add(const Duration(days: 7));

    final schedule = <DateTime, List<Medication>>{};
    final current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      final medications = _medications.where((med) {
        if (med.frequency == MedicationFrequency.asNeeded) return false;
        if (!med.weekdays[current.weekday - 1]) return false;
        if (_settings.quietHoursEnabled) {
          for (final time in med.scheduledTimes) {
            if (_settings.isInQuietHours(time)) return false;
          }
        }
        return true;
      }).toList();

      if (medications.isNotEmpty) {
        schedule[current] = medications;
      }

      current.add(const Duration(days: 1));
    }

    return schedule;
  }

  List<MapEntry<DateTime, bool>> getAdherenceHistory(
    String medicationId, {
    DateTime? start,
    DateTime? end,
  }) {
    final medication = _medications.firstWhere((med) => med.id == medicationId);
    final history = medication.adherenceLog.entries.where((entry) {
      if (start != null && entry.key.isBefore(start)) return false;
      if (end != null && entry.key.isAfter(end)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return history;
  }

  double getAdherenceRate(
    String medicationId, {
    DateTime? start,
    DateTime? end,
  }) {
    final history = getAdherenceHistory(medicationId, start: start, end: end);
    if (history.isEmpty) return 0.0;

    final takenCount = history.where((entry) => entry.value).length;
    return takenCount / history.length;
  }
} 