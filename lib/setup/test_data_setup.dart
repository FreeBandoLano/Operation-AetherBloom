import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class TestDataSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Set up test data for development
  static Future<void> initializeTestData() async {
    print('🧪 Setting up test data...');
    
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No authenticated user found');
      return;
    }

    try {
      // Check if user profile already exists
      DocumentSnapshot existingProfile = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!existingProfile.exists) {
        await _setupCurrentUserProfile(currentUser);
      } else {
        print('✅ User profile already exists');
      }

      // Create test patients and doctors
      await _createTestDoctors();
      await _createTestPatients(currentUser.uid);
      await _createTestUsageData(currentUser.uid);
      
      print('✅ Test data setup complete!');
      
    } catch (e) {
      print('❌ Error setting up test data: $e');
    }
  }

  /// Set up the current user's profile
  static Future<void> _setupCurrentUserProfile(User user) async {
    print('👤 Creating user profile for ${user.email}');
    
    // Create doctor profile (since we're testing doctor portal)
    await FirestoreService.createUserProfile(
      uid: user.uid,
      email: user.email ?? 'test@example.com',
      userType: 'doctor',
      firstName: 'Dr. Test',
      lastName: 'Doctor',
      specialization: 'Pulmonology',
      licenseNumber: 'TEST123456',
    );
    
    print('✅ Doctor profile created');
  }

  /// Create test doctors
  static Future<void> _createTestDoctors() async {
    print('👩‍⚕️ Creating test doctors...');
    
    List<Map<String, dynamic>> testDoctors = [
      {
        'uid': 'doctor_test_1',
        'email': 'dr.smith@test.com',
        'userType': 'doctor',
        'firstName': 'Dr. Sarah',
        'lastName': 'Smith',
        'specialization': 'Pulmonology',
        'licenseNumber': 'DOC001',
      },
      {
        'uid': 'doctor_test_2', 
        'email': 'dr.jones@test.com',
        'userType': 'doctor',
        'firstName': 'Dr. Michael',
        'lastName': 'Jones',
        'specialization': 'Internal Medicine',
        'licenseNumber': 'DOC002',
      },
    ];

    for (var doctorData in testDoctors) {
      DocumentSnapshot existing = await _firestore
          .collection('users')
          .doc(doctorData['uid'])
          .get();
          
      if (!existing.exists) {
        await _firestore
            .collection('users')
            .doc(doctorData['uid'])
            .set({
          ...doctorData,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
    }
    
    print('✅ Test doctors created');
  }

  /// Create test patients
  static Future<void> _createTestPatients(String currentDoctorId) async {
    print('🤒 Creating test patients...');
    
    List<Map<String, dynamic>> testPatients = [
      {
        'uid': 'patient_test_1',
        'email': 'john.doe@test.com',
        'userType': 'patient',
        'firstName': 'John',
        'lastName': 'Doe',
        'dateOfBirth': Timestamp.fromDate(DateTime(1980, 5, 15)),
        'assignedDoctorId': currentDoctorId,
        'medicalConditions': ['Asthma'],
      },
      {
        'uid': 'patient_test_2',
        'email': 'jane.smith@test.com', 
        'userType': 'patient',
        'firstName': 'Jane',
        'lastName': 'Smith',
        'dateOfBirth': Timestamp.fromDate(DateTime(1975, 8, 22)),
        'assignedDoctorId': currentDoctorId,
        'medicalConditions': ['COPD'],
      },
      {
        'uid': 'patient_test_3',
        'email': 'mike.johnson@test.com',
        'userType': 'patient', 
        'firstName': 'Mike',
        'lastName': 'Johnson',
        'dateOfBirth': Timestamp.fromDate(DateTime(1992, 12, 3)),
        'assignedDoctorId': currentDoctorId,
        'medicalConditions': ['Allergic Asthma'],
      },
    ];

    for (var patientData in testPatients) {
      DocumentSnapshot existing = await _firestore
          .collection('users')
          .doc(patientData['uid'])
          .get();
          
      if (!existing.exists) {
        await _firestore
            .collection('users')
            .doc(patientData['uid'])
            .set({
          ...patientData,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
    }
    
    print('✅ Test patients created');
  }

  /// Create test usage data
  static Future<void> _createTestUsageData(String doctorId) async {
    print('💨 Creating test inhaler usage data...');
    
    List<String> patientIds = ['patient_test_1', 'patient_test_2', 'patient_test_3'];
    List<String> medications = ['Albuterol', 'Fluticasone', 'Budesonide'];
    
    DateTime now = DateTime.now();
    
    // Create usage data for the last 7 days
    for (int day = 0; day < 7; day++) {
      DateTime usageDay = now.subtract(Duration(days: day));
      
      for (String patientId in patientIds) {
        // Random number of usages per day (0-4)
        int usagesPerDay = (day % 3) + 1; // Varies by day
        
        for (int usage = 0; usage < usagesPerDay; usage++) {
          DateTime usageTime = usageDay.add(Duration(
            hours: 8 + (usage * 4), // Spread throughout the day
            minutes: (usage * 15) % 60,
          ));
          
          String medication = medications[patientId.hashCode % medications.length];
          
          await FirestoreService.logInhalerUsage(
            deviceId: 'device_${patientId}_1',
            patientId: patientId,
            usageTime: usageTime,
            dosage: 90.0 + (usage * 10), // Vary dosage
            medicationType: medication,
            sensorData: {
              'temperature': 22.0 + (usage * 2),
              'humidity': 45.0 + (usage * 5),
              'pressure': 1013.25,
              'flow_rate': 180.0 + (usage * 20),
            },
          );
        }
      }
    }
    
    print('✅ Test usage data created');
  }

  /// Reset all test data
  static Future<void> resetTestData() async {
    print('🔄 Resetting test data...');
    
    try {
      // Delete test collections
      await _deleteCollection('users');
      await _deleteCollection('inhaler_usage');
      await _deleteCollection('iot_devices');
      await _deleteCollection('notification_history');
      
      print('✅ Test data reset complete');
      
    } catch (e) {
      print('❌ Error resetting test data: $e');
    }
  }

  /// Delete a collection (for testing only)
  static Future<void> _deleteCollection(String collectionName) async {
    QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
    
    for (DocumentSnapshot doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Check current user setup status
  static Future<Map<String, dynamic>> checkSetupStatus() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {'authenticated': false};
    }

    DocumentSnapshot userProfile = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();

    QuerySnapshot patients = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'patient')
        .get();

    QuerySnapshot usageData = await _firestore
        .collection('inhaler_usage')
        .limit(5)
        .get();

    return {
      'authenticated': true,
      'userEmail': currentUser.email,
      'hasUserProfile': userProfile.exists,
      'userType': userProfile.exists ? (userProfile.data() as Map<String, dynamic>)['userType'] : null,
      'patientsCount': patients.docs.length,
      'usageDataCount': usageData.docs.length,
    };
  }
} 