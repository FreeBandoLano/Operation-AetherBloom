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
      throw e;
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
} 