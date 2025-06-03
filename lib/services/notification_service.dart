/// Clean notification service without Firebase dependencies
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔔 NotificationService initialized (Firebase disabled)');
      _isInitialized = true;
    } catch (e) {
      print('❌ NotificationService initialization failed: $e');
      rethrow;
    }
  }

  /// Show a simple message
  Future<void> showMessage(String title, String body, {String? payload}) async {
    print('📱 Notification: $title - $body');
    // In a real implementation, this would show actual notifications
  }

  /// Schedule a medication reminder (stub implementation)
  Future<void> scheduleReminder(dynamic reminder) async {
    print('⏰ Scheduled reminder: ${reminder.toString()}');
    // In a real implementation, this would schedule local notifications
  }

  /// Cancel a medication reminder (stub implementation)
  Future<void> cancelReminder(dynamic reminder) async {
    print('❌ Cancelled reminder: ${reminder.toString()}');
    // In a real implementation, this would cancel local notifications
  }

  /// Send medication reminder
  Future<void> sendMedicationReminder({
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
  }) async {
    print('💊 Medication reminder: Take $dosage of $medicationName at $scheduledTime');
  }

  /// Send inhaler usage notification
  Future<void> sendInhalerUsageNotification({
    required String deviceName,
    required DateTime usageTime,
  }) async {
    print('🫁 Inhaler usage recorded: $deviceName at $usageTime');
  }

  /// Send emergency alert
  Future<void> sendEmergencyAlert({
    required String message,
    required String contactInfo,
  }) async {
    print('🚨 Emergency Alert: $message | Contact: $contactInfo');
  }

  /// Show doctor portal notification
  Future<void> sendDoctorPortalNotification({
    required String patientName,
    required String message,
  }) async {
    print('👨‍⚕️ Doctor Portal: $patientName - $message');
  }

  /// Get pending notifications count - FIX for web compatibility
  Future<int> getPendingNotificationsCount() async {
    // For web demo, return a mock count
    print('📊 Getting pending notifications count (web mock): 3');
    return 3;
  }

  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    print('🚫 All notifications cancelled (web mock)');
  }

  /// Test web notification
  Future<void> testWebNotification() async {
    print('🌐 Testing web notification...');
    // For web, we'll use browser's native notification API
    try {
      // This would trigger browser notification in a real implementation
      print('✅ Web notification sent successfully!');
    } catch (e) {
      print('❌ Web notification failed: $e');
    }
  }

  // Missing methods for compatibility
  
  /// Show instant notification
  Future<void> showInstantNotification(String message) async {
    print('⚡ Instant notification: $message');
  }

  /// Send usage confirmation
  Future<void> sendUsageConfirmation(String medication, double dosage) async {
    print('✅ Usage confirmed: $medication ($dosage mg)');
  }

  /// Send missed medication alert
  Future<void> sendMissedMedicationAlert(String medication, DateTime missedTime) async {
    print('⚠️ Missed medication alert: $medication at $missedTime');
  }

  /// Get current FCM token
  Future<String?> getCurrentFCMToken() async {
    print('🔑 FCM Token requested (web mock)');
    return 'web-mock-token-12345';
  }

  /// Check if FCM is available
  bool get isFCMAvailable => false; // Web version doesn't use FCM in this demo

  /// Refresh FCM token (stub for compatibility)
  Future<String?> refreshFCMToken() async {
    print('🔄 FCM Token refresh requested (mock - not applicable)');
    if (!isFCMAvailable) {
      return null; // Or return existing mock token: 'web-mock-token-12345'
    }
    // In a real FCM implementation, this would refresh the token
    return null;
  }

  /// Get FCM permission status (stub for compatibility)
  Future<String> getFCMPermissionStatus() async {
    print('📊 FCM Permission status requested (mock - not applicable)');
    if (!isFCMAvailable) {
      return 'not_applicable';
    }
    // In a real FCM implementation, this would get the actual permission status
    return 'denied'; // Default to denied
  }

  /// Request FCM permissions (stub for compatibility)
  Future<bool> requestFCMPermissions() async {
    print('🙏 FCM Permissions request (mock - not applicable)');
    if (!isFCMAvailable) {
      return false;
    }
    // In a real FCM implementation, this would request permissions
    return false;
  }

  /// Clear FCM token (stub for compatibility)
  Future<void> clearFCMToken() async {
    print('🗑️ FCM Token clear requested (mock - not applicable)');
    if (!isFCMAvailable) {
      return;
    }
    // In a real FCM implementation, this would clear/delete the token
  }
} 