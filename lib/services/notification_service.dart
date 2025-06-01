import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_record.dart';
import '../models/reminder.dart';
import 'notification_history_service.dart';
import 'firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.notification?.title}');
}

/// Service to handle all notification-related functionality
/// Supports local notifications, scheduled reminders, and Firebase push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final NotificationHistoryService _historyService = NotificationHistoryService();
  FirebaseMessaging? _messaging;
  bool _isInitialized = false;

  NotificationService._();

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Initialize history service
      await _historyService.initialize();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase Cloud Messaging (mobile only for now)
      if (!kIsWeb) {
        try {
          await _initializeFirebaseMessaging();
        } catch (e) {
          print('⚠️ FCM initialization failed: $e');
        }
      } else {
        print('🌐 Running on web - FCM tokens will be available on mobile deployment');
        print('📱 To test FCM tokens, run: flutter run -d android');
      }
      
      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
      
      // Send a test notification to verify setup
      await showTestNotification();
      
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      // Don't rethrow - we want the app to continue working even if notifications fail
    }
  }

  /// Initialize Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsIOS,
      linux: initializationSettingsLinux,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request permissions on iOS
    if (!kIsWeb) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      print('🔄 Initializing Firebase Cloud Messaging...');
      
      _messaging = FirebaseMessaging.instance;
      
      if (kIsWeb) {
        print('🌐 Web platform detected - FCM tokens may have different behavior');
      } else {
        print('📱 Mobile platform detected - Full FCM support available');
      }
      
      // Request permissions
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      print('📱 FCM Permission status: ${settings.authorizationStatus}');
      
      // Get FCM token for this device
      String? token = await _messaging!.getToken();
      if (token != null) {
        print('📱 FCM Token generated successfully!');
        print('🔑 Token: ${token.substring(0, 20)}...[${token.length} chars total]');
        print('🌐 This token can be used to send messages from Firebase Console');
        
        // Save token to Firestore for targeted messaging
        await _saveTokenToDatabase(token);
      } else {
        print('⚠️ FCM token is null - this may be normal on web platforms or if permissions are denied');
      }
      
      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        print('📱 FCM Token refreshed: ${newToken.substring(0, 20)}...');
        _saveTokenToDatabase(newToken);
      });
      
      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Listen for background messages (when app is terminated)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      print('✅ Firebase Cloud Messaging initialized successfully');
      
    } catch (e) {
      print('❌ Error initializing FCM: $e');
      print('ℹ️ This may be normal on web platforms or if Firebase is not properly configured');
      throw e; // Re-throw so the caller can handle it
    }
  }

  /// Save FCM token to Firestore for targeted messaging
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      // Import at top: import '../services/firestore_service.dart';
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService.updateUserFCMToken(user.uid, token);
        print('✅ FCM token saved to database');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Check if FCM is supported and available
  bool get isFCMAvailable => _messaging != null;

  /// Get current FCM token for this device
  Future<String?> getCurrentFCMToken() async {
    try {
      if (kIsWeb) {
        print('🌐 Web Platform: FCM tokens are not available in web development mode');
        print('📱 Deploy to Android/iOS to get real FCM tokens');
        return 'web_platform_simulation_token_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      if (_messaging == null) {
        print('⚠️ FCM not initialized');
        return null;
      }
      
      String? token = await _messaging!.getToken();
      if (token != null) {
        print('📱 Current FCM Token: $token');
      } else {
        print('⚠️ No FCM token available (check permissions or web setup)');
      }
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Manually refresh the FCM token
  Future<String?> refreshFCMToken() async {
    try {
      if (kIsWeb) {
        print('🌐 Web Platform: Simulating FCM token refresh');
        print('📱 Deploy to Android/iOS to get real FCM token refresh');
        return 'web_platform_refreshed_token_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      if (_messaging == null) {
        print('⚠️ FCM not initialized');
        return null;
      }
      
      await _messaging!.deleteToken();
      String? newToken = await _messaging!.getToken();
      
      if (newToken != null) {
        print('📱 FCM Token refreshed: ${newToken.substring(0, 20)}...');
        await _saveTokenToDatabase(newToken);
        return newToken;
      } else {
        print('⚠️ Failed to get new FCM token');
      }
      
      return null;
    } catch (e) {
      print('❌ Error refreshing FCM token: $e');
      return null;
    }
  }

  /// Clear FCM token on logout
  Future<void> clearFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService.clearUserFCMToken(user.uid);
      }
      
      if (_messaging != null) {
        await _messaging!.deleteToken();
      }
      
      print('✅ FCM token cleared');
    } catch (e) {
      print('❌ Error clearing FCM token: $e');
    }
  }

  /// Get FCM permission status
  Future<String> getFCMPermissionStatus() async {
    try {
      if (kIsWeb) {
        return 'Web Platform (FCM available on mobile deployment)';
      }
      
      if (_messaging == null) {
        return 'FCM Not Initialized';
      }
      
      NotificationSettings settings = await _messaging!.getNotificationSettings();
      return settings.authorizationStatus.toString();
    } catch (e) {
      print('❌ Error getting FCM permission status: $e');
      return 'Error: $e';
    }
  }

  /// Request FCM permissions if not already granted
  Future<bool> requestFCMPermissions() async {
    try {
      if (kIsWeb) {
        print('🌐 Web Platform: FCM permissions would be requested on mobile');
        return true; // Simulate success
      }
      
      if (_messaging == null) {
        print('⚠️ FCM not initialized');
        return false;
      }
      
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      bool granted = settings.authorizationStatus == AuthorizationStatus.authorized;
      print('📱 FCM Permissions ${granted ? "granted" : "denied"}');
      return granted;
    } catch (e) {
      print('❌ Error requesting FCM permissions: $e');
      return false;
    }
  }

  /// Handle foreground Firebase messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Received FCM message: ${message.notification?.title}');
    
    if (message.notification != null) {
      showInstantNotification(
        message.notification!.title ?? 'Notification',
        message.notification!.body ?? '',
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Show a test notification to verify setup
  Future<void> showTestNotification() async {
    await showInstantNotification(
      '🌟 AetherBloom Ready',
      'Notification system is working! You\'ll receive medication reminders here.',
    );
  }

  /// Show an instant notification
  Future<void> showInstantNotification(String title, String body, {String? payload}) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'aetherbloom_instant',
        'Instant Notifications',
        channelDescription: 'Immediate notifications from AetherBloom',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        macOS: iOSPlatformChannelSpecifics,
      );
      
      final int notificationId = Random().nextInt(100000);
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      
      // Log to history
      await _historyService.addRecord(
        NotificationRecord(
          id: notificationId.toString(),
          title: title,
          description: body,
          timestamp: DateTime.now(),
          status: NotificationStatus.sent,
        ),
      );
      
      print('✅ Instant notification sent: $title');
      
    } catch (e) {
      print('❌ Error showing instant notification: $e');
    }
  }

  /// Schedule a recurring medication reminder
  Future<void> scheduleReminder(Reminder reminder) async {
    try {
      // Cancel any existing reminder with the same ID
      await cancelReminder(reminder);
      
      // Schedule notifications for each selected weekday
      for (int i = 0; i < reminder.weekdays.length; i++) {
        if (reminder.weekdays[i]) {
          await _scheduleWeeklyNotification(
            reminder,
            i + 1, // Flutter uses 1-7 for Monday-Sunday
          );
        }
      }
      
      // Log the scheduled reminder
      await _historyService.addRecord(
        NotificationRecord(
          id: reminder.id,
          title: 'Reminder Scheduled',
          description: '${reminder.title} - ${reminder.description}',
          timestamp: DateTime.now(),
          status: NotificationStatus.scheduled,
        ),
      );
      
      print('✅ Reminder scheduled: ${reminder.title}');
      
    } catch (e) {
      print('❌ Error scheduling reminder: $e');
    }
  }

  /// Schedule a weekly recurring notification
  Future<void> _scheduleWeeklyNotification(Reminder reminder, int weekday) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'aetherbloom_reminders',
      'Medication Reminders',
      channelDescription: 'Scheduled medication reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: iOSPlatformChannelSpecifics,
    );
    
    // Calculate next occurrence of this weekday at the specified time
    final now = DateTime.now();
    final tz.TZDateTime scheduledDate = _nextInstanceOfWeekdayAtTime(
      weekday,
      reminder.time.hour,
      reminder.time.minute,
    );
    
    // Use reminder ID + weekday as unique notification ID
    final int notificationId = int.parse(reminder.id) + weekday;
    
    await _localNotifications.zonedSchedule(
      notificationId,
      '💊 ${reminder.title}',
      reminder.description,
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'reminder:${reminder.id}',
    );
  }

  /// Calculate next instance of weekday at specific time
  tz.TZDateTime _nextInstanceOfWeekdayAtTime(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Cancel a scheduled reminder
  Future<void> cancelReminder(Reminder reminder) async {
    try {
      // Cancel all notifications for this reminder (one for each weekday)
      for (int weekday = 1; weekday <= 7; weekday++) {
        final int notificationId = int.parse(reminder.id) + weekday;
        await _localNotifications.cancel(notificationId);
      }
      
      // Log the cancellation
      await _historyService.addRecord(
        NotificationRecord(
          id: reminder.id,
          title: 'Reminder Cancelled',
          description: '${reminder.title} reminder has been cancelled',
          timestamp: DateTime.now(),
          status: NotificationStatus.cancelled,
        ),
      );
      
      print('✅ Reminder cancelled: ${reminder.title}');
      
    } catch (e) {
      print('❌ Error cancelling reminder: $e');
    }
  }

  /// Send medication missed notification
  Future<void> sendMissedMedicationAlert(String medicationName, DateTime missedTime) async {
    await showInstantNotification(
      '⚠️ Missed Medication',
      'You missed your $medicationName scheduled for ${missedTime.hour}:${missedTime.minute.toString().padLeft(2, '0')}',
      payload: 'missed_medication',
    );
  }

  /// Send inhaler usage confirmation
  Future<void> sendUsageConfirmation(String medicationName, double dosage) async {
    await showInstantNotification(
      '✅ Medication Taken',
      'Great! $medicationName (${dosage.toStringAsFixed(1)}mg) logged successfully.',
      payload: 'usage_logged',
    );
  }

  /// Get notification history
  Future<List<NotificationRecord>> getNotificationHistory({
    DateTime? start,
    DateTime? end,
  }) async {
    return await _historyService.getHistory(start: start, end: end);
  }

  /// Show a message notification (general purpose)
  Future<void> showMessage(String title, String message) async {
    await showInstantNotification(title, message);
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _localNotifications.pendingNotificationRequests();
      return pendingNotifications.length;
    } catch (e) {
      print('Error getting pending notifications: $e');
      return 0;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('✅ All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }
} 