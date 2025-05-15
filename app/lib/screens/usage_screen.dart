import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  final _medicationService = MedicationService();
  late List<Medication> _medications;
  int _selectedPeriod = 7; // Default to 7 days

  @override
  void initState() {
    super.initState();
    _medications = _medicationService.medications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage History'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (days) {
              setState(() => _selectedPeriod = days);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 7,
                child: Text('Last 7 Days'),
              ),
              const PopupMenuItem(
                value: 30,
                child: Text('Last 30 Days'),
              ),
              const PopupMenuItem(
                value: 90,
                child: Text('Last 90 Days'),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final medication = _medications[index];
          final history = _medicationService.getAdherenceHistory(
            medication.id,
            start: DateTime.now().subtract(Duration(days: _selectedPeriod)),
            end: DateTime.now(),
          );

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
                        'Usage History',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8.0),
                      if (history.isEmpty)
                        const Text('No usage history for this period')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final entry = history[index];
                            return ListTile(
                              leading: Icon(
                                entry.value
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: entry.value
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(
                                entry.value ? 'Taken' : 'Missed',
                              ),
                              subtitle: Text(
                                '${entry.key.month}/${entry.key.day}/${entry.key.year} at '
                                '${entry.key.hour}:${entry.key.minute.toString().padLeft(2, '0')}',
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 