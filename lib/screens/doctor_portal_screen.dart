import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/bluetooth_service.dart';
import '../services/firestore_service.dart';
import '../models/notification_record.dart';
import '../services/notification_history_service.dart';
import 'patient_details_screen.dart'; // Added import

class DoctorPortalScreen extends StatefulWidget {
  const DoctorPortalScreen({Key? key}) : super(key: key);

  @override
  _DoctorPortalScreenState createState() => _DoctorPortalScreenState();
}

class _DoctorPortalScreenState extends State<DoctorPortalScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  late TabController _tabController;
  
  final BluetoothService _bluetoothService = BluetoothService();
  final NotificationHistoryService _notificationHistoryService = NotificationHistoryService();
  
  List<NotificationRecord> _notificationHistory = [];
  bool _showConnectionStatus = false;
  StreamSubscription<User?>? _authStateSubscription;
  
  // Real-time Firestore data
  Stream<QuerySnapshot>? _patientsStream;
  Stream<QuerySnapshot>? _usageDataStream;
  DocumentSnapshot? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotificationHistory();

    // Listen to auth state changes
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) { // Ensure the widget is still in the tree
        setState(() {
          _isLoggedIn = user != null;
          if (user == null) {
            _emailController.clear();
            _passwordController.clear();
            _tabController.index = 0;
            _patientsStream = null;
            _usageDataStream = null;
            _currentUserProfile = null;
          } else {
            _initializeUserData(user);
          }
        });
      }
    });
  }

  /// Initialize user data and streams when user logs in
  Future<void> _initializeUserData(User user) async {
    try {
      print('🔄 Initializing user data for: ${user.uid}');
      
      // Load user profile
      _currentUserProfile = await FirestoreService.getUserProfile(user.uid);
      
      print('👤 User profile loaded: ${_currentUserProfile?.data()}');
      
      // Initialize patients stream - for doctors, show their patients
      // For patients, show their own data
      if (_isDoctor()) {
        print('👨‍⚕️ Setting up doctor view - showing patients assigned to: ${user.uid}');
        _patientsStream = FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: 'patient')
            .where('assignedDoctorId', isEqualTo: user.uid)
            .where('isActive', isEqualTo: true) // Only show active patients
            .snapshots();
      } else {
        print('🤒 Setting up patient view - showing own profile for: ${user.uid}');
        // Patient view - just show their own profile
        _patientsStream = FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .snapshots();
      }
      
      // Initialize usage data stream using basic query without orderBy to avoid index requirement
      if (_isDoctor()) {
        print('👨‍⚕️ Setting up doctor usage data stream');
        // Doctor sees all usage data (no doctorId field exists, so get all and filter client-side if needed)
        _usageDataStream = FirebaseFirestore.instance
            .collection('inhaler_usage')
            .limit(100)
            .snapshots();
      } else {
        print('🤒 Setting up patient usage data stream for: ${user.uid}');
        // Patient sees only their own usage data (basic query without orderBy)
        _usageDataStream = FirebaseFirestore.instance
            .collection('inhaler_usage')
            .where('patientId', isEqualTo: user.uid)
            .limit(50)
            .snapshots();
      }
      
      setState(() {});
      
      print('✅ User data initialization complete');
      
    } catch (e) {
      print('❌ Error initializing user data: $e');
    }
  }

  /// Check if current user is a doctor
  bool _isDoctor() {
    // For demo purposes, if user profile is null but user is logged in, assume doctor
    if (_currentUserProfile?.data() != null) {
      Map<String, dynamic> data = _currentUserProfile!.data() as Map<String, dynamic>;
      return data['userType'] == 'doctor';
    }
    // Default to doctor view for demo purposes when profile is null
    return true; 
  }

  Future<void> _loadNotificationHistory() async {
    var history = await _notificationHistoryService.getHistory();
    setState(() {
      _notificationHistory = history;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    _authStateSubscription?.cancel(); // Cancel subscription on dispose
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // If login is successful, UserCredential object is returned
        if (userCredential.user != null) {
          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is not valid.';
        } else if (e.code == 'too-many-requests') {
          message = 'Too many login attempts. Please try again later.';
        } else if (e.code == 'network-request-failed') {
          message = 'Network error. Please check your connection.';
        } else {
          message = 'An unexpected error occurred. Please try again.';
        }
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      } catch (e, s) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _isLoading = false;
        });
        debugPrint('*****************************************************');
        debugPrint('********** LOGIN ERROR CAUGHT ***********************');
        debugPrint('Login Error Object: ${e.toString()}');
        debugPrint('Login Stack Trace: ${s.toString()}');
        debugPrint('*****************************************************');
      }
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          message = 'An account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is not valid.';
        } else {
          message = 'An unexpected error occurred during sign-up.';
        }
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      } catch (e, s) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _isLoading = false;
        });
        debugPrint('*****************************************************');
        debugPrint('********** SIGNUP ERROR CAUGHT **********************');
        debugPrint('Signup Error Object: ${e.toString()}');
        debugPrint('Signup Stack Trace: ${s.toString()}');
        debugPrint('*****************************************************');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoggedIn ? 'Doctor Portal' : 'Doctor Login'),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              tooltip: 'Logout',
            ),
        ],
        bottom: _isLoggedIn
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                  Tab(text: 'Patients', icon: Icon(Icons.people)),
                ],
              )
            : null,
      ),
      body: _isLoggedIn ? _buildPortalContent() : _buildLoginForm(),
      floatingActionButton: _isLoggedIn && _isDoctor() 
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: _generateTestData,
                heroTag: "generateTestData",
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                mini: true,
                child: const Icon(Icons.science),
                tooltip: 'Generate Test Data',
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                onPressed: _showAddPatientDialog,
                heroTag: "addPatient",
                icon: const Icon(Icons.person_add),
                label: const Text('Add Patient'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ],
          )
        : null,
    );
  }

  Widget _buildLoginForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.health_and_safety,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                'Healthcare Provider Portal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('LOG IN', style: TextStyle(fontSize: 16)),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Would navigate to password reset
                },
                child: const Text('Forgot password?'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to a sign-up screen or show a sign-up dialog
                  _signUp(); // Placeholder for now
                },
                child: const Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortalContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildPatientsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    if (_usageDataStream == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading usage data...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-time usage summary card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Inhaler Usage Analytics',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: _usageDataStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Live Data',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200, // Reduced from 250 to 200
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _usageDataStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(height: 8),
                                Text('Error: ${snapshot.error}'),
                              ],
                            ),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'No usage data yet',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Data will appear here once patients start using their inhalers',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        // Process the usage data for the chart
                        List<Map<String, dynamic>> weeklyData = _processUsageDataForChart(snapshot.data!.docs);
                        
                        return BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxUsageForChart(weeklyData),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (BarChartGroupData group) => Colors.blueGrey.withOpacity(0.8),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  String dayName = weeklyData[groupIndex]['dayName'];
                                  int count = weeklyData[groupIndex]['count'];
                                  return BarTooltipItem(
                                    '$dayName\n$count usages',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    if (value.toInt() < weeklyData.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Text(
                                          weeklyData[value.toInt()]['dayName'],
                                          style: const TextStyle(
                                            color: Colors.blueGrey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        color: Colors.blueGrey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                  reservedSize: 24,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: false,
                            ),
                            barGroups: weeklyData.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, dynamic> data = entry.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: data['count'].toDouble(),
                                    color: _getBarColor(data['count']),
                                    width: 20, // Reduced from 22 to 20
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.3),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Real-time statistics cards
          StreamBuilder<QuerySnapshot>(
            stream: _usageDataStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }

              Map<String, dynamic> stats = _calculateUsageStats(snapshot.data!.docs);
              
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Today\'s Usage',
                      '${stats['todayUsage']}',
                      Icons.today,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'This Week',
                      '${stats['weekUsage']}',
                      Icons.date_range,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Patients',
                      '${stats['activePatients']}',
                      Icons.people,
                      Colors.orange,
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Recent activity
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Inhaler Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250, // Fixed height instead of Expanded
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _usageDataStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No recent activity',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // Show the most recent 5 usage records
                        List<QueryDocumentSnapshot> recentUsage = snapshot.data!.docs.take(5).toList();
                        
                        return ListView.builder(
                          itemCount: recentUsage.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> usageData = recentUsage[index].data() as Map<String, dynamic>;
                            DateTime usageTime = (usageData['usageTime'] as Timestamp).toDate();
                            
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(
                                  Icons.air,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              title: Text(
                                'Patient: ${usageData['patientId']?.toString().substring(0, 8) ?? 'Unknown'}...',
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                '${usageData['dosageAmount'] ?? 'Unknown'} mg • ${_formatDateTime(usageTime)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                _formatLastUsage(usageTime),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Process usage data for weekly chart
  List<Map<String, dynamic>> _processUsageDataForChart(List<QueryDocumentSnapshot> docs) {
    DateTime now = DateTime.now();
    List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Initialize data for the last 7 days
    List<Map<String, dynamic>> weeklyData = [];
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      weeklyData.add({
        'date': day,
        'dayName': dayNames[(day.weekday - 1) % 7],
        'count': 0,
      });
    }
    
    // Count usage for each day
    for (var doc in docs) {
      try {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime? usageTime;
        
        // Handle different timestamp field names and null values
        if (data['usageTime'] != null) {
          usageTime = (data['usageTime'] as Timestamp).toDate();
        } else if (data['timestamp'] != null) {
          usageTime = (data['timestamp'] as Timestamp).toDate();
        } else {
          continue; // Skip records without valid timestamps
        }
        
        for (var dayData in weeklyData) {
          DateTime dayDate = dayData['date'];
          if (usageTime.year == dayDate.year &&
              usageTime.month == dayDate.month &&
              usageTime.day == dayDate.day) {
            dayData['count']++;
            break;
          }
        }
      } catch (e) {
        print('Error processing usage data: $e');
        continue; // Skip problematic records
      }
    }
    
    return weeklyData;
  }

  /// Get maximum usage count for chart scaling
  double _getMaxUsageForChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 10;
    int maxUsage = data.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b);
    return (maxUsage + 2).toDouble(); // Add some padding
  }

  /// Get bar color based on usage count
  Color _getBarColor(int count) {
    if (count == 0) return Colors.grey.shade300;
    if (count <= 2) return Colors.orange;
    if (count <= 5) return Colors.blue;
    return Colors.green;
  }

  /// Calculate usage statistics
  Map<String, dynamic> _calculateUsageStats(List<QueryDocumentSnapshot> docs) {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime startOfWeek = now.subtract(Duration(days: 7));
    
    int todayUsage = 0;
    int weekUsage = 0;
    Set<String> activePatients = {};
    
    for (var doc in docs) {
      try {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime? usageTime;
        
        // Handle different timestamp field names and null values
        if (data['usageTime'] != null) {
          usageTime = (data['usageTime'] as Timestamp).toDate();
        } else if (data['timestamp'] != null) {
          usageTime = (data['timestamp'] as Timestamp).toDate();
        } else {
          continue; // Skip records without valid timestamps
        }
        
        String patientId = data['patientId'] ?? '';
        
        if (patientId.isNotEmpty) {
          activePatients.add(patientId);
        }
        
        if (usageTime.isAfter(startOfDay)) {
          todayUsage++;
        }
        
        if (usageTime.isAfter(startOfWeek)) {
          weekUsage++;
        }
      } catch (e) {
        print('Error processing usage stats: $e');
        continue; // Skip problematic records
      }
    }
    
    return {
      'todayUsage': todayUsage,
      'weekUsage': weekUsage,
      'activePatients': activePatients.length,
    };
  }

  /// Build a statistics card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsTab() {
    if (_patientsStream == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading patients...'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Patients',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // TODO: Implement patient search filtering
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showAddPatientDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Patient'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _patientsStream,
              builder: (context, snapshot) {
                print('📊 Patients stream state: ${snapshot.connectionState}');
                print('📊 Has data: ${snapshot.hasData}');
                if (snapshot.hasData) {
                  print('📊 Number of patients: ${snapshot.data!.docs.length}');
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    print('👤 Patient: ${data['name']} (${data['email']}) - Doctor: ${data['assignedDoctorId']}');
                  }
                }
                
                if (snapshot.hasError) {
                  print('❌ Patients stream error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading patients: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Trigger rebuild
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _isDoctor() ? 'No patients assigned yet' : 'No patient data found',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isDoctor() 
                              ? 'Patients you add will appear here automatically' 
                              : 'Your patient profile will appear here',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        if (_isDoctor())
                          ElevatedButton.icon(
                            onPressed: _showAddPatientDialog,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add First Patient'),
                          ),
                      ],
                    ),
                  );
                }

                final patients = snapshot.data!.docs;
                
                return ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patientDoc = patients[index];
                    final patientData = patientDoc.data() as Map<String, dynamic>;
                    
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _getPatientStats(patientDoc.id),
                      builder: (context, statsSnapshot) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getPatientStatusColor(statsSnapshot.data),
                              radius: 28,
                              child: Text(
                                _getPatientInitials(patientData['firstName'], patientData['lastName']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${patientData['firstName'] ?? 'Unknown'} ${patientData['lastName'] ?? 'Patient'}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Email: ${patientData['email'] ?? 'Not provided'}'),
                                const SizedBox(height: 2),
                                if (patientData['dateOfBirth'] != null)
                                  Text('Age: ${_calculateAge(patientData['dateOfBirth'])} years'),
                                const SizedBox(height: 2),
                                if (statsSnapshot.hasData && statsSnapshot.data!['lastUsage'] != null)
                                  Text(
                                    'Last usage: ${_formatLastUsage(statsSnapshot.data!['lastUsage'])}',
                                    style: TextStyle(
                                      color: _getLastUsageColor(statsSnapshot.data!['lastUsage']),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (statsSnapshot.hasData) ...[
                                  Text(
                                    'Usage Today',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getUsageColor(statsSnapshot.data!['todayUsage'] ?? 0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${statsSnapshot.data!['todayUsage'] ?? 0}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                            onTap: () => _viewPatientDetails(patientDoc.id, patientData),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Get patient initials for avatar
  String _getPatientInitials(String? firstName, String? lastName) {
    String initials = '';
    if (firstName != null && firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName != null && lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    return initials.isEmpty ? '??' : initials;
  }

  /// Calculate age from date of birth
  int _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 0;
    
    DateTime birthDate;
    if (dateOfBirth is Timestamp) {
      birthDate = dateOfBirth.toDate();
    } else if (dateOfBirth is String) {
      birthDate = DateTime.tryParse(dateOfBirth) ?? DateTime.now();
    } else {
      return 0;
    }
    
    DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Get patient statistics (usage data) - simplified to avoid composite indexes
  Future<Map<String, dynamic>> _getPatientStats(String patientId) async {
    try {
      // Use simple query without date filters to avoid requiring indexes
      QuerySnapshot allUsage = await FirebaseFirestore.instance
          .collection('inhaler_usage')
          .where('patientId', isEqualTo: patientId)
          .limit(20) // Get recent records without ordering to avoid index requirement
          .get();

      // Process data on client side
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      
      int todayCount = 0;
      DateTime? lastUsage;
      
      for (var doc in allUsage.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['usageTime'] != null) {
          DateTime usageTime = (data['usageTime'] as Timestamp).toDate();
          
          // Count today's usage
          if (usageTime.isAfter(startOfDay)) {
            todayCount++;
          }
          
          // Track most recent usage
          if (lastUsage == null || usageTime.isAfter(lastUsage)) {
            lastUsage = usageTime;
          }
        }
      }

      return {
        'todayUsage': todayCount,
        'lastUsage': lastUsage,
      };
    } catch (e) {
      print('Error getting patient stats: $e');
      return {'todayUsage': 0, 'lastUsage': null};
    }
  }

  /// Get color based on patient status
  Color _getPatientStatusColor(Map<String, dynamic>? stats) {
    if (stats == null) return Colors.grey;
    
    DateTime? lastUsage = stats['lastUsage'];
    if (lastUsage == null) return Colors.red;
    
    int hoursSinceLastUsage = DateTime.now().difference(lastUsage).inHours;
    
    if (hoursSinceLastUsage < 24) return Colors.green;
    if (hoursSinceLastUsage < 48) return Colors.orange;
    return Colors.red;
  }

  /// Get color for usage count
  Color _getUsageColor(int usageCount) {
    if (usageCount == 0) return Colors.red;
    if (usageCount < 3) return Colors.orange;
    return Colors.green;
  }

  /// Get color for last usage text
  Color _getLastUsageColor(DateTime? lastUsage) {
    if (lastUsage == null) return Colors.red;
    
    int hoursSinceLastUsage = DateTime.now().difference(lastUsage).inHours;
    if (hoursSinceLastUsage < 24) return Colors.green;
    if (hoursSinceLastUsage < 48) return Colors.orange;
    return Colors.red;
  }

  /// Format last usage time
  String _formatLastUsage(DateTime? lastUsage) {
    if (lastUsage == null) return 'Never';
    
    Duration difference = DateTime.now().difference(lastUsage);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Show add patient dialog
  Future<void> _showAddPatientDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final ageController = TextEditingController();
    final conditionController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Patient'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        final age = int.tryParse(value!);
                        if (age == null || age < 1 || age > 120) {
                          return 'Please enter a valid age (1-120)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: conditionController,
                    decoration: const InputDecoration(
                      labelText: 'Medical Condition',
                      prefixIcon: Icon(Icons.medical_services),
                      hintText: 'e.g., Asthma, COPD',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await _addNewPatient(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    age: int.tryParse(ageController.text.trim()),
                    condition: conditionController.text.trim(),
                  );
                  
                  if (success && mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Patient added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add Patient'),
            ),
          ],
        );
      },
    );
  }

  /// Add a new patient to the database
  Future<bool> _addNewPatient({
    required String name,
    required String email,
    String? phone,
    int? age,
    String? condition,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No current user found when adding patient');
        return false;
      }

      print('👨‍⚕️ Adding patient with doctor ID: ${currentUser.uid}');

      // Generate a unique patient ID
      final patientId = 'patient_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create patient document with all required fields
      final patientData = {
        'uid': patientId,
        'firstName': name.split(' ').first, // Split name into first and last
        'lastName': name.split(' ').length > 1 ? name.split(' ').skip(1).join(' ') : '',
        'name': name, // Keep full name for backwards compatibility
        'email': email,
        'phone': phone ?? '',
        'age': age,
        'dateOfBirth': age != null ? Timestamp.fromDate(DateTime.now().subtract(Duration(days: age * 365))) : null,
        'medicalCondition': condition ?? '',
        'userType': 'patient',
        'assignedDoctorId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'doctor_portal',
        'isActive': true,
      };

      print('🏥 Creating patient document with data: $patientData');
      
      // Create patient document
      await FirebaseFirestore.instance.collection('users').doc(patientId).set(patientData);

      print('✅ Patient document created successfully with ID: $patientId');

      // Add some sample inhaler usage data for demo purposes
      await _createSampleUsageData(patientId, name);

      print('💨 Sample usage data created for patient: $patientId');

      // Force refresh the patients stream
      if (mounted) {
        setState(() {
          // This will trigger a rebuild and refresh the stream
        });
      }

      return true;
    } catch (e) {
      print('❌ Error adding patient: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding patient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Create sample usage data for new patient (for demo purposes)
  Future<void> _createSampleUsageData(String patientId, String patientName) async {
    try {
      final now = DateTime.now();
      
      // Create 5 sample usage records over the past week
      for (int i = 0; i < 5; i++) {
        final usageTime = now.subtract(Duration(days: i + 1, hours: (i * 3) % 24));
        
        await FirebaseFirestore.instance.collection('inhaler_usage').add({
          'patientId': patientId,
          'patientName': patientName,
          'usageTime': Timestamp.fromDate(usageTime),
          'deviceId': 'demo_inhaler_001',
          'medicationType': i % 2 == 0 ? 'Albuterol' : 'Budesonide',
          'dosageAmount': i % 2 == 0 ? 90.0 : 200.0,
          'technique': ['Excellent', 'Good', 'Fair'][i % 3],
          'flowRate': 'Normal',
          'createdBy': 'doctor_portal_demo',
          'notes': 'Sample usage data for demonstration',
        });
      }
    } catch (e) {
      print('Error creating sample usage data: $e');
    }
  }

  /// View patient details
  void _viewPatientDetails(String patientId, Map<String, dynamic> patientData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(
          patientId: patientId,
          patientData: patientData,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _generateTestData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No current user found for test data generation');
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating test data...'),
                ],
              ),
            ),
          ),
        ),
      );

      print('🧪 Generating test patients and usage data...');

      // Create 3 test patients
      final testPatients = [
        {
          'name': 'Alice Johnson',
          'email': 'alice.johnson@example.com',
          'phone': '555-0123',
          'age': 28,
          'condition': 'Asthma'
        },
        {
          'name': 'Bob Smith',
          'email': 'bob.smith@example.com',
          'phone': '555-0456',
          'age': 35,
          'condition': 'COPD'
        },
        {
          'name': 'Carol Davis',
          'email': 'carol.davis@example.com',
          'phone': '555-0789',
          'age': 42,
          'condition': 'Chronic Bronchitis'
        }
      ];

      for (var patientData in testPatients) {
        // Generate unique patient ID
        final patientId = 'test_patient_${DateTime.now().millisecondsSinceEpoch}_${(patientData['name'] as String).replaceAll(' ', '_').toLowerCase()}';
        
        // Create patient document
        final patient = {
          'uid': patientId,
          'firstName': (patientData['name'] as String).split(' ').first,
          'lastName': (patientData['name'] as String).split(' ').last,
          'name': patientData['name'],
          'email': patientData['email'],
          'phone': patientData['phone'],
          'age': patientData['age'],
          'dateOfBirth': Timestamp.fromDate(DateTime.now().subtract(Duration(days: (patientData['age'] as int) * 365))),
          'medicalCondition': patientData['condition'],
          'userType': 'patient',
          'assignedDoctorId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': 'test_data_generator',
          'isActive': true,
        };

        await FirebaseFirestore.instance.collection('users').doc(patientId).set(patient);
        print('👤 Created test patient: ${patientData['name']}');

        // Create random usage data for this patient (last 14 days)
        final now = DateTime.now();
        for (int day = 0; day < 14; day++) {
          final usageDate = now.subtract(Duration(days: day));
          
          // Random number of uses per day (0-4)
          final usesPerDay = (day % 3 == 0) ? 0 : (day % 4) + 1;
          
          for (int use = 0; use < usesPerDay; use++) {
            final usageTime = usageDate.add(Duration(
              hours: 8 + (use * 4) + (day % 3), // Spread throughout day
              minutes: (use * 15) + (day % 60),
            ));

            await FirebaseFirestore.instance.collection('inhaler_usage').add({
              'patientId': patientId,
              'patientName': patientData['name'],
              'usageTime': Timestamp.fromDate(usageTime),
              'deviceId': 'test_device_${patientId.substring(0, 8)}',
              'medicationType': ['Albuterol', 'Budesonide', 'Fluticasone'][day % 3],
              'dosageAmount': [90.0, 200.0, 100.0][day % 3],
              'technique': ['Excellent', 'Good', 'Fair'][(day + use) % 3],
              'flowRate': ['Normal', 'Fast', 'Slow'][use % 3],
              'temperature': 20.0 + (day % 10),
              'humidity': 40.0 + (day % 30),
              'createdBy': 'test_data_generator',
              'notes': 'Test usage data for demonstration',
            });
          }
        }
        print('💨 Created usage data for: ${patientData['name']}');
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Test data generated! Created ${testPatients.length} patients with usage history.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Force refresh to show new data
        setState(() {});
      }

      print('✅ Test data generation complete!');

    } catch (e) {
      print('❌ Error generating test data: $e');
      
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error generating test data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 