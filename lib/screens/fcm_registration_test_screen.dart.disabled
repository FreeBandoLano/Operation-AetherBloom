import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';

/// Screen to test and manage FCM registration tokens
/// 
/// This screen provides:
/// - Current FCM token display
/// - Token refresh functionality
/// - Permission management
/// - Token storage testing
/// - Token retrieval for different user types
class FCMRegistrationTestScreen extends StatefulWidget {
  const FCMRegistrationTestScreen({super.key});

  @override
  State<FCMRegistrationTestScreen> createState() => _FCMRegistrationTestScreenState();
}

class _FCMRegistrationTestScreenState extends State<FCMRegistrationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  
  String _statusMessage = 'Ready to test FCM registration';
  String _currentToken = 'No token available';
  String _permissionStatus = 'Unknown';
  bool _isLoading = false;
  List<String> _allTokens = [];
  List<String> _doctorTokens = [];
  List<String> _patientTokens = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Load initial FCM data
  Future<void> _loadInitialData() async {
    await _getCurrentToken();
    await _getPermissionStatus();
    await _loadAllTokens();
  }

  /// Get current FCM token
  Future<void> _getCurrentToken() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Getting current FCM token...';
    });

    try {
      String? token = await _notificationService.getCurrentFCMToken();
      setState(() {
        _currentToken = token ?? 'No token available (Web platform or FCM not supported)';
        _statusMessage = token != null 
            ? 'FCM token retrieved successfully'
            : 'FCM not available on this platform';
      });
    } catch (e) {
      setState(() {
        _currentToken = 'Error: $e';
        _statusMessage = 'Error getting FCM token: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Refresh FCM token
  Future<void> _refreshToken() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Refreshing FCM token...';
    });

    try {
      String? newToken = await _notificationService.refreshFCMToken();
      setState(() {
        _currentToken = newToken ?? 'Failed to refresh token';
        _statusMessage = newToken != null 
            ? 'FCM token refreshed successfully'
            : 'Failed to refresh token (Web platform or FCM not supported)';
      });
    } catch (e) {
      setState(() {
        _currentToken = 'Error: $e';
        _statusMessage = 'Error refreshing FCM token: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get FCM permission status
  Future<void> _getPermissionStatus() async {
    try {
      String status = await _notificationService.getFCMPermissionStatus();
      setState(() {
        _permissionStatus = status;
      });
    } catch (e) {
      setState(() {
        _permissionStatus = 'Error: $e';
      });
    }
  }

  /// Request FCM permissions
  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Requesting FCM permissions...';
    });

    try {
      bool granted = await _notificationService.requestFCMPermissions();
      setState(() {
        _statusMessage = granted 
            ? 'FCM permissions granted successfully'
            : 'FCM permissions denied or not available';
      });
      await _getPermissionStatus();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error requesting FCM permissions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load all FCM tokens from database
  Future<void> _loadAllTokens() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading FCM tokens from database...';
    });

    try {
      // Get all tokens
      List<String> allTokens = await FirestoreService.getAllFCMTokens();
      
      // Get doctor tokens
      List<String> doctorTokens = await FirestoreService.getUserTypesFCMTokens('doctor');
      
      // Get patient tokens
      List<String> patientTokens = await FirestoreService.getUserTypesFCMTokens('patient');

      setState(() {
        _allTokens = allTokens;
        _doctorTokens = doctorTokens;
        _patientTokens = patientTokens;
        _statusMessage = 'Loaded ${allTokens.length} total FCM tokens '
            '(${doctorTokens.length} doctors, ${patientTokens.length} patients)';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading FCM tokens: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Clear current user's FCM token
  Future<void> _clearToken() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing FCM token...';
    });

    try {
      await _notificationService.clearFCMToken();
      setState(() {
        _currentToken = 'Token cleared';
        _statusMessage = 'FCM token cleared successfully';
      });
      await _loadAllTokens();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing FCM token: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Test saving a custom token (for testing purposes)
  Future<void> _testTokenSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = 'No authenticated user found!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing token save...';
    });

    try {
      String testToken = 'test_token_${DateTime.now().millisecondsSinceEpoch}';
      await FirestoreService.updateUserFCMToken(user.uid, testToken);
      
      setState(() {
        _statusMessage = 'Test token saved successfully: $testToken';
      });
      await _loadAllTokens();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving test token: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Registration Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FCM Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusMessage.contains('Error') 
                            ? Colors.red 
                            : _statusMessage.contains('success') 
                                ? Colors.green 
                                : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current Token Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current FCM Token',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        _currentToken,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Permission Status: $_permissionStatus',
                      style: TextStyle(
                        color: _permissionStatus.contains('authorized') 
                            ? Colors.green 
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Token Management Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token Management',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    // Action buttons in a grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getCurrentToken,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Get Token'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _refreshToken,
                          icon: const Icon(Icons.autorenew),
                          label: const Text('Refresh Token'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _requestPermissions,
                          icon: const Icon(Icons.security),
                          label: const Text('Request Perms'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _clearToken,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Token'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadAllTokens,
                          icon: const Icon(Icons.download),
                          label: const Text('Load All'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testTokenSave,
                          icon: const Icon(Icons.save),
                          label: const Text('Test Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Database Tokens Overview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Database FCM Tokens',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTokenList('All Users (${_allTokens.length})', _allTokens, Colors.blue),
                    const SizedBox(height: 12),
                    _buildTokenList('Doctors (${_doctorTokens.length})', _doctorTokens, Colors.green),
                    const SizedBox(height: 12),
                    _buildTokenList('Patients (${_patientTokens.length})', _patientTokens, Colors.orange),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // FCM Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FCM Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• FCM Available: ${_notificationService.isFCMAvailable ? "Yes" : "No"}',
                    ),
                    Text(
                      '• Platform: ${_notificationService.isFCMAvailable ? "Mobile" : "Web/Desktop"}',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'FCM tokens are automatically registered when users log in and the notification service initializes. '
                      'Tokens are stored in Firestore and can be used for targeted push notifications.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a token list widget
  Widget _buildTokenList(String title, List<String> tokens, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          if (tokens.isEmpty)
            const Text(
              'No tokens found',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            )
          else
            ...tokens.take(3).map((token) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SelectableText(
                '${token.substring(0, token.length > 50 ? 50 : token.length)}...',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            )).toList(),
          if (tokens.length > 3)
            Text(
              '... and ${tokens.length - 3} more',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
} 