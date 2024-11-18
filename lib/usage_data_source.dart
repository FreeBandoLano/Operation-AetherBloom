import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'usage_data.dart';

class UsageDataSource {
  final String _storageKey = 'usage_data';

  Future<void> saveUsageData(UsageData data) async {
    final prefs = await SharedPreferences.getInstance();
    final usageList = await getUsageData();
    usageList.add(data);

    final jsonData = usageList.map((data) => data.toJson()).toList();
    prefs.setString(_storageKey, jsonEncode(jsonData));
  }

  Future<List<UsageData>> getUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_storageKey);

    if (jsonData != null) {
      final decodedData = jsonDecode(jsonData) as List<dynamic>;
      return decodedData.map((json) => UsageData.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> clearUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
