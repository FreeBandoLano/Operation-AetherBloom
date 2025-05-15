import 'package:flutter/material.dart';
import '../models/notification_record.dart';
import '../models/reminder.dart';
import 'notification_history_service.dart';

/// Service to handle all notification-related functionality
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final NotificationHistoryService _historyService = NotificationHistoryService();

  NotificationService._();

  Future<void> initialize() async {
    await _historyService.initialize();
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    // TODO: Implement platform-specific notification scheduling
    await _historyService.addRecord(
      NotificationRecord(
        id: reminder.id,
        title: reminder.title,
        description: reminder.description,
        timestamp: DateTime.now(),
        status: NotificationStatus.scheduled,
      ),
    );
  }

  Future<void> cancelReminder(Reminder reminder) async {
    // TODO: Implement platform-specific notification cancellation
    await _historyService.addRecord(
      NotificationRecord(
        id: reminder.id,
        title: 'Reminder Cancelled',
        description: 'The reminder has been cancelled',
        timestamp: DateTime.now(),
        status: NotificationStatus.cancelled,
      ),
    );
  }
} 