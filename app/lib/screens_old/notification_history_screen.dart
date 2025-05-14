import 'package:flutter/material.dart';
import '../models/notification_record.dart';
import '../services/notification_history_service.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final _historyService = NotificationHistoryService();
  List<NotificationRecord> _history = [];
  bool _isLoading = true;
  int _selectedPeriod = 7; // Default to 7 days

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _historyService.getHistory(
        start: DateTime.now().subtract(Duration(days: _selectedPeriod)),
        end: DateTime.now(),
      );
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notification history: $e'),
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
        title: const Text('Notification History'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (days) {
              setState(() => _selectedPeriod = days);
              _loadHistory();
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear History'),
                  content: const Text(
                    'Are you sure you want to clear all notification history?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _historyService.clearHistory();
                await _loadHistory();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64.0,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'No notifications yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final record = _history[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            record.status == NotificationStatus.sent
                                ? Icons.notifications_active
                                : record.status == NotificationStatus.scheduled
                                    ? Icons.schedule
                                    : Icons.notifications_off,
                            color: record.status == NotificationStatus.sent
                                ? Colors.green
                                : record.status == NotificationStatus.scheduled
                                    ? Colors.blue
                                    : Colors.red,
                          ),
                          title: Text(record.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(record.description),
                              const SizedBox(height: 4.0),
                              Text(
                                '${record.timestamp.month}/${record.timestamp.day}/${record.timestamp.year} at '
                                '${record.timestamp.hour}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
} 