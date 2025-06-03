import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/web_notification_service.dart';
import '../models/reminder.dart';
import 'dart:async';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  late final dynamic _notificationService;
  final WebNotificationService _webNotificationService = WebNotificationService();

  String _statusMessage = 'Ready to test notifications...';
  bool _isLoading = false;
  int _pendingNotifications = 0;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _notificationService = _webNotificationService;
    } else {
      _notificationService = NotificationService();
    }
    if (kIsWeb) {
       _webNotificationService.initialize().then((_) => _checkNotificationStatus());
    } else {
      _checkNotificationStatus();
    }
  }

  Future<void> _checkNotificationStatus() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (kIsWeb) {
        final isSupported = _webNotificationService.isSupported;
        setState(() {
          _statusMessage = 'Web Notifications: ${isSupported ? "Permission Granted" : "Permission NOT Granted or Not Supported"}\nTap "Test Instant Notification" to prompt if needed.';
          _pendingNotifications = 0;
        });
      } else {
        final pendingCount = await (_notificationService as NotificationService).getPendingNotificationsCount();
        setState(() {
          _pendingNotifications = pendingCount;
          _statusMessage = 'Notification system ready\nPending notifications: $pendingCount';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking notifications: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testInstantNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Sending instant notification...';
    });

    try {
      if (kIsWeb) {
        await _webNotificationService.sendTestNotification();
        setState(() {
          _statusMessage = '✅ Web notification sent!\nCheck your browser notifications.';
        });
      } else {
        await (_notificationService as NotificationService).showMessage(
          '🔔 Test Notification',
          'This is a test notification from AetherBloom! If you see this, the notification system is working perfectly.',
        );
        setState(() {
          _statusMessage = '✅ Instant notification sent!\nCheck your notification panel.';
        });
      }
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
      _statusMessage = kIsWeb ? 'Sending web medication reminder...' : 'Scheduling medication reminder...';
    });

    try {
      if (kIsWeb) {
        await _webNotificationService.sendMedicationReminder(medicationName: 'WebAspirin', dosage: '1 tablet');
         setState(() {
          _statusMessage = '✅ Web Medication reminder sent!';
        });
      } else {
        await (_notificationService as NotificationService).sendUsageConfirmation('Albuterol', 90.0);
        setState(() {
          _statusMessage = '✅ Medication confirmation sent!\nCheck your notification panel.';
        });
      }
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
      _statusMessage = kIsWeb ? 'Select when to schedule the notification...' : 'Scheduling reminder for 30 seconds from now...';
    });

    if (kIsWeb) {
      try {
        // Show time picker for web users
        final now = DateTime.now();
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: now.hour,
            minute: now.minute + 1, // Default to 1 minute from now
          ),
          helpText: 'Schedule Notification Time',
        );
        
        if (selectedTime == null) {
          setState(() {
            _statusMessage = 'Notification scheduling cancelled.';
            _isLoading = false;
          });
          return;
        }
        
        // Calculate the delay until the selected time
        final today = DateTime.now();
        var scheduledDateTime = DateTime(
          today.year,
          today.month,
          today.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        
        // If the selected time is in the past, schedule for tomorrow
        if (scheduledDateTime.isBefore(today)) {
          scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
        }
        
        final delay = scheduledDateTime.difference(today);
        
        setState(() {
          _statusMessage = '⏰ Notification scheduled for ${selectedTime.format(context)}\n'
              'Time remaining: ${delay.inMinutes} minutes ${delay.inSeconds % 60} seconds';
        });
        
        // Use Timer to schedule the notification
        Timer(delay, () async {
          await _webNotificationService.sendMedicationReminder(
            medicationName: 'Scheduled Medication',
            dosage: '1 dose'
          );
          print('⏰ Scheduled notification sent at ${DateTime.now()}');
        });
        
        setState(() {
          _statusMessage = '✅ Notification successfully scheduled for ${selectedTime.format(context)}!\n'
              'The notification will appear in ${delay.inMinutes} minutes ${delay.inSeconds % 60} seconds.';
        });
        
      } catch (e) {
        setState(() {
          _statusMessage = '❌ Error scheduling notification: $e';
        });
      } finally {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // Create a test reminder for 30 seconds from now (non-web platforms)
      final now = DateTime.now();
      final futureTime = now.add(const Duration(seconds: 30));
      
      final testReminder = Reminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Test Medication',
        description: 'This is a test scheduled reminder. Take your medication now!',
        time: TimeOfDay(hour: futureTime.hour, minute: futureTime.minute),
        weekdays: [
          futureTime.weekday == 1, futureTime.weekday == 2, futureTime.weekday == 3,
          futureTime.weekday == 4, futureTime.weekday == 5, futureTime.weekday == 6,
          futureTime.weekday == 7,
        ],
        isEnabled: true,
      );
      
      await (_notificationService as NotificationService).scheduleReminder(testReminder);
      
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

  Future<void> _testMedicationTaken() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Sending medication taken notification...';
    });

    try {
      if (kIsWeb) {
        await _webNotificationService.showCustomNotification(
          title: '✅ Medication Recorded',
          body: 'Your medication intake has been successfully recorded. Great adherence!',
        );
      } else {
        await _notificationService.showMessage(
          '✅ Medication Recorded',
          'Your medication intake has been successfully recorded. Great adherence!',
        );
      }
      
      setState(() {
        _statusMessage = 'Medication taken notification sent successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to send medication taken notification: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testMissedMedicationAlert() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Sending missed medication alert...';
    });

    try {
      if (kIsWeb) {
        await _webNotificationService.showCustomNotification(
          title: '⚠️ Missed Medication Alert',
          body: 'You may have missed your scheduled medication. Please take it as soon as possible.',
        );
      } else {
        await _notificationService.showMessage(
          '⚠️ Missed Medication Alert',
          'You may have missed your scheduled medication. Please take it as soon as possible.',
        );
      }
      
      setState(() {
        _statusMessage = 'Missed medication alert sent successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to send missed medication alert: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      _isLoading = true;
      _statusMessage = kIsWeb ? 'Web notifications are cleared by browser/OS.' : 'Clearing all notifications...';
    });

    if (kIsWeb) {
      setState(() {
        _statusMessage = 'ℹ️ Web notifications are managed by the browser/OS.\nThere is no app-side "clear all".';
      });
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);
      return;
    }

    try {
      await (_notificationService as NotificationService).cancelAllNotifications();
      setState(() {
        _statusMessage = '✅ All notifications cleared!';
      });
      await _checkNotificationStatus();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error clearing notifications: $e';
      });
    } finally {
      if(!kIsWeb) setState(() => _isLoading = false);
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
            onPressed: _isLoading ? null : _checkNotificationStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              title: 'Test Medication Taken',
              subtitle: 'Simulate medication taken notification',
              icon: Icons.medication,
              onPressed: _isLoading ? null : _testMedicationTaken,
            ),
            
            const SizedBox(height: 12),
            
            _TestButton(
              title: 'Test Missed Medication Alert',
              subtitle: 'Simulate missed medication warning',
              icon: Icons.warning,
              onPressed: _isLoading ? null : _testMissedMedicationAlert,
            ),
            
            const SizedBox(height: 24),
            
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