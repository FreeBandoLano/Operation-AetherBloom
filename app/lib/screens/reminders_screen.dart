import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/reminder.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../usage_data.dart';
import '../usage_data_source.dart';
import 'add_medication_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _medicationService = MedicationService();
  final _notificationService = NotificationService();
  final _apiService = ApiService();
  final _usageDataSource = UsageDataSource();
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
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Quick Log',
            onPressed: () => _showQuickLogDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medications.isEmpty
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'quickLog',
            onPressed: () => _showQuickLogDialog(context),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.checklist),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'addReminder',
            onPressed: () => _showAddReminderDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
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

  Future<void> _showQuickLogDialog(BuildContext context) async {
    int usageCount = 1;
    String notes = '';
    Medication? selectedMedication;
    
    if (_medications.isNotEmpty) {
      selectedMedication = _medications.first;
    }
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Quick Log Inhaler Usage'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: usageCount > 1
                          ? () => setState(() => usageCount--)
                          : null,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        usageCount.toString(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => usageCount++),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_medications.isNotEmpty) ...[
                  const Text('Medication:'),
                  DropdownButton<Medication>(
                    value: selectedMedication,
                    isExpanded: true,
                    items: _medications.map((med) {
                      return DropdownMenuItem<Medication>(
                        value: med,
                        child: Text(med.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedMedication = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) => notes = value,
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (_) {},
                    ),
                    const Text('Share with website dashboard'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveQuickLog(usageCount, notes, selectedMedication);
              },
              child: const Text('Log Usage'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveQuickLog(int count, String notes, Medication? medication) async {
    String fullNotes = notes;
    if (medication != null) {
      fullNotes = '${medication.name}: $notes';
    }
    
    final data = UsageData(
      timestamp: DateTime.now(),
      inhalerUseCount: count,
      notes: fullNotes,
    );
    
    await _usageDataSource.saveUsageData(data);
    
    final success = await _apiService.sendUsageData(count, fullNotes);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Usage logged and shared with website!' 
                : 'Usage logged, but sharing with website failed',
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }
} 