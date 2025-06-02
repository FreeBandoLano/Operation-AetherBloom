/// Simple Firestore service stub for Bluetooth testing
/// This is a temporary simplified version while Firebase is disabled
class FirestoreService {
  /// Log inhaler usage (stub version)
  static Future<void> logInhalerUsage({
    required String userId,
    required String deviceId,
    required DateTime usageTime,
    Map<String, dynamic>? additionalData,
  }) async {
    print('📊 Logged inhaler usage for user $userId at $usageTime');
    // In a real implementation, this would save to Firestore
  }

  /// Get inhaler usage data (stub version)
  static Future<List<Map<String, dynamic>>> getInhalerUsageData({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    print('📊 Retrieved inhaler usage data for user $userId');
    // In a real implementation, this would fetch from Firestore
      return [];
  }

  /// Update user FCM token (stub version)
  static Future<void> updateUserFCMToken(String userId, String token) async {
    print('🔑 Updated FCM token for user $userId');
    // In a real implementation, this would update Firestore
  }

  /// Clear user FCM token (stub version)
  static Future<void> clearUserFCMToken(String userId) async {
    print('🔑 Cleared FCM token for user $userId');
    // In a real implementation, this would clear from Firestore
  }
} 