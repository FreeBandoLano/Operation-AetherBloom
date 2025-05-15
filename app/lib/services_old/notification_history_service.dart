import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_record.dart';

class NotificationHistoryService {
  static const String _storageKey = 'notification_history';
  static final NotificationHistoryService _instance = NotificationHistoryService._();
  
  factory NotificationHistoryService() => _instance;
  
  List<NotificationRecord> _history = [];
  
  NotificationHistoryService._();

  Future<void> initialize() async {
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString != null) {
      final jsonList = jsonDecode(jsonString) as List;
      _history = jsonList
          .map((json) => NotificationRecord.fromJson(json))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      _history.map((record) => record.toJson()).toList(),
    );
    await prefs.setString(_storageKey, jsonString);
  }

  Future<List<NotificationRecord>> getHistory({
    DateTime? start,
    DateTime? end,
  }) async {
    await _loadHistory();
    return _history.where((record) {
      if (start != null && record.timestamp.isBefore(start)) return false;
      if (end != null && record.timestamp.isAfter(end)) return false;
      return true;
    }).toList();
  }

  Future<void> addRecord(NotificationRecord record) async {
    _history.add(record);
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }
} 