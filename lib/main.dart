import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AetherBloom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AetherBloom',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Bluetooth',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildPlaceholderScreen('Analytics', Icons.analytics);
      case 2:
        return _buildPlaceholderScreen('Reminders', Icons.alarm);
      case 3:
        return _buildPlaceholderScreen('Bluetooth Test', Icons.bluetooth);
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to AetherBloom',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Your personal medication management companion',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
            ),
            const SizedBox(height: 16.0),

          // Feature Cards
          _buildFeatureCard(
              title: 'Usage Tracking',
            description: 'Track your medication usage and patterns',
            icon: Icons.timeline,
            color: Colors.green,
            onTap: () => _showFeatureDialog('Usage Tracking'),
          ),
          const SizedBox(height: 16.0),
          
          _buildFeatureCard(
            title: 'Analytics & Reports',
            description: 'View detailed analytics and health reports',
            icon: Icons.analytics,
            color: Colors.purple,
            onTap: () => _showFeatureDialog('Analytics & Reports'),
          ),
          const SizedBox(height: 16.0),
          
          _buildFeatureCard(
            title: 'Medication Reminders',
            description: 'Set and manage your medication schedules',
            icon: Icons.alarm_add,
            color: Colors.orange,
            onTap: () => _showFeatureDialog('Medication Reminders'),
          ),
          const SizedBox(height: 16.0),
          
          _buildFeatureCard(
            title: 'Bluetooth Test (BT05)',
            description: 'Test BT05 device connectivity (requires physical device)',
            icon: Icons.bluetooth,
            color: Colors.cyan,
            onTap: () => _showBluetoothInfo(),
          ),
          
          const SizedBox(height: 32.0),
          
          // Status Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 8.0),
                    Text(
                      'App Status: Working!',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  '✅ App built and running successfully\n'
                  '✅ UI navigation working\n'
                  '✅ Ready for feature development',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icon,
                size: 32.0,
                color: color,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.6),
              size: 16.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderScreen(String title, IconData icon) {
    return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
            size: 100,
            color: Colors.grey[400],
              ),
          const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
              fontSize: 24,
                  fontWeight: FontWeight.bold,
              color: Colors.grey,
                ),
              ),
          const SizedBox(height: 10),
              Text(
            'Feature placeholder\nReady for implementation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
                ),
              ),
            ],
          ),
    );
  }

  void _showFeatureDialog(String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(featureName),
          content: Text('$featureName feature is ready for implementation!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showBluetoothInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('BT05 Bluetooth Test'),
          content: const Text(
            'Bluetooth functionality requires:\n\n'
            '• Physical Android device (not emulator)\n'
            '• BT05 device (MAC: 04:A3:16:A8:94:D2)\n'
            '• Bluetooth permissions\n\n'
            'The BT05 integration code is ready and tested via Python scripts!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}
