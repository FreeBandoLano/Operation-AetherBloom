import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/reminder.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _notificationService = NotificationService();
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    // TODO: Implement loading reminders from NotificationService
    setState(() {
      _reminders = [];
      _isLoading = false;
    });
  }

  Future<void> _showAddReminderDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Reminder'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Time'),
                trailing: Text(selectedTime.format(context)),
                onTap: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() => selectedTime = time);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reminder = Reminder(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text,
                description: messageController.text,
                time: selectedTime,
                weekdays: List.filled(7, true), // Default to every day
                isEnabled: true,
              );

              await _notificationService.scheduleReminder(reminder);
              Navigator.pop(context);
              _loadReminders();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddReminderDialog,
          ),
        ],
      ),
      body: _reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No reminders set',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showAddReminderDialog,
                    child: const Text('Add Reminder'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(reminder.title),
                    subtitle: Text(reminder.description),
                    trailing: Switch(
                      value: reminder.isEnabled,
                      onChanged: (value) async {
                        // TODO: Implement enabling/disabling reminders
                      },
                    ),
                    onTap: () {
                      // TODO: Navigate to reminder details screen
                    },
                  ),
                );
              },
            ),
    );
  }
} 