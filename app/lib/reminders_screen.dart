import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/reminder.dart';
import 'services/reminder_data_source.dart';
import 'services/notification_service.dart';

/// Screen for managing medication reminders
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderDataSource _dataSource = ReminderDataSource();
  final NotificationService _notificationService = NotificationService();
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _notificationService.initialize();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final reminders = await _dataSource.getReminders();
    setState(() {
      _reminders = reminders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: const Color(0xFFF4A7B9),
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_add),
            onPressed: _testNotification,
            tooltip: 'Test Notification',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _buildEmptyState()
              : _buildRemindersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReminderDialog(),
        backgroundColor: const Color(0xFFE91E63),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a medication reminder',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final nextOccurrence = reminder.getNextOccurrence();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _showReminderDialog(reminder: reminder),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    reminder.priorityIcon,
                    color: reminder.priorityColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reminder.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Switch(
                    value: reminder.isEnabled,
                    onChanged: (value) => _toggleReminder(reminder),
                    activeColor: const Color(0xFFE91E63),
                  ),
                ],
              ),
              if (reminder.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  reminder.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reminder.timeString,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reminder.activeWeekdays.join(', '),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              if (nextOccurrence != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Next: ${_formatDateTime(nextOccurrence)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReminderDialog({Reminder? reminder}) async {
    final result = await showDialog<Reminder>(
      context: context,
      builder: (context) => ReminderDialog(reminder: reminder),
    );

    if (result != null) {
      if (reminder != null) {
        await _updateReminder(result);
      } else {
        await _addReminder(result);
      }
    }
  }

  Future<void> _addReminder(Reminder reminder) async {
    await _dataSource.addReminder(reminder);
    if (reminder.isEnabled) {
      await _notificationService.scheduleReminder(reminder);
    }
    _loadReminders();
  }

  Future<void> _updateReminder(Reminder reminder) async {
    await _dataSource.updateReminder(reminder);
    await _notificationService.cancelReminder(reminder);
    if (reminder.isEnabled) {
      await _notificationService.scheduleReminder(reminder);
    }
    _loadReminders();
  }

  Future<void> _toggleReminder(Reminder reminder) async {
    await _dataSource.toggleReminder(reminder.id);
    if (reminder.isEnabled) {
      await _notificationService.cancelReminder(reminder);
    } else {
      final updated = reminder.copyWith(isEnabled: true);
      await _notificationService.scheduleReminder(updated);
    }
    _loadReminders();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day + 1) {
      return 'Tomorrow at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return '${dateTime.day}/${dateTime.month} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Test notification functionality
  Future<void> _testNotification() async {
    final now = TimeOfDay.now();
    final testReminder = Reminder(
      id: 'test_notification',
      title: 'Test Reminder',
      description: 'This is a test notification',
      time: TimeOfDay(
        hour: now.hour,
        minute: now.minute + 1,
      ),
      weekdays: List.generate(7, (index) => true),
      priority: ReminderPriority.normal,
      isEnabled: true,
    );

    try {
      await _notificationService.scheduleReminder(testReminder);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification scheduled for 1 minute from now'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule test notification: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

/// Dialog for creating and editing reminders
class ReminderDialog extends StatefulWidget {
  final Reminder? reminder;

  const ReminderDialog({
    super.key,
    this.reminder,
  });

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late TimeOfDay _selectedTime;
  late List<bool> _selectedDays;
  late ReminderPriority _selectedPriority;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    if (reminder != null) {
      _titleController.text = reminder.title;
      _descriptionController.text = reminder.description;
      _selectedTime = reminder.time;
      _selectedDays = List.from(reminder.weekdays);
      _selectedPriority = reminder.priority;
    } else {
      _selectedTime = TimeOfDay.now();
      _selectedDays = List.filled(7, false);
      _selectedPriority = ReminderPriority.normal;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.reminder != null ? 'Edit Reminder' : 'New Reminder',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Time:'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _showTimePicker,
                  child: Text(
                    '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Repeat on:'),
            const SizedBox(height: 8),
            _buildWeekdaySelector(),
            const SizedBox(height: 16),
            const Text('Priority:'),
            const SizedBox(height: 8),
            _buildPrioritySelector(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        return InkWell(
          onTap: () => setState(() => _selectedDays[index] = !_selectedDays[index]),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedDays[index]
                  ? const Color(0xFFE91E63)
                  : Colors.transparent,
              border: Border.all(
                color: _selectedDays[index]
                    ? const Color(0xFFE91E63)
                    : Colors.grey,
              ),
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  color: _selectedDays[index] ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPrioritySelector() {
    return Wrap(
      spacing: 8,
      children: ReminderPriority.values.map((priority) {
        final isSelected = priority == _selectedPriority;
        return ChoiceChip(
          label: Text(_getPriorityLabel(priority)),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedPriority = priority),
          selectedColor: _getPriorityColor(priority),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveReminder() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (!_selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final reminder = Reminder(
      id: widget.reminder?.id ?? const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      time: _selectedTime,
      weekdays: _selectedDays,
      priority: _selectedPriority,
      isEnabled: widget.reminder?.isEnabled ?? true,
    );

    Navigator.pop(context, reminder);
  }

  String _getPriorityLabel(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return 'Low';
      case ReminderPriority.normal:
        return 'Normal';
      case ReminderPriority.high:
        return 'High';
      case ReminderPriority.urgent:
        return 'Urgent';
    }
  }

  Color _getPriorityColor(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return Colors.green;
      case ReminderPriority.normal:
        return Colors.blue;
      case ReminderPriority.high:
        return Colors.orange;
      case ReminderPriority.urgent:
        return Colors.red;
    }
  }
}
