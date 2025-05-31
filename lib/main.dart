import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb and defaultTargetPlatform
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'test_firebase_auth.dart';
import 'screens/analytics_screen.dart';
import 'screens/notification_history_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/usage_screen.dart';
import 'screens/doctor_portal_screen.dart';
import 'screens/firestore_test_screen.dart';
import 'services/medication_service.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (web and mobile platforms)
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
    try {
      print('🔥 Starting Firebase initialization...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('🔥 Firebase initialized successfully!');
      print('🔥 Ready to test authentication!');
      
      // Initialize Firestore sample data if needed
      print('📊 Initializing Firestore database...');
      // Note: This will only create sample data if user is authenticated and doesn't exist
      // FirestoreService.initializeSampleData();
      print('📊 Firestore database ready!');
      
      if (kIsWeb) {
        print('🌐 Running on web - Firebase auth fully supported!');
      }
    } catch (e, stackTrace) {
      print('❌ Firebase initialization failed: $e');
      print('❌ Stack trace: $stackTrace');
    }
  } else {
    print('⚠️ Firebase skipped on Windows (C++ SDK build issues)');
    print('🚀 Use: flutter run -d edge (for web testing)');
    print('🤖 Or: flutter run -d android (for Android testing)');
  }
  
  // Initialize services (temporarily commented out for Android testing)
  // final medicationService = MedicationService();
  // final notificationService = NotificationService();
  // await medicationService.initialize();
  // await notificationService.initialize();
  
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AetherBloom'),
        actions: [
          // Firebase test (works on web/Android)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirebaseAuthTest(),
                ),
              );
            },
            tooltip: 'Firebase Test',
          ),
          IconButton(
            icon: const Icon(Icons.medical_services),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorPortalScreen(),
                ),
              );
            },
            tooltip: 'Doctor Portal',
          ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Firebase test (works on web/Android)
            _FeatureCard(
              title: 'Firebase Test',
              description: 'Test Firebase authentication (web/Android only)',
              icon: Icons.bug_report,
              gradient: const LinearGradient(
                colors: [Colors.deepOrange, Colors.orange],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirebaseAuthTest(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            _FeatureCard(
              title: 'Firestore Database Test',
              description: 'Test database operations with real-time data (web/Android only)',
              icon: Icons.storage,
              gradient: const LinearGradient(
                colors: [Colors.indigo, Colors.indigoAccent],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirestoreTestScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            _FeatureCard(
              title: 'Doctor Portal',
              description: 'Access healthcare provider dashboard',
              icon: Icons.local_hospital,
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
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
            const SizedBox(height: 16.0),
            _FeatureCard(
              title: 'Reminders',
              description: 'Set up and manage your medication reminders',
              icon: Icons.alarm,
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent],
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
            const SizedBox(height: 16.0),
            _FeatureCard(
              title: 'Usage Tracking',
              description: 'Track your medication usage and adherence',
              icon: Icons.calendar_today,
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.lightGreen],
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
            const SizedBox(height: 16.0),
            _FeatureCard(
              title: 'Analytics',
              description: 'View insights about your medication usage',
              icon: Icons.bar_chart,
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.purpleAccent],
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
            const SizedBox(height: 16.0),
            _FeatureCard(
              title: 'Notification History',
              description: 'View past notifications and reminders',
              icon: Icons.notifications,
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.amber],
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
            const SizedBox(height: 16.0),
            // Bluetooth functionality will be added later in Phase 3
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.bluetooth_disabled, size: 32.0, color: Colors.grey),
                  SizedBox(height: 8.0),
                  Text(
                    'Bluetooth Device Connection',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'Available in Phase 3 (Hardware Integration)',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
