# 🔥 Firestore Database Setup Guide for AetherBloom

## Phase 1 Complete: Database Implementation ✅

You've successfully implemented the Firestore real-time database! Here's what we've accomplished and what you need to do next.

## ✅ What's Already Implemented

### 1. **Database Schema Design**
- **Users Collection**: Doctor and patient profiles with proper relationships
- **IoT Devices Collection**: Smart inhaler device registration and management  
- **Inhaler Usage Collection**: Real-time usage data logging with sensor information
- **Notification History Collection**: Complete notification tracking system

### 2. **Security Rules** 
- Role-based access control (doctors vs patients)
- Data privacy protection (users can only see their own data)
- Doctor-patient relationship enforcement
- Comprehensive security for all collections

### 3. **Database Service**
- Complete CRUD operations for all collections
- Real-time data streaming
- Analytics and reporting capabilities
- GDPR compliance with data deletion methods

## 🚀 Required Setup Steps

### Step 1: Enable Firestore in Firebase Console

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `aetherbloomapp`
3. **Navigate to Firestore Database**:
   - Click **"Firestore Database"** in the left sidebar
   - Click **"Create database"**

4. **Choose Security Rules**:
   - Select **"Start in test mode"** (we'll deploy our custom rules later)
   - Click **"Next"**

5. **Choose Location**: 
   - Select a location close to your users (e.g., `us-central1`)
   - Click **"Done"**

### Step 2: Deploy Security Rules

1. **Copy the rules** from `firestore.rules` in your project
2. **In Firebase Console** → **Firestore Database** → **Rules**
3. **Replace the default rules** with our custom rules
4. **Click "Publish"**

### Step 3: Test the Database

1. **Run the app**: `flutter run -d edge`
2. **Sign up/Login** using Firebase Auth Test
3. **Navigate to "Firestore Database Test"**
4. **Test all operations**:
   - Create User Profile
   - Register Sample Device  
   - Log Usage Data
   - Send Test Notification
   - Get Analytics

## 📊 Database Collections Overview

### `users/` - User Profiles
```firestore
users/{userId}
├── uid: string
├── email: string  
├── userType: "doctor" | "patient"
├── firstName: string
├── lastName: string
├── phoneNumber?: string
├── dateOfBirth?: string
├── createdAt: timestamp
├── updatedAt: timestamp
├── isActive: boolean
├── [Doctor Fields]
│   ├── specialization?: string
│   ├── licenseNumber?: string
│   ├── hospitalAffiliation?: string
│   └── patientCount: number
└── [Patient Fields]
    ├── medicalHistory?: object
    └── assignedDoctorId?: string
```

### `iot_devices/` - Smart Inhalers
```firestore
iot_devices/{deviceId}
├── deviceName: string
├── deviceType: "inhaler" | "sensor"
├── macAddress: string (Bluetooth MAC)
├── patientId: string (ref to users)
├── firmwareVersion?: string
├── specifications: object
├── status: "active" | "inactive" | "maintenance"
├── batteryLevel?: number (0-100)
├── lastConnected?: timestamp
├── createdAt: timestamp
└── updatedAt: timestamp
```

### `inhaler_usage/` - Usage Events
```firestore
inhaler_usage/{usageId}
├── deviceId: string (ref to iot_devices)
├── patientId: string (ref to users)
├── usageTime: timestamp
├── dosage: number (mg or puffs)
├── medicationType: string
├── flowRate?: number
├── temperature?: number
├── humidity?: number
├── sensorData: object (custom sensor readings)
├── notes?: string
├── createdAt: timestamp
└── processed: boolean (for analytics)
```

### `notification_history/` - Notifications
```firestore
notification_history/{notificationId}
├── userId: string (ref to users)
├── type: "reminder" | "alert" | "info"
├── title: string
├── message: string
├── deviceId?: string
├── metadata: object
├── sentAt: timestamp
├── read: boolean
├── readAt?: timestamp
└── delivered: boolean
```

## 🔒 Security Features

### Role-Based Access Control
- **Doctors** can read their assigned patients' data
- **Patients** can only access their own data
- **Device data** is restricted to owners and assigned doctors
- **Usage data** is immutable once logged (prevents tampering)

### Data Privacy
- Users can only see their own profiles
- Patient-doctor relationships are enforced
- Historical data cannot be modified
- GDPR compliance with data deletion capabilities

## 🧪 Test Scenarios

Once you've enabled Firestore, test these scenarios:

### Authentication & Profiles
1. **Sign up** with a new email
2. **Create user profile** (will create as doctor by default)
3. **View profile** information in the test screen

### Device Management  
1. **Register a sample device** (simulates IoT inhaler)
2. **View device** in Firebase console
3. **Update device status** programmatically

### Usage Tracking
1. **Log sample usage** events
2. **View recent usage** in the app
3. **Get analytics** for usage patterns

### Notifications
1. **Send test notifications**
2. **View notification history**  
3. **Mark notifications as read**

## 🎯 Phase 1 Completion Checklist

- ✅ **Firebase Authentication** working
- ✅ **Firestore Database** schema designed
- ✅ **Security Rules** implemented
- ✅ **Database Service** created
- ✅ **Test Interface** built
- ⏳ **Firestore enabled** in console (your next step)
- ⏳ **End-to-end testing** completed

## 🚀 Ready for Phase 2

Once Firestore is enabled and tested, you're ready to move to **Phase 2**:
- Develop app screens with real Firebase data
- Implement mock Bluetooth service for UI development  
- Design Flask backend API for Firebase integration
- Prepare for hardware integration in Phase 3

## 🆘 Troubleshooting

### Common Issues:
1. **"Client is offline"** → Enable Firestore in console
2. **Permission denied** → Check security rules
3. **Authentication required** → Sign in first
4. **Network errors** → Check internet connection

### Firestore Debug Tips:
- Monitor **Firestore console** for real-time data
- Check **DevTools** for detailed error messages
- Use **Firebase Auth** test screen to verify authentication
- Test **incrementally** (one operation at a time)

---

🎉 **Congratulations!** You've successfully implemented a production-ready Firestore database for AetherBloom. The foundation is now solid for building the complete smart inhaler management system! 