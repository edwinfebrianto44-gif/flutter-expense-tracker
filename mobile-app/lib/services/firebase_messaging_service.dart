import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'notification_service.dart';

final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FirebaseMessagingService(apiService);
});

class FirebaseMessagingService {
  final ApiService _apiService;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  FirebaseMessagingService(this._apiService);

  Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request permission for iOS
      if (Platform.isIOS) {
        NotificationSettings settings = await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          print('User declined or has not accepted permission');
          return;
        }
      }

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token != null) {
        // Send token to backend
        await _sendTokenToBackend(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((String token) {
        print('FCM Token refreshed: $token');
        _sendTokenToBackend(token);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Handle app opened from terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _apiService.post('/notifications/register-token', data: {
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });
    } catch (e) {
      print('Error sending FCM token to backend: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification when app is in foreground
    _notificationService.showInstantNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'Expense Tracker',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data['payload'] ?? message.data['type'],
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    print('Message tapped: ${message.messageId}');
    print('Data: ${message.data}');

    // Handle navigation based on message data
    final type = message.data['type'];
    switch (type) {
      case 'budget_alert':
        // Navigate to budget screen
        break;
      case 'transaction_reminder':
        // Navigate to add transaction screen
        break;
      case 'weekly_summary':
        // Navigate to reports screen
        break;
      case 'monthly_summary':
        // Navigate to reports screen
        break;
      default:
        // Navigate to dashboard
        break;
    }
  }

  // Helper methods for different notification types
  Future<void> sendBudgetAlert({
    required String userId,
    required String categoryName,
    required double spentAmount,
    required double budgetLimit,
  }) async {
    try {
      await _apiService.post('/notifications/send-budget-alert', data: {
        'user_id': userId,
        'category_name': categoryName,
        'spent_amount': spentAmount,
        'budget_limit': budgetLimit,
      });
    } catch (e) {
      print('Error sending budget alert: $e');
    }
  }

  Future<void> sendTransactionReminder(String userId) async {
    try {
      await _apiService.post('/notifications/send-transaction-reminder', data: {
        'user_id': userId,
      });
    } catch (e) {
      print('Error sending transaction reminder: $e');
    }
  }

  Future<void> sendWeeklySummary({
    required String userId,
    required double weeklyIncome,
    required double weeklyExpense,
  }) async {
    try {
      await _apiService.post('/notifications/send-weekly-summary', data: {
        'user_id': userId,
        'weekly_income': weeklyIncome,
        'weekly_expense': weeklyExpense,
      });
    } catch (e) {
      print('Error sending weekly summary: $e');
    }
  }

  Future<void> sendMonthlySummary({
    required String userId,
    required double monthlyIncome,
    required double monthlyExpense,
    required String month,
  }) async {
    try {
      await _apiService.post('/notifications/send-monthly-summary', data: {
        'user_id': userId,
        'monthly_income': monthlyIncome,
        'monthly_expense': monthlyExpense,
        'month': month,
      });
    } catch (e) {
      print('Error sending monthly summary: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}
