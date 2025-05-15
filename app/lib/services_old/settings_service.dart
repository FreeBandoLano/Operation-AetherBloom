import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  final bool quietHoursEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final bool groupNotifications;
  final int maxNotificationsPerHour;
  final Duration minTimeBetweenNotifications;

  const NotificationSettings({
    this.quietHoursEnabled = false,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    this.groupNotifications = true,
    this.maxNotificationsPerHour = 3,
    this.minTimeBetweenNotifications = const Duration(minutes: 10),
  });

  Map<String, dynamic> toJson() => {
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
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: TimeOfDay(
        hour: json['quietHoursStart']['hour'],
        minute: json['quietHoursStart']['minute'],
      ),
      quietHoursEnd: TimeOfDay(
        hour: json['quietHoursEnd']['hour'],
        minute: json['quietHoursEnd']['minute'],
      ),
      groupNotifications: json['groupNotifications'] ?? true,
      maxNotificationsPerHour: json['maxNotificationsPerHour'] ?? 3,
      minTimeBetweenNotifications: Duration(
        minutes: json['minTimeBetweenNotifications'] ?? 10,
      ),
    );
  }

  bool isInQuietHours(DateTime time) {
    if (!quietHoursEnabled) return false;

    final timeOfDay = TimeOfDay.fromDateTime(time);
    final start = quietHoursStart;
    final end = quietHoursEnd;

    // Convert to minutes since midnight for easier comparison
    final currentMinutes = timeOfDay.hour * 60 + timeOfDay.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Simple case: quiet hours within same day
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Complex case: quiet hours span midnight
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  NotificationSettings copyWith({
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? groupNotifications,
    int? maxNotificationsPerHour,
    Duration? minTimeBetweenNotifications,
  }) {
    return NotificationSettings(
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      maxNotificationsPerHour: maxNotificationsPerHour ?? this.maxNotificationsPerHour,
      minTimeBetweenNotifications: minTimeBetweenNotifications ?? this.minTimeBetweenNotifications,
    );
  }
}

class SettingsService {
  static const String _settingsKey = 'notification_settings';
  static final SettingsService _instance = SettingsService._();
  
  factory SettingsService() => _instance;
  SettingsService._();

  NotificationSettings? _cachedSettings;

  Future<NotificationSettings> getSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);
    
    if (jsonString == null) {
      // Default settings
      _cachedSettings = NotificationSettings(
        quietHoursStart: const TimeOfDay(hour: 22, minute: 0),
        quietHoursEnd: const TimeOfDay(hour: 7, minute: 0),
      );
      return _cachedSettings!;
    }

    try {
      final json = jsonDecode(jsonString);
      _cachedSettings = NotificationSettings.fromJson(json);
      return _cachedSettings!;
    } catch (e) {
      print('Error loading settings: $e');
      // Return default settings on error
      _cachedSettings = NotificationSettings(
        quietHoursStart: const TimeOfDay(hour: 22, minute: 0),
        quietHoursEnd: const TimeOfDay(hour: 7, minute: 0),
      );
      return _cachedSettings!;
    }
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
    _cachedSettings = settings;
  }

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    _cachedSettings = null;
  }
} 