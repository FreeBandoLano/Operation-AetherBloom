import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== USER MANAGEMENT ====================
  
  /// Create a new user profile in Firestore
  static Future<void> createUserProfile({
    required String uid,
    required String email,
    required String userType, // 'doctor' or 'patient'
    required String firstName,
    required String lastName,
    String? specialization, // For doctors
    String? licenseNumber, // For doctors
    String? hospitalAffiliation, // For doctors
    String? phoneNumber,
    DateTime? dateOfBirth,
    Map<String, dynamic>? medicalHistory, // For patients
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'userType': userType,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        // Doctor-specific fields
        if (userType == 'doctor') ...{
          'specialization': specialization,
          'licenseNumber': licenseNumber,
          'hospitalAffiliation': hospitalAffiliation,
          'patientCount': 0,
        },
        // Patient-specific fields
        if (userType == 'patient') ...{
          'medicalHistory': medicalHistory ?? {},
          'assignedDoctorId': null,
        },
      });
      print('✅ User profile created successfully');
    } catch (e) {
      print('❌ Error creating user profile: $e');
      throw e;
    }
  }

  /// Get user profile by UID
  static Future<DocumentSnapshot?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Get current user profile
  static Future<DocumentSnapshot?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await getUserProfile(user.uid);
    }
    return null;
  }

  // ==================== PATIENT MANAGEMENT ====================
  
  /// Assign patient to doctor
  static Future<void> assignPatientToDoctor({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      // Update patient with assigned doctor
      batch.update(_firestore.collection('users').doc(patientId), {
        'assignedDoctorId': doctorId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Increment doctor's patient count
      batch.update(_firestore.collection('users').doc(doctorId), {
        'patientCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      print('✅ Patient assigned to doctor successfully');
    } catch (e) {
      print('❌ Error assigning patient to doctor: $e');
      throw e;
    }
  }

  /// Get patients assigned to a doctor
  static Stream<QuerySnapshot> getDoctorPatients(String doctorId) {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'patient')
        .where('assignedDoctorId', isEqualTo: doctorId)
        .orderBy('firstName')
        .snapshots();
  }

  // ==================== IOT DEVICE MANAGEMENT ====================
  
  /// Register a new IoT device
  static Future<String> registerIoTDevice({
    required String deviceName,
    required String deviceType, // 'inhaler', 'sensor', etc.
    required String macAddress,
    required String patientId,
    String? firmwareVersion,
    Map<String, dynamic>? specifications,
  }) async {
    try {
      DocumentReference deviceRef = await _firestore.collection('iot_devices').add({
        'deviceName': deviceName,
        'deviceType': deviceType,
        'macAddress': macAddress,
        'patientId': patientId,
        'firmwareVersion': firmwareVersion,
        'specifications': specifications ?? {},
        'status': 'inactive', // 'active', 'inactive', 'maintenance'
        'batteryLevel': null,
        'lastConnected': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ IoT device registered successfully with ID: ${deviceRef.id}');
      return deviceRef.id;
    } catch (e) {
      print('❌ Error registering IoT device: $e');
      throw e;
    }
  }

  /// Update device status and connection info
  static Future<void> updateDeviceStatus({
    required String deviceId,
    required String status,
    int? batteryLevel,
    DateTime? lastConnected,
  }) async {
    try {
      await _firestore.collection('iot_devices').doc(deviceId).update({
        'status': status,
        'batteryLevel': batteryLevel,
        'lastConnected': lastConnected?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating device status: $e');
      throw e;
    }
  }

  /// Get devices for a specific patient
  static Stream<QuerySnapshot> getPatientDevices(String patientId) {
    return _firestore
        .collection('iot_devices')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== INHALER USAGE DATA ====================
  
  /// Log inhaler usage event
  static Future<String> logInhalerUsage({
    required String deviceId,
    required String patientId,
    required DateTime usageTime,
    required double dosage, // in mg or puffs
    required String medicationType,
    double? flowRate,
    double? temperature,
    double? humidity,
    Map<String, dynamic>? sensorData,
    String? notes,
  }) async {
    try {
      DocumentReference usageRef = await _firestore.collection('inhaler_usage').add({
        'deviceId': deviceId,
        'patientId': patientId,
        'usageTime': Timestamp.fromDate(usageTime),
        'dosage': dosage,
        'medicationType': medicationType,
        'flowRate': flowRate,
        'temperature': temperature,
        'humidity': humidity,
        'sensorData': sensorData ?? {},
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false, // For analytics processing
      });
      
      print('✅ Inhaler usage logged successfully');
      return usageRef.id;
    } catch (e) {
      print('❌ Error logging inhaler usage: $e');
      throw e;
    }
  }

  /// Get inhaler usage history for a patient
  static Stream<QuerySnapshot> getPatientUsageHistory({
    required String patientId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    Query query = _firestore
        .collection('inhaler_usage')
        .where('patientId', isEqualTo: patientId);
    
    if (startDate != null) {
      query = query.where('usageTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    if (endDate != null) {
      query = query.where('usageTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    query = query.orderBy('usageTime', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }

  /// Get basic usage data without ordering (no composite index needed)
  static Future<Map<String, dynamic>> getBasicUsageData({
    required String patientId,
  }) async {
    try {
      print('🔍 Testing basic usage query (no index required) for patient: $patientId');
      
      QuerySnapshot snapshot = await _firestore
          .collection('inhaler_usage')
          .where('patientId', isEqualTo: patientId)
          .limit(10)
          .get();

      print('✅ Basic query successful! Found ${snapshot.docs.length} records');

      int totalUsages = snapshot.docs.length;
      double totalDosage = 0;
      List<Map<String, dynamic>> usageList = [];
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalDosage += (data['dosage'] ?? 0).toDouble();
        usageList.add({
          'id': doc.id,
          'dosage': data['dosage'],
          'medicationType': data['medicationType'],
          'usageTime': data['usageTime'],
        });
      }

      return {
        'totalUsages': totalUsages,
        'totalDosage': totalDosage,
        'usageList': usageList,
        'status': 'success',
      };
    } catch (e) {
      print('❌ Error in basic usage query: $e');
      throw e;
    }
  }

  /// Get usage analytics for a patient
  static Future<Map<String, dynamic>> getUsageAnalytics({
    required String patientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('inhaler_usage')
          .where('patientId', isEqualTo: patientId)
          .where('usageTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('usageTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('usageTime')
          .get();

      // Calculate analytics
      int totalUsages = snapshot.docs.length;
      double totalDosage = 0;
      Map<String, int> medicationTypes = {};
      List<DateTime> usageTimes = [];
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalDosage += (data['dosage'] ?? 0).toDouble();
        
        String medType = data['medicationType'] ?? 'Unknown';
        medicationTypes[medType] = (medicationTypes[medType] ?? 0) + 1;
        
        Timestamp timestamp = data['usageTime'];
        usageTimes.add(timestamp.toDate());
      }

      return {
        'totalUsages': totalUsages,
        'totalDosage': totalDosage,
        'averageDailyUsage': totalUsages / (endDate.difference(startDate).inDays + 1),
        'medicationBreakdown': medicationTypes,
        'usageTimes': usageTimes,
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
      };
    } catch (e) {
      print('❌ Error getting usage analytics: $e');
      throw e;
    }
  }

  // ==================== NOTIFICATION HISTORY ====================
  
  /// Log notification sent to user
  static Future<void> logNotification({
    required String userId,
    required String type, // 'reminder', 'alert', 'info'
    required String title,
    required String message,
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('notification_history').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'deviceId': deviceId,
        'metadata': metadata ?? {},
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
        'delivered': true, // Assume delivery unless we implement delivery tracking
      });
      
      print('✅ Notification logged successfully');
    } catch (e) {
      print('❌ Error logging notification: $e');
      throw e;
    }
  }

  /// Get notification history for a user
  static Stream<QuerySnapshot> getUserNotifications({
    required String userId,
    int? limit,
  }) {
    Query query = _firestore
        .collection('notification_history')
        .where('userId', isEqualTo: userId)
        .orderBy('sentAt', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notification_history').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      throw e;
    }
  }

  // ==================== UTILITY METHODS ====================
  
  /// Initialize some sample data for testing
  static Future<void> initializeSampleData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if user profile already exists
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) return;

      // Create a doctor profile for the current user
      await createUserProfile(
        uid: user.uid,
        email: user.email!,
        userType: 'doctor',
        firstName: 'Dr. John',
        lastName: 'Smith',
        specialization: 'Pulmonology',
        licenseNumber: 'DOC123456',
        hospitalAffiliation: 'AetherBloom Medical Center',
        phoneNumber: '+1-555-0123',
      );

      print('✅ Sample data initialized successfully');
    } catch (e) {
      print('❌ Error initializing sample data: $e');
    }
  }

  /// Delete all data for a user (GDPR compliance)
  static Future<void> deleteUserData(String userId) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      // Delete user profile
      batch.delete(_firestore.collection('users').doc(userId));
      
      // Delete user's devices
      QuerySnapshot devices = await _firestore
          .collection('iot_devices')
          .where('patientId', isEqualTo: userId)
          .get();
      
      for (var doc in devices.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's usage data
      QuerySnapshot usageData = await _firestore
          .collection('inhaler_usage')
          .where('patientId', isEqualTo: userId)
          .get();
      
      for (var doc in usageData.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's notifications
      QuerySnapshot notifications = await _firestore
          .collection('notification_history')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ User data deleted successfully');
    } catch (e) {
      print('❌ Error deleting user data: $e');
      throw e;
    }
  }

  /// Update user's FCM token for push notifications
  static Future<void> updateUserFCMToken(String userId, String fcmToken) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      print('✅ FCM token updated for user: $userId');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
      throw e;
    }
  }

  /// Get FCM token for a specific user
  static Future<String?> getUserFCMToken(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Get FCM tokens for all patients assigned to a doctor
  static Future<List<String>> getDoctorPatientsFCMTokens(String doctorId) async {
    try {
      QuerySnapshot patients = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'patient')
          .where('assignedDoctorId', isEqualTo: doctorId)
          .get();

      List<String> tokens = [];
      for (var doc in patients.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? token = data['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }
      
      print('✅ Found ${tokens.length} FCM tokens for doctor $doctorId');
      return tokens;
    } catch (e) {
      print('❌ Error getting patient FCM tokens: $e');
      return [];
    }
  }

  /// Get FCM tokens for all users of a specific type
  static Future<List<String>> getUserTypesFCMTokens(String userType) async {
    try {
      QuerySnapshot users = await _firestore
          .collection('users')
          .where('userType', isEqualTo: userType)
          .where('isActive', isEqualTo: true)
          .get();

      List<String> tokens = [];
      for (var doc in users.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? token = data['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }
      
      print('✅ Found ${tokens.length} FCM tokens for user type: $userType');
      return tokens;
    } catch (e) {
      print('❌ Error getting user type FCM tokens: $e');
      return [];
    }
  }

  /// Get all FCM tokens for broadcasting to all users
  static Future<List<String>> getAllFCMTokens() async {
    try {
      QuerySnapshot users = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      List<String> tokens = [];
      for (var doc in users.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? token = data['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }
      
      print('✅ Found ${tokens.length} total FCM tokens for broadcasting');
      return tokens;
    } catch (e) {
      print('❌ Error getting all FCM tokens: $e');
      return [];
    }
  }

  /// Remove invalid FCM tokens (called when FCM returns invalid token errors)
  static Future<void> removeInvalidFCMToken(String fcmToken) async {
    try {
      QuerySnapshot users = await _firestore
          .collection('users')
          .where('fcmToken', isEqualTo: fcmToken)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in users.docs) {
        batch.update(doc.reference, {
          'fcmToken': FieldValue.delete(),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('✅ Removed invalid FCM token: $fcmToken');
    } catch (e) {
      print('❌ Error removing invalid FCM token: $e');
    }
  }

  /// Clear FCM token for a user (useful for logout)
  static Future<void> clearUserFCMToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      print('✅ FCM token cleared for user: $userId');
    } catch (e) {
      print('❌ Error clearing FCM token: $e');
      throw e;
    }
  }
} 