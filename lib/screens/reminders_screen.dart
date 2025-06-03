import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/medication.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../services/web_notification_service.dart';
import 'add_medication_screen.dart';
import 'dart:async';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _medicationService = MedicationService();
  final _notificationService = NotificationService();
  final _webNotificationService = WebNotificationService();
  late List<Medication> _medications;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    try {
      _medications = _medicationService.medications;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading medications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quick Schedule Reminder Section
                Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Schedule Reminder',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Schedule a one-time medication reminder for later today',
                        style: TextStyle(color: Colors.blue.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _scheduleQuickReminder,
                        icon: const Icon(Icons.access_time),
                        label: const Text('Schedule Reminder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Medications List
                Expanded(
                  child: _medications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medication,
                                size: 64.0,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                'No medications yet',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).disabledColor,
                                    ),
                              ),
                              const SizedBox(height: 8.0),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddMedicationScreen(),
                                    ),
                                  ).then((_) {
                                    _loadMedications();
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Medication'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMedications,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _medications.length,
                            itemBuilder: (context, index) {
                              final medication = _medications[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      title: Text(medication.name),
                                      subtitle: Text(medication.dosageText),
                                      leading: CircleAvatar(
                                        backgroundColor: medication.color,
                                        child: Text(
                                          medication.name[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.schedule),
                                        onPressed: () => _scheduleMedicationReminder(medication),
                                        tooltip: 'Schedule Reminder',
                                      ),
                                    ),
                                    const Divider(),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Scheduled Times',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8.0),
                                          Wrap(
                                            spacing: 8.0,
                                            children: medication.scheduledTimes.map((time) {
                                              return Chip(
                                                label: Text(time.format(context)),
                                                deleteIcon: const Icon(Icons.close),
                                                onDeleted: () async {
                                                  final updatedTimes =
                                                      List<TimeOfDay>.from(
                                                    medication.scheduledTimes,
                                                  )..remove(time);
                                                  await _medicationService
                                                      .updateMedication(
                                                    medication.copyWith(
                                                      scheduledTimes: updatedTimes,
                                                    ),
                                                  );
                                                  setState(() {
                                                    _medications =
                                                        _medicationService.medications;
                                                  });
                                                },
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 16.0),
                                          Text(
                                            'Active Days',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8.0),
                                          Wrap(
                                            spacing: 8.0,
                                            children: [
                                              'Mon',
                                              'Tue',
                                              'Wed',
                                              'Thu',
                                              'Fri',
                                              'Sat',
                                              'Sun',
                                            ].asMap().entries.map((entry) {
                                              final isActive =
                                                  medication.weekdays[entry.key];
                                              return FilterChip(
                                                label: Text(entry.value),
                                                selected: isActive,
                                                onSelected: (selected) async {
                                                  final updatedWeekdays =
                                                      List<bool>.from(
                                                    medication.weekdays,
                                                  )..[entry.key] = selected;
                                                  await _medicationService
                                                      .updateMedication(
                                                    medication.copyWith(
                                                      weekdays: updatedWeekdays,
                                                    ),
                                                  );
                                                  setState(() {
                                                    _medications =
                                                        _medicationService.medications;
                                                  });
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddReminderDialog(BuildContext context) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null && mounted) {
      final medication = await showDialog<Medication>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Medication'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                final medication = _medications[index];
                return ListTile(
                  title: Text(medication.name),
                  subtitle: Text(medication.dosageText),
                  onTap: () => Navigator.pop(context, medication),
                );
              },
            ),
          ),
        ),
      );

      if (medication != null) {
        final updatedTimes = List<TimeOfDay>.from(medication.scheduledTimes)
          ..add(selectedTime);
        await _medicationService.updateMedication(
          medication.copyWith(
            scheduledTimes: updatedTimes,
          ),
        );
        setState(() {
          _medications = _medicationService.medications;
        });
      }
    }
  }

  Future<void> _scheduleQuickReminder() async {
    if (kIsWeb) {
      try {
        // Show time picker for web users
        final now = DateTime.now();
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: now.hour,
            minute: now.minute + 5, // Default to 5 minutes from now
          ),
          helpText: 'Schedule Reminder Time',
        );
        
        if (selectedTime == null) return;
        
        // Calculate delay
        final scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        
        Duration delay = scheduledDateTime.difference(now);
        if (delay.isNegative) {
          delay = scheduledDateTime.add(const Duration(days: 1)).difference(now);
        }
        
        // Schedule the notification
        Timer(delay, () async {
          await _webNotificationService.showCustomNotification(
            title: '💊 Medication Reminder',
            body: 'It\'s time to take your medication!',
          );
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reminder scheduled for ${selectedTime.format(context)} (${delay.inMinutes} minutes from now)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to schedule reminder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Mobile implementation would use local notifications
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled reminders are currently available on web only'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _scheduleMedicationReminder(Medication medication) async {
    if (kIsWeb) {
      try {
        // Show time picker for specific medication
        final now = DateTime.now();
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: now.hour,
            minute: now.minute + 5,
          ),
          helpText: 'Schedule ${medication.name} Reminder',
        );
        
        if (selectedTime == null) return;
        
        // Calculate delay
        final scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        
        Duration delay = scheduledDateTime.difference(now);
        if (delay.isNegative) {
          delay = scheduledDateTime.add(const Duration(days: 1)).difference(now);
        }
        
        // Schedule the notification
        Timer(delay, () async {
          await _webNotificationService.sendMedicationReminder(
            medicationName: medication.name,
            dosage: medication.dosageText,
          );
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${medication.name} reminder scheduled for ${selectedTime.format(context)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to schedule ${medication.name} reminder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled reminders are currently available on web only'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
} 