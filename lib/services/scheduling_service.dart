import 'package:flutter/material.dart';
import '../models/reminder.dart';
import 'notification_service.dart';
import 'shared_preferences_service.dart';

class SchedulingService {
  static final SchedulingService _instance = SchedulingService._();
  factory SchedulingService() => _instance;

  final NotificationService _notificationService = NotificationService();
  static const String _quietHoursStartKey = 'quiet_hours_start';
  static const String _quietHoursEndKey = 'quiet_hours_end';
  static const int _maxNotificationsPerHour = 3;

  SchedulingService._();

  /// Get quiet hours
  Future<QuietHours> getQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final startHour = prefs.getInt(_quietHoursStartKey) ?? 22; // Default 10 PM
    final endHour = prefs.getInt(_quietHoursEndKey) ?? 8;     // Default 8 AM
    return QuietHours(
      start: TimeOfDay(hour: startHour, minute: 0),
      end: TimeOfDay(hour: endHour, minute: 0),
    );
  }

  /// Set quiet hours
  Future<void> setQuietHours(TimeOfDay start, TimeOfDay end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quietHoursStartKey, start.hour);
    await prefs.setInt(_quietHoursEndKey, end.hour);
    // Reschedule all reminders to respect new quiet hours
    // TODO: Implement reminder rescheduling
  }

  /// Check if current time is within quiet hours
  Future<bool> isQuietHours() async {
    final quietHours = await getQuietHours();
    final now = TimeOfDay.now();
    
    // Convert to minutes since midnight for easier comparison
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = quietHours.start.hour * 60;
    final endMinutes = quietHours.end.hour * 60;
    
    if (startMinutes < endMinutes) {
      // Simple case: quiet hours within same day
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Complex case: quiet hours span midnight
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  /// Schedule a reminder with smart timing
  Future<DateTime?> getNextSmartScheduleTime(Reminder reminder) async {
    if (await isQuietHours()) {
      // If we're in quiet hours, schedule for the end of quiet hours
      final quietHours = await getQuietHours();
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        quietHours.end.hour,
        quietHours.end.minute,
      );
    }

    // Get existing notifications in the next hour
    final existingNotifications = await _getUpcomingNotifications(const Duration(hours: 1));
    if (existingNotifications.length >= _maxNotificationsPerHour) {
      // Too many notifications in the next hour, delay by 15 minutes
      return DateTime.now().add(const Duration(minutes: 15));
    }

    // Use the original scheduled time
    return reminder.getNextOccurrence();
  }

  /// Get upcoming notifications within a time window
  Future<List<Reminder>> _getUpcomingNotifications(Duration window) async {
    // TODO: Implement getting upcoming notifications from storage
    return [];
  }

  /// Group similar reminders together
  Future<void> groupReminders(List<Reminder> reminders) async {
    // Sort reminders by priority and time
    reminders.sort((a, b) {
      if (a.priority != b.priority) {
        return b.priority.index - a.priority.index; // Higher priority first
      }
      return a.time.hour * 60 + a.time.minute - (b.time.hour * 60 + b.time.minute);
    });

    // Group reminders that are within 15 minutes of each other
    final groups = <List<Reminder>>[];
    List<Reminder> currentGroup = [];

    for (final reminder in reminders) {
      if (currentGroup.isEmpty) {
        currentGroup.add(reminder);
      } else {
        final lastReminder = currentGroup.last;
        final timeDiff = (reminder.time.hour * 60 + reminder.time.minute) -
            (lastReminder.time.hour * 60 + lastReminder.time.minute);
        
        if (timeDiff.abs() <= 15) {
          currentGroup.add(reminder);
        } else {
          groups.add(List.from(currentGroup));
          currentGroup = [reminder];
        }
      }
    }

    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    // Schedule grouped notifications
    for (final group in groups) {
      if (group.length == 1) {
        await _notificationService.scheduleReminder(group.first);
      } else {
        // Create a grouped notification
        final highestPriority = group.map((r) => r.priority).reduce((a, b) => 
          a.index > b.index ? a : b);
        
        final combinedReminder = Reminder(
          id: 'group_${group.first.id}',
          title: 'Multiple Reminders',
          description: '${group.length} reminders: ${group.map((r) => r.title).join(", ")}',
          time: group.first.time,
          weekdays: group.first.weekdays,
          priority: highestPriority,
        );
        
        await _notificationService.scheduleReminder(combinedReminder);
      }
    }
  }
}

class QuietHours {
  final TimeOfDay start;
  final TimeOfDay end;

  const QuietHours({
    required this.start,
    required this.end,
  });
} 