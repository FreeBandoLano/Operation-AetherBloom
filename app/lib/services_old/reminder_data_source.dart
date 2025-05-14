import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';

/// Service to handle reminder data persistence
class ReminderDataSource {
  final String _storageKey = 'reminders';

  /// Save a list of reminders
  Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = reminders.map((reminder) => reminder.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonData));
  }

  /// Get all saved reminders
  Future<List<Reminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_storageKey);

    if (jsonData != null) {
      final List<dynamic> decodedData = jsonDecode(jsonData);
      return decodedData
          .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Add a new reminder
  Future<void> addReminder(Reminder reminder) async {
    final reminders = await getReminders();
    reminders.add(reminder);
    await saveReminders(reminders);
  }

  /// Update an existing reminder
  Future<void> updateReminder(Reminder reminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    
    if (index != -1) {
      reminders[index] = reminder;
      await saveReminders(reminders);
    }
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((reminder) => reminder.id == id);
    await saveReminders(reminders);
  }

  /// Toggle reminder enabled state
  Future<void> toggleReminder(String id) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == id);
    
    if (index != -1) {
      final reminder = reminders[index];
      reminders[index] = reminder.copyWith(isEnabled: !reminder.isEnabled);
      await saveReminders(reminders);
    }
  }

  /// Get active reminders (enabled and with future occurrences)
  Future<List<Reminder>> getActiveReminders() async {
    final reminders = await getReminders();
    return reminders.where((reminder) {
      return reminder.isEnabled && reminder.getNextOccurrence() != null;
    }).toList();
  }
} 