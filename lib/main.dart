import 'package:flutter/material.dart';
import 'screens/analytics_screen.dart';
import 'screens/notification_history_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/usage_screen.dart';
import 'screens/doctor_portal_screen.dart';
import 'screens/notification_screen.dart';
import 'services/medication_service.dart';
import 'services/notification_service.dart';
import 'services/bluetooth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final medicationService = MedicationService();
  await medicationService.initialize();
  final notificationService = NotificationService();
  await notificationService.initialize();
  final bluetoothService = BluetoothService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AetherBloom',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AetherBloom'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AetherBloom',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Smart Medication Management',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FeatureCard(
                    title: 'Notifications',
                    description: 'Test and manage your medication notifications',
                    icon: Icons.notifications_active,
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    title: 'Analytics',
                    description: 'View your medication usage patterns',
                    icon: Icons.insert_chart,
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    title: 'Notification History',
                    description: 'View your past notifications',
                    icon: Icons.history,
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.teal],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    title: 'Usage',
                    description: 'Track your medication consumption',
                    icon: Icons.medication,
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.cyan],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UsageScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    title: 'Reminders',
                    description: 'Set up medication reminders',
                    icon: Icons.alarm,
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.redAccent],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RemindersScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    title: 'Smart Inhaler Connection',
                    description: 'Connect to your BLE 4.0 Smart Inhaler',
                    icon: Icons.bluetooth,
                    gradient: const LinearGradient(
                      colors: [Colors.indigo, Colors.blue],
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Smart Inhaler'),
                          content: const Text(
                            'Searching for nearby Smart Inhalers...\n\nMake sure your device is turned on and in pairing mode.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Connected to Smart Inhaler'),
                                  ),
                                );
                                Navigator.of(context).pop();
                              },
                              child: const Text('Connect'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    title: 'Doctor Portal',
                    description: 'Healthcare provider access',
                    icon: Icons.medical_services,
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.green],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorPortalScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32.0,
                color: Colors.white,
              ),
              const SizedBox(height: 16.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
