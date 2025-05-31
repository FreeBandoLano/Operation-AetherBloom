import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_record.dart';
import '../models/reminder.dart';
import 'notification_history_service.dart';

/// Service to handle all notification-related functionality
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final NotificationHistoryService _historyService = NotificationHistoryService();
  final String _serverUrl = 'http://localhost:8080';

  NotificationService._();

  Future<void> initialize() async {
    await _historyService.initialize();
    
    // Test notification to ensure server is running
    await _sendTestNotification();
  }

  Future<void> _sendTestNotification() async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/notify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': 'AetherBloom Connected',
          'message': 'Notification system is now active',
          'duration': 3
        }),
      );
      
      if (response.statusCode == 200) {
        print('Test notification sent successfully');
      } else {
        print('Failed to send test notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    try {
      // Convert weekdays from boolean list to integer indices
      final List<int> weekdayIndices = [];
      for (int i = 0; i < reminder.weekdays.length; i++) {
        if (reminder.weekdays[i]) {
          weekdayIndices.add(i);  // Python server expects 0-6 for Mon-Sun
        }
      }
      
      final timeString = '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}';
      
      // Send the reminder to the Python server
      final response = await http.post(
        Uri.parse('$_serverUrl/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': reminder.id,
          'title': reminder.title,
          'message': reminder.description,
          'time': timeString,
          'weekdays': weekdayIndices,
        }),
      );
      
      if (response.statusCode != 200) {
        print('Failed to schedule reminder: ${response.statusCode}');
      }
      
      // Log the notification in the history
      await _historyService.addRecord(
        NotificationRecord(
          id: reminder.id,
          title: reminder.title,
          description: reminder.description,
          timestamp: DateTime.now(),
          status: NotificationStatus.scheduled,
        ),
      );
    } catch (e) {
      print('Error scheduling reminder: $e');
    }
  }

  Future<void> cancelReminder(Reminder reminder) async {
    try {
      // Send cancellation request to the Python server
      final response = await http.post(
        Uri.parse('$_serverUrl/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': reminder.id,
        }),
      );
      
      if (response.statusCode != 200) {
        print('Failed to cancel reminder: ${response.statusCode}');
      }
      
      // Log the cancellation in the history
      await _historyService.addRecord(
        NotificationRecord(
          id: reminder.id,
          title: 'Reminder Cancelled',
          description: 'The reminder has been cancelled',
          timestamp: DateTime.now(),
          status: NotificationStatus.cancelled,
        ),
      );
    } catch (e) {
      print('Error cancelling reminder: $e');
    }
  }

  Future<void> showMessage(String title, String message) async {
    try {
      // Display a local notification
      await _historyService.addRecord(
        NotificationRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: message,
          timestamp: DateTime.now(),
          status: NotificationStatus.info,
        ),
      );
      
      // Send to Python server if available
      try {
        final response = await http.post(
          Uri.parse('$_serverUrl/notify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'message': message,
            'duration': 3
          }),
        );
        
        if (response.statusCode != 200) {
          print('Failed to send notification: ${response.statusCode}');
        }
      } catch (e) {
        print('Error sending notification: $e');
      }
    } catch (e) {
      print('Error showing message: $e');
    }
  }
} 