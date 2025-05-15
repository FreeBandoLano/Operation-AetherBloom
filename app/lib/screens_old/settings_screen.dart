import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../services/medication_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _medicationService = MedicationService();
  late NotificationSettings _settings;
  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _settings = _medicationService.settings;
  }

  Future<void> _updateSettings(NotificationSettings settings) async {
    await _medicationService.updateSettings(settings);
    setState(() {
      _settings = settings;
    });
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay initialTime) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
              dayPeriodTextColor: Theme.of(context).colorScheme.onSurface,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiet Hours',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16.0),
                  SwitchListTile(
                    title: const Text('Enable Quiet Hours'),
                    subtitle: const Text(
                      'No notifications will be sent during quiet hours',
                    ),
                    value: _settings.quietHoursEnabled,
                    onChanged: (value) {
                      _updateSettings(_settings.copyWith(
                        quietHoursEnabled: value,
                      ));
                    },
                  ),
                  if (_settings.quietHoursEnabled) ...[
                    ListTile(
                      title: const Text('Start Time'),
                      trailing: Text(
                        _settings.quietHoursStart.format(context),
                      ),
                      onTap: () async {
                        final time = await _selectTime(
                          context,
                          _settings.quietHoursStart,
                        );
                        if (time != null) {
                          _updateSettings(_settings.copyWith(
                            quietHoursStart: time,
                          ));
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('End Time'),
                      trailing: Text(
                        _settings.quietHoursEnd.format(context),
                      ),
                      onTap: () async {
                        final time = await _selectTime(
                          context,
                          _settings.quietHoursEnd,
                        );
                        if (time != null) {
                          _updateSettings(_settings.copyWith(
                            quietHoursEnd: time,
                          ));
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16.0),
                  SwitchListTile(
                    title: const Text('Group Notifications'),
                    subtitle: const Text(
                      'Combine multiple notifications into a single group',
                    ),
                    value: _settings.groupNotifications,
                    onChanged: (value) {
                      _updateSettings(_settings.copyWith(
                        groupNotifications: value,
                      ));
                    },
                  ),
                  ListTile(
                    title: const Text('Maximum Notifications per Hour'),
                    subtitle: Text(
                      '${_settings.maxNotificationsPerHour} notifications',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final value = await showDialog<int>(
                        context: context,
                        builder: (context) => NumberPickerDialog(
                          minValue: 1,
                          maxValue: 10,
                          initialValue: _settings.maxNotificationsPerHour,
                          title: 'Max Notifications per Hour',
                        ),
                      );
                      if (value != null) {
                        _updateSettings(_settings.copyWith(
                          maxNotificationsPerHour: value,
                        ));
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Minimum Time Between Notifications'),
                    subtitle: Text(
                      '${_settings.minTimeBetweenNotifications.inMinutes} minutes',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final value = await showDialog<int>(
                        context: context,
                        builder: (context) => NumberPickerDialog(
                          minValue: 1,
                          maxValue: 60,
                          initialValue:
                              _settings.minTimeBetweenNotifications.inMinutes,
                          title: 'Minutes Between Notifications',
                        ),
                      );
                      if (value != null) {
                        _updateSettings(_settings.copyWith(
                          minTimeBetweenNotifications: Duration(minutes: value),
                        ));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Days',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16.0),
                  ...List.generate(7, (index) {
                    return CheckboxListTile(
                      title: Text(_weekdays[index]),
                      value: _settings.enabledDays.containsKey(_weekdays[index]) 
                          ? _settings.enabledDays[_weekdays[index]]!
                          : true,
                      onChanged: (value) {
                        if (value != null) {
                          final newEnabledDays = Map<String, bool>.from(
                            _settings.enabledDays,
                          );
                          newEnabledDays[_weekdays[index]] = value;
                          _updateSettings(_settings.copyWith(
                            enabledDays: newEnabledDays,
                          ));
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NumberPickerDialog extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final int initialValue;
  final String title;

  const NumberPickerDialog({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.title,
  });

  @override
  State<NumberPickerDialog> createState() => _NumberPickerDialogState();
}

class _NumberPickerDialogState extends State<NumberPickerDialog> {
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _selectedValue > widget.minValue
                ? () {
                    setState(() {
                      _selectedValue--;
                    });
                  }
                : null,
          ),
          Text(
            _selectedValue.toString(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _selectedValue < widget.maxValue
                ? () {
                    setState(() {
                      _selectedValue++;
                    });
                  }
                : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedValue),
          child: const Text('OK'),
        ),
      ],
    );
  }
} 