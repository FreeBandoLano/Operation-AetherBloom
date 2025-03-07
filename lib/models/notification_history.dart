import 'package:flutter/material.dart';

enum NotificationStatus {
  sent,
  delivered,
  snoozed,
  missed,
  completed
}

class NotificationHistoryItem {
  final String id;
  final String title;
  final String message;
  final DateTime scheduledTime;
  final DateTime? deliveredTime;
  final NotificationStatus status;
  final String? reminderId;
  final bool isRecurring;

  NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.message,
    required this.scheduledTime,
    this.deliveredTime,
    required this.status,
    this.reminderId,
    this.isRecurring = false,
  });

  // Create from JSON
  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      deliveredTime: json['deliveredTime'] != null 
          ? DateTime.parse(json['deliveredTime']) 
          : null,
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      reminderId: json['reminderId'],
      isRecurring: json['isRecurring'] ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'scheduledTime': scheduledTime.toIso8601String(),
      'deliveredTime': deliveredTime?.toIso8601String(),
      'status': status.toString(),
      'reminderId': reminderId,
      'isRecurring': isRecurring,
    };
  }

  // Get status icon
  IconData get statusIcon {
    switch (status) {
      case NotificationStatus.sent:
        return Icons.send;
      case NotificationStatus.delivered:
        return Icons.notifications_active;
      case NotificationStatus.snoozed:
        return Icons.snooze;
      case NotificationStatus.missed:
        return Icons.notification_important;
      case NotificationStatus.completed:
        return Icons.check_circle;
    }
  }

  // Get status color
  Color get statusColor {
    switch (status) {
      case NotificationStatus.sent:
        return Colors.blue;
      case NotificationStatus.delivered:
        return Colors.green;
      case NotificationStatus.snoozed:
        return Colors.orange;
      case NotificationStatus.missed:
        return Colors.red;
      case NotificationStatus.completed:
        return Colors.grey;
    }
  }

  // Format relative time
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(scheduledTime);

    if (difference.inDays > 7) {
      return '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 