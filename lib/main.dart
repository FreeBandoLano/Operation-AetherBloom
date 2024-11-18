import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'usage_screen.dart';
import 'analytics_screen.dart';
import 'reminders_screen.dart';
import 'usage_data.dart';
import 'dart:async';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // For JSON decoding

// Entry point of the application
void main() {
  runApp(ProjectAetherBloomApp());
}

// Root widget for the Project AetherBloom app
class ProjectAetherBloomApp extends StatelessWidget {
  const ProjectAetherBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project AetherBloom',
      theme: ThemeData(
        primarySwatch: Colors.pink, // Primary color for the app theme
      ),
      home: HomeScreen(), // Set HomeScreen as the initial screen
    );
  }
}

// Define the MethodChannel for Python integration
const MethodChannel _channel = MethodChannel('com.example.project_aetherbloom/data_channel');

// HomeScreen widget that displays the main navigation options
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Project AetherBloom'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavigationCard(
              label: 'Usage',
              icon: Icons.track_changes,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UsageScreen()),
                );
              },
            ),
            NavigationCard(
              label: 'Analytics',
              icon: Icons.analytics,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnalyticsScreen()),
                );
              },
            ),
            NavigationCard(
              label: 'Reminders',
              icon: Icons.alarm,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RemindersScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Custom reusable card widget for navigation within the app
class NavigationCard extends StatelessWidget {
  final String label; // Label for the card
  final IconData icon; // Icon for the card
  final VoidCallback onTap; // Action when the card is tapped

  const NavigationCard({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
      child: ListTile(
        leading: Icon(icon, color: Colors.pink),
        title: Text(label, style: const TextStyle(fontSize: 18)),
        onTap: onTap,
      ),
    );
  }
}

// Analytics screen that displays usage data analysis
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

  // Function to fetch data from Python
  Future<void> fetchDataFromPython() async {
    print("Attempting to fetch data from Python...");
    try {
      // Replace the MethodChannel call with an HTTP GET request
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/fetchData'));

      if (response.statusCode == 200) {
        // If the server responds successfully, decode the JSON data
        print("Data received from Python: ${response.body}");

        final Map<String, dynamic> data = jsonDecode(response.body);

        // Parse the data correctly
        final usageData = UsageData(
          inhalerUseCount: data['inhalerUseCount'],
          timestamp: DateTime.parse(data['timestamp']),
          notes: data['notes'],
        );

        setState(() {
          _usageDataList = [usageData];
        });

        print("Updated _usageDataList: $_usageDataList");
      } else {
        print("Failed to fetch data from Python, status code: ${response.statusCode}");
      }
    } on Exception catch (e) {
      print("Error fetching data: $e");
    }
  }


  @override
  void dispose() {
    _dataFetchTimer?.cancel(); // Cancel the timer on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("AnalyticsScreen build method called");
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
                  trailing: usage.notes.isNotEmpty
                      ? Text('Notes: ${usage.notes}')
                      : null,
                );
              },
            ),
    );
  }
}
