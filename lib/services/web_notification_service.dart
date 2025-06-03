import 'dart:html' as html;

/// Web-specific notification service using browser APIs
class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  bool _isInitialized = false;

  /// Initialize web notifications
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🌐 Initializing Web Notification Service...');
      
      // Request notification permission with timeout
      await _requestPermission().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Notification permission request timed out after 10 seconds');
          // Continue initialization even if permission request times out
        },
      );
      
      _isInitialized = true;
      print('✅ Web Notification Service initialized successfully!');
    } catch (e) {
      print('❌ Web Notification Service initialization failed: $e');
      // Set as initialized anyway to prevent retry loops
      _isInitialized = true;
      rethrow;
    }
  }

  /// Request browser notification permission
  Future<void> _requestPermission() async {
    try {
      print('🔔 Requesting notification permission...');
      final permission = await html.Notification.requestPermission();
      print('🔔 Notification permission: $permission');
      
      if (permission != 'granted') {
        print('⚠️ Notification permission not granted');
      }
    } catch (e) {
      print('❌ Failed to request notification permission: $e');
      // Don't rethrow - we want initialization to continue even if permission fails
    }
  }

  /// Show browser notification
  Future<void> _showBrowserNotification({
    required String title,
    required String body,
    String? icon,
  }) async {
    try {
      if (html.Notification.permission == 'granted') {
        final notification = html.Notification(
          title,
          body: body,
          icon: icon ?? '/icons/Icon-192.png',
        );
        
        // Auto-close after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          notification.close();
        });
        
        print('✅ Browser notification shown: $title');
      } else {
        print('⚠️ Cannot show notification: permission not granted');
        // Show fallback alert for demo
        html.window.alert('📱 $title: $body');
      }
    } catch (e) {
      print('❌ Failed to show browser notification: $e');
      // Fallback to alert for demo
      html.window.alert('📱 $title: $body');
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    await _showBrowserNotification(
      title: '💊 AetherBloom Reminder',
      body: 'Time to take your medication!',
    );
  }

  /// Send medication reminder
  Future<void> sendMedicationReminder({
    required String medicationName,
    required String dosage,
  }) async {
    await _showBrowserNotification(
      title: '💊 Medication Reminder',
      body: 'Time to take $dosage of $medicationName',
    );
  }

  /// Send inhaler usage notification
  Future<void> sendInhalerAlert() async {
    await _showBrowserNotification(
      title: '🫁 Inhaler Usage Detected',
      body: 'Inhaler usage has been recorded successfully',
    );
  }

  /// Send emergency alert
  Future<void> sendEmergencyAlert() async {
    await _showBrowserNotification(
      title: '🚨 Emergency Alert',
      body: 'Critical health event detected - Contact emergency services',
    );
  }

  /// Send custom notification with title and body
  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? icon,
  }) async {
    await _showBrowserNotification(
      title: title,
      body: body,
      icon: icon,
    );
  }
  
  /// Check if notifications are supported and permitted
  bool get isSupported => _isInitialized && html.Notification.permission == 'granted';
} 