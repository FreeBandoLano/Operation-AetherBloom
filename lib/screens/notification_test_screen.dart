import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/reminder.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  String _statusMessage = 'Ready to test notifications...';
  bool _isLoading = false;
  int _pendingNotifications = 0;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    try {
      final pendingCount = await _notificationService.getPendingNotificationsCount();
      setState(() {
        _pendingNotifications = pendingCount;
        _statusMessage = 'Notification system ready\nPending notifications: $pendingCount';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking notifications: $e';
      });
    }
  }

  Future<void> _testInstantNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Sending instant notification...';
    });

    try {
      await _notificationService.showInstantNotification(
        '🔔 Test Notification',
        'This is a test notification from AetherBloom! If you see this, the notification system is working perfectly.',
      );
      
      setState(() {
        _statusMessage = '✅ Instant notification sent!\nCheck your notification panel.';
      });
      
      await _checkNotificationStatus();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error sending notification: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testMedicationReminder() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Scheduling medication reminder...';
    });

    try {
      await _notificationService.sendUsageConfirmation('Albuterol', 90.0);
      
      setState(() {
        _statusMessage = '✅ Medication confirmation sent!\nCheck your notification panel.';
      });
      
      await _checkNotificationStatus();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error sending medication reminder: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testScheduledReminder() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Scheduling reminder for 30 seconds from now...';
    });

    try {
      // Create a test reminder for 30 seconds from now
      final now = DateTime.now();
      final futureTime = now.add(const Duration(seconds: 30));
      
      final testReminder = Reminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Test Medication',
        description: 'This is a test scheduled reminder. Take your medication now!',
        time: TimeOfDay(hour: futureTime.hour, minute: futureTime.minute),
        weekdays: [
          futureTime.weekday == 1, // Monday
          futureTime.weekday == 2, // Tuesday
          futureTime.weekday == 3, // Wednesday
          futureTime.weekday == 4, // Thursday
          futureTime.weekday == 5, // Friday
          futureTime.weekday == 6, // Saturday
          futureTime.weekday == 7, // Sunday
        ],
        isEnabled: true,
      );
      
      await _notificationService.scheduleReminder(testReminder);
      
      setState(() {
        _statusMessage = '✅ Scheduled reminder set!\nYou should receive a notification in 30 seconds.\n\nTip: Keep the app in background to test properly.';
      });
      
      await _checkNotificationStatus();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error scheduling reminder: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testMissedMedication() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Sending missed medication alert...';
    });

    try {
      final missedTime = DateTime.now().subtract(const Duration(minutes: 15));
      await _notificationService.sendMissedMedicationAlert('Albuterol', missedTime);
      
      setState(() {
        _statusMessage = '✅ Missed medication alert sent!\nCheck your notification panel.';
      });
      
      await _checkNotificationStatus();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error sending missed medication alert: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing all notifications...';
    });

    try {
      await _notificationService.cancelAllNotifications();
      
      setState(() {
        _statusMessage = '✅ All notifications cleared!';
      });
      
      await _checkNotificationStatus();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error clearing notifications: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Notification System Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkNotificationStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 System Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16),
                        const SizedBox(width: 4),
                        Text('Pending: $_pendingNotifications'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            const Text(
              '🧪 Notification Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 16),
            
            _TestButton(
              title: 'Test Instant Notification',
              subtitle: 'Send an immediate notification',
              icon: Icons.notifications,
              onPressed: _isLoading ? null : _testInstantNotification,
            ),
            
            const SizedBox(height: 12),
            
            _TestButton(
              title: 'Test Medication Confirmation',
              subtitle: 'Simulate medication taken notification',
              icon: Icons.medication,
              onPressed: _isLoading ? null : _testMedicationReminder,
            ),
            
            const SizedBox(height: 12),
            
            _TestButton(
              title: 'Test Scheduled Reminder',
              subtitle: 'Schedule a notification for 30 seconds from now',
              icon: Icons.schedule,
              onPressed: _isLoading ? null : _testScheduledReminder,
            ),
            
            const SizedBox(height: 12),
            
            _TestButton(
              title: 'Test Missed Medication Alert',
              subtitle: 'Simulate missed medication warning',
              icon: Icons.warning,
              onPressed: _isLoading ? null : _testMissedMedication,
            ),
            
            const SizedBox(height: 24),
            
            // Management buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearAllNotifications,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkNotificationStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Testing Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Instant notifications should appear immediately\n'
                      '• For scheduled tests, minimize the app to test background delivery\n'
                      '• On Android 13+, notification permission may be requested\n'
                      '• Check notification settings if tests fail',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onPressed;

  const _TestButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onPressed,
        enabled: onPressed != null,
      ),
    );
  }
} 