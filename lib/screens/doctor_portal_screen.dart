import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/bluetooth_service.dart';
import '../models/notification_record.dart';
import '../services/notification_history_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          }
        });
      }
    });
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
                  Tab(text: 'Reports', icon: Icon(Icons.assessment)),
                ],
              )
            : null,
      ),
      body: _isLoggedIn ? _buildPortalContent() : _buildLoginForm(),
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showConnectionStatus = !_showConnectionStatus;
                });
                if (_showConnectionStatus) {
                  _bluetoothService.startScan();
                } else {
                  _bluetoothService.stopScan();
                }
              },
              child: Icon(_showConnectionStatus ? Icons.bluetooth_connected : Icons.bluetooth_searching),
              tooltip: 'Connect to devices',
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
        _buildReportsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inhaler Usage Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 20,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (BarChartGroupData group) => Colors.blueGrey.withOpacity(0.8),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                const titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    titles[value.toInt() % titles.length],
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
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
                                    fontSize: 12,
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        barGroups: [
                          // Sample data - would be replaced with real usage data
                          _buildBarGroup(0, 5),
                          _buildBarGroup(1, 10),
                          _buildBarGroup(2, 8),
                          _buildBarGroup(3, 15),
                          _buildBarGroup(4, 12),
                          _buildBarGroup(5, 6),
                          _buildBarGroup(6, 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _notificationHistory.isEmpty
                        ? const Center(
                            child: Text('No notification history available'),
                          )
                        : ListView.builder(
                            itemCount: _notificationHistory.length > 5
                                ? 5
                                : _notificationHistory.length,
                            itemBuilder: (context, index) {
                              final notification = _notificationHistory[index];
                              return ListTile(
                                title: Text(notification.title),
                                subtitle: Text(notification.description),
                                trailing: Text(
                                  _formatDateTime(notification.timestamp),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
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
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.blue,
          width: 15,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}, ${dateTime.hour}:${dateTime.minute}';
  }

  Widget _buildPatientsTab() {
    // Sample patient data - would be fetched from a real backend
    final patients = [
      {
        'name': 'John Doe',
        'age': 42,
        'condition': 'Asthma',
        'adherence': 0.85,
      },
      {
        'name': 'Jane Smith',
        'age': 35,
        'condition': 'COPD',
        'adherence': 0.92,
      },
      {
        'name': 'Michael Johnson',
        'age': 67,
        'condition': 'Asthma',
        'adherence': 0.78,
      },
      {
        'name': 'Emily Williams',
        'age': 29,
        'condition': 'Allergic Asthma',
        'adherence': 0.95,
      },
      {
        'name': 'Robert Brown',
        'age': 51,
        'condition': 'COPD',
        'adherence': 0.65,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Patients',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // This would filter the patient list
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      child: Text(
                        patient['name'].toString().substring(0, 1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(patient['name'].toString()),
                    subtitle: Text(
                        '${patient['age']} years - ${patient['condition']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Adherence',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text("TESTING"),
                      ],
                    ),
                    onTap: () {
                      // Would navigate to patient details
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getAdherenceColor(double adherence) {
    if (adherence >= 0.9) return Colors.green;
    if (adherence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  Widget _buildReportsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assessment,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Analytics & Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Generate detailed reports and analytics',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildReportCard(
                'Adherence Report',
                Icons.assignment_turned_in,
                Colors.green,
              ),
              _buildReportCard(
                'Usage Patterns',
                Icons.insights,
                Colors.orange,
              ),
              _buildReportCard(
                'Patient Progress',
                Icons.trending_up,
                Colors.blue,
              ),
              _buildReportCard(
                'Medication Efficacy',
                Icons.medical_services,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // Would generate and display the selected report
      },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 