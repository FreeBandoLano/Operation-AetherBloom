import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'usage_data.dart';

// Method channel for Python integration
const MethodChannel _channel = MethodChannel('com.example.project_aetherbloom/data_channel');

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<UsageData> _usageDataList = []; // Store usage data for analytics
  Timer? _dataFetchTimer; // Timer to periodically fetch data

  @override
  void initState() {
    super.initState();
    _startDataFetchLoop(); // Start periodic data fetching
  }

  // Start periodic data fetch from the Python server
  void _startDataFetchLoop() {
    _dataFetchTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchDataFromPython();
    });
  }

  // Function to fetch data from the Python server
  Future<void> fetchDataFromPython() async {
    print("Attempting to fetch data from Python...");
    try {
      final String result = await _channel.invokeMethod('fetchData');
      print("Data received from Python: $result"); // Log received data

      // Parse the JSON data
      final Map<String, dynamic> data = jsonDecode(result);
      setState(() {
        _usageDataList = [
          UsageData(
            inhalerUseCount: data['inhalerUseCount'],
            timestamp: data['timestamp'],
            notes: data['notes'],
          ),
        ];
      });
      print("Updated _usageDataList: $_usageDataList"); // Confirm list update
    } on PlatformException catch (e) {
      print("Failed to get data: '${e.message}'");
    }
  }

  @override
  void dispose() {
    _dataFetchTimer?.cancel(); // Cancel the timer on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("AnalyticsScreen build method called"); // Log build calls
    return Scaffold(
      appBar: AppBar(title: Text('Analytics')),
      body: _usageDataList.isEmpty
          ? Center(child: Text('No data available'))
          : ListView.builder(
              itemCount: _usageDataList.length,
              itemBuilder: (context, index) {
                final usage = _usageDataList[index];
                return ListTile(
                  title: Text('Inhaler Usage Count: ${usage.inhalerUseCount}'),
                  subtitle: Text('Date: ${usage.timestamp}'),
                  trailing: usage.notes.isNotEmpty ? Text('Notes: ${usage.notes}') : null,
                );
              },
            ),
    );
  }
}
