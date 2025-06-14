import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../setup/test_data_setup.dart';
import '../screens/notification_test_screen.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  String _statusMessage = 'Ready to test Firestore...';
  bool _isLoading = false;
  DocumentSnapshot? _currentUserProfile;
  List<Map<String, dynamic>> _recentUsageData = [];
  Map<String, dynamic>? _setupStatus;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading user profile...';
    });

    try {
      final profile = await FirestoreService.getCurrentUserProfile();
      setState(() {
        _currentUserProfile = profile;
        _statusMessage = profile != null 
            ? 'User profile loaded successfully!' 
            : 'No user profile found';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = 'No authenticated user found!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating user profile...';
    });

    try {
      await FirestoreService.createUserProfile(
        uid: user.uid,
        email: user.email!,
        userType: 'doctor',
        firstName: 'Dr. Test',
        lastName: 'User',
        specialization: 'Pulmonology',
        licenseNumber: 'TEST123456',
        hospitalAffiliation: 'AetherBloom Medical Center',
        phoneNumber: '+1-555-TEST',
      );

      await _loadUserProfile();
      setState(() {
        _statusMessage = 'User profile created successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSampleDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = 'No authenticated user found!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating sample device...';
    });

    try {
      String deviceId = await FirestoreService.registerIoTDevice(
        deviceName: 'AetherBloom Inhaler Pro',
        deviceType: 'inhaler',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        patientId: user.uid,
        firmwareVersion: '1.0.0',
        specifications: {
          'batteryCapacity': '3000mAh',
          'sensorTypes': ['pressure', 'temperature', 'humidity'],
          'connectivityType': 'Bluetooth LE',
        },
      );

      setState(() {
        _statusMessage = 'Sample device created with ID: $deviceId';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating device: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logSampleUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = 'No authenticated user found!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Logging sample usage...';
    });

    try {
      String usageId = await FirestoreService.logInhalerUsage(
        deviceId: 'sample-device-123',
        patientId: user.uid,
        usageTime: DateTime.now(),
        dosage: 100.0,
        medicationType: 'Albuterol',
        flowRate: 85.5,
        temperature: 22.5,
        humidity: 45.0,
        sensorData: {
          'peakFlow': 450,
          'usageDuration': 3.2,
          'qualityScore': 92,
        },
        notes: 'Sample inhaler usage for testing',
      );

      setState(() {
        _statusMessage = 'Sample usage logged with ID: $usageId';
      });
      
      await _loadRecentUsage();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error logging usage: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirestoreService.getPatientUsageHistory(
        patientId: user.uid,
        limit: 5,
      ).first;

      List<Map<String, dynamic>> usageList = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        usageList.add(data);
      }

      setState(() {
        _recentUsageData = usageList;
      });
    } catch (e) {
      print('Error loading recent usage: $e');
    }
  }

  Future<void> _sendTestNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = 'No authenticated user found!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Sending test notification...';
    });

    try {
      await FirestoreService.logNotification(
        userId: user.uid,
        type: 'reminder',
        title: 'Medication Reminder',
        message: 'Time to take your Albuterol inhaler',
        metadata: {
          'dosage': '100mg',
          'medicationType': 'Albuterol',
          'reminderType': 'scheduled',
        },
      );

      setState(() {
        _statusMessage = 'Test notification sent successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error sending notification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Set up test data using TestDataSetup class
  Future<void> _setupTestData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up test data...';
    });

    try {
      await TestDataSetup.initializeTestData();
      
      setState(() {
        _statusMessage = '✅ Test data setup complete!\n'
            '• Created doctor profile for current user\n'
            '• Added 3 test patients: John Doe, Jane Smith, Mike Johnson\n'
            '• Generated 7 days of inhaler usage data\n'
            '• Set up doctor-patient relationships\n\n'
            'You can now go to the Doctor Portal and see real patient data!';
      });
      
      // Reload user profile to reflect changes
      await _loadUserProfile();
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error setting up test data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Test basic usage data (no composite index needed)
  Future<void> _testBasicUsageData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing basic usage data (no index required)...';
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _statusMessage = '❌ Must be logged in to test usage data';
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> usageData = await FirestoreService.getBasicUsageData(
        patientId: currentUser.uid,
      );

      setState(() {
        _statusMessage = '✅ Basic usage data test successful!\n'
            'Total usages: ${usageData['totalUsages']}\n'
            'Total dosage: ${usageData['totalDosage']}\n'
            'Found ${usageData['usageList'].length} usage records';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error in basic usage data test: $e';
        _isLoading = false;
      });
    }
  }

  /// Test simple analytics (should work with current index)
  Future<void> _testSimpleAnalytics() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing simple analytics...';
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _statusMessage = '❌ Must be logged in to test analytics';
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> analytics = await FirestoreService.getBasicUsageData(
        patientId: currentUser.uid,
      );

      setState(() {
        _statusMessage = '✅ Simple analytics test successful!\n'
            'Recent usages: ${analytics['totalUsages']}\n'
            'Total dosage: ${analytics['totalDosage']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error in simple analytics test: $e';
        _isLoading = false;
      });
    }
  }

  /// Test complex analytics (requires composite index)

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Database Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('User: ${user?.email ?? 'Not authenticated'}'),
                    Text('UID: ${user?.uid ?? 'N/A'}'),
                    const SizedBox(height: 8),
                    if (_currentUserProfile != null) ...[
                      const Text('Profile Status: ✅ Profile exists'),
                      Text('User Type: ${(_currentUserProfile!.data() as Map<String, dynamic>)['userType'] ?? 'Unknown'}'),
                      Text('Name: ${(_currentUserProfile!.data() as Map<String, dynamic>)['firstName'] ?? ''} ${(_currentUserProfile!.data() as Map<String, dynamic>)['lastName'] ?? ''}'),
                    ] else
                      const Text('Profile Status: ❌ No profile found'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status Message
            Card(
              color: _isLoading ? Colors.orange.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_isLoading) const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: _isLoading ? Colors.orange.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Buttons
            Text(
              'Database Operations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _TestButton(
              title: 'Create User Profile',
              subtitle: 'Create a doctor profile in Firestore',
              icon: Icons.person_add,
              onPressed: _isLoading ? null : _createUserProfile,
              enabled: user != null && _currentUserProfile == null,
            ),
            
            _TestButton(
              title: 'Register Sample Device',
              subtitle: 'Add an IoT inhaler device',
              icon: Icons.devices,
              onPressed: _isLoading ? null : _createSampleDevice,
              enabled: user != null,
            ),
            
            _TestButton(
              title: 'Log Usage Data',
              subtitle: 'Record inhaler usage event',
              icon: Icons.medical_information,
              onPressed: _isLoading ? null : _logSampleUsage,
              enabled: user != null,
            ),
            
            _TestButton(
              title: 'Send Test Notification',
              subtitle: 'Log notification to history',
              icon: Icons.notifications,
              onPressed: _isLoading ? null : _sendTestNotification,
              enabled: user != null,
            ),
            
            _TestButton(
              title: 'Test Basic Usage Data',
              subtitle: 'Test basic usage data (no index required)',
              icon: Icons.analytics,
              onPressed: _isLoading ? null : _testBasicUsageData,
              enabled: user != null,
            ),
            
            _TestButton(
              title: 'Test Simple Analytics',
              subtitle: 'Test simple usage analytics',
              icon: Icons.analytics,
              onPressed: _isLoading ? null : _testSimpleAnalytics,
              enabled: user != null,
            ),
            
            _TestButton(
              title: 'Setup Test Data',
              subtitle: 'Create test users, patients, and usage data',
              icon: Icons.build,
              onPressed: _isLoading ? null : _setupTestData,
              enabled: user != null,
            ),
            
            _TestButton(
              title: '🔔 Test Notifications',
              subtitle: 'Test notification system and reminders',
              icon: Icons.notifications,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationTestScreen(),
                  ),
                );
              },
              enabled: true,
            ),
            
            const SizedBox(height: 24),
            
            // Recent Usage Data
            if (_recentUsageData.isNotEmpty) ...[
              Text(
                'Recent Usage Data',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...(_recentUsageData.map((usage) => Card(
                child: ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: Text(usage['medicationType'] ?? 'Unknown'),
                  subtitle: Text('Dosage: ${usage['dosage']}mg'),
                  trailing: Text(
                    usage['usageTime'] != null 
                        ? (usage['usageTime'] as Timestamp).toDate().toString().substring(0, 16)
                        : 'Unknown time',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ))),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;

  const _TestButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
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