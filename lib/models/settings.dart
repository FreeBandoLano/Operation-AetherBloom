import 'package:flutter/material.dart';

class NotificationSettings {
  final bool quietHoursEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final bool groupNotifications;
  final int maxNotificationsPerHour;
  final Duration minTimeBetweenNotifications;
  final Map<String, bool> enabledDays;

  const NotificationSettings({
    this.quietHoursEnabled = false,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 7, minute: 0),
    this.groupNotifications = true,
    this.maxNotificationsPerHour = 3,
    this.minTimeBetweenNotifications = const Duration(minutes: 15),
    Map<String, bool>? enabledDays,
  }) : enabledDays = enabledDays ??
            const {
              'Monday': true,
              'Tuesday': true,
              'Wednesday': true,
              'Thursday': true,
              'Friday': true,
              'Saturday': true,
              'Sunday': true,
            };

  Map<String, dynamic> toJson() {
    return {
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': {
        'hour': quietHoursStart.hour,
        'minute': quietHoursStart.minute,
      },
      'quietHoursEnd': {
        'hour': quietHoursEnd.hour,
        'minute': quietHoursEnd.minute,
      },
      'groupNotifications': groupNotifications,
      'maxNotificationsPerHour': maxNotificationsPerHour,
      'minTimeBetweenNotifications': minTimeBetweenNotifications.inMinutes,
      'enabledDays': enabledDays,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: TimeOfDay(
        hour: (json['quietHoursStart'] as Map<String, dynamic>)['hour'] as int,
        minute: (json['quietHoursStart'] as Map<String, dynamic>)['minute'] as int,
      ),
      quietHoursEnd: TimeOfDay(
        hour: (json['quietHoursEnd'] as Map<String, dynamic>)['hour'] as int,
        minute: (json['quietHoursEnd'] as Map<String, dynamic>)['minute'] as int,
      ),
      groupNotifications: json['groupNotifications'] as bool? ?? true,
      maxNotificationsPerHour: json['maxNotificationsPerHour'] as int? ?? 3,
      minTimeBetweenNotifications: Duration(
        minutes: json['minTimeBetweenNotifications'] as int? ?? 15,
      ),
      enabledDays: (json['enabledDays'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
          ) ??
          {
            'Monday': true,
            'Tuesday': true,
            'Wednesday': true,
            'Thursday': true,
            'Friday': true,
            'Saturday': true,
            'Sunday': true,
          },
    );
  }

  NotificationSettings copyWith({
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? groupNotifications,
    int? maxNotificationsPerHour,
    Duration? minTimeBetweenNotifications,
    Map<String, bool>? enabledDays,
  }) {
    return NotificationSettings(
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      maxNotificationsPerHour:
          maxNotificationsPerHour ?? this.maxNotificationsPerHour,
      minTimeBetweenNotifications:
          minTimeBetweenNotifications ?? this.minTimeBetweenNotifications,
      enabledDays: enabledDays ?? Map<String, bool>.from(this.enabledDays),
    );
  }

  bool isInQuietHours(TimeOfDay time) {
    if (!quietHoursEnabled) return false;

    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = quietHoursStart.hour * 60 + quietHoursStart.minute;
    final endMinutes = quietHoursEnd.hour * 60 + quietHoursEnd.minute;
    final timeMinutes = time.hour * 60 + time.minute;

    if (startMinutes <= endMinutes) {
      // Quiet hours within the same day
      return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
    } else {
      // Quiet hours span across midnight
      return timeMinutes >= startMinutes || timeMinutes <= endMinutes;
    }
  }

  bool isDayEnabled(String weekday) {
    return enabledDays[weekday] ?? true;
  }
} 