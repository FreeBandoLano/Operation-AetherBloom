import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Send a test notification to verify your notification system is working correctly.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Notification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        notificationService.showMessage(
                          'Test Notification',
                          'This is a test notification from AetherBloom.',
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications),
                      label: const Text('Send Test Notification'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Smart Scheduling',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Smart Scheduling Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Quiet Hours'),
                      subtitle: const Text('No notifications during sleeping hours'),
                      value: false, // Would be stored in settings
                      onChanged: (value) {
                        // Would update settings
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Group Notifications'),
                      subtitle: const Text('Group similar notifications to avoid overload'),
                      value: true, // Would be stored in settings
                      onChanged: (value) {
                        // Would update settings
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Priority-Based Scheduling'),
                      subtitle: const Text('Schedule notifications based on importance'),
                      value: true, // Would be stored in settings
                      onChanged: (value) {
                        // Would update settings
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Weekend Notifications'),
                      subtitle: const Text('Allow notifications on weekends'),
                      value: true, // Would be stored in settings
                      onChanged: (value) {
                        // Would update settings
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 