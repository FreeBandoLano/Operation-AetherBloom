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
import 'screens/fcm_registration_test_screen.dart';
import 'screens/notification_test_screen.dart';
import 'services/medication_service.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'services/web_notification_service.dart';

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
  
  // Initialize services
  try {
    print('🔔 Initializing notification service...');
    if (kIsWeb) {
      // Don't await web notification service - initialize it in the background
      // so it doesn't block the UI from loading
      final webNotificationService = WebNotificationService();
      webNotificationService.initialize().then((_) {
        print('🌐 Web Notification Service initialized successfully!');
      }).catchError((e) {
        print('❌ Web Notification Service initialization failed: $e');
      });
      print('🌐 Web Notification Service initialization started (non-blocking)');
    } else {
      final notificationService = NotificationService();
      await notificationService.initialize();
      print('🔔 Non-web NotificationService initialized successfully!');
    }
  } catch (e) {
    print('❌ Notification service initialization failed: $e');
  }
  
  // Initialize other services (temporarily commented out for Android testing)
  // final medicationService = MedicationService();
  // await medicationService.initialize();
  
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
              title: 'User Authentication',
              description: 'Login and manage your account',
              icon: Icons.person,
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
              title: 'Doctor Portal',
              description: 'Healthcare provider dashboard',
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
              title: 'Medication Reminders',
              description: 'Set up and manage your medication schedule',
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
              description: 'Track your inhaler usage and adherence',
              icon: Icons.insights,
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
              title: 'Analytics Dashboard',
              description: 'View insights about your medication patterns',
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
              title: 'Notification Test',
              description: 'Test notification system and scheduled reminders',
              icon: Icons.notification_add,
              gradient: const LinearGradient(
                colors: [Colors.teal, Colors.cyan],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationTestScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
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
