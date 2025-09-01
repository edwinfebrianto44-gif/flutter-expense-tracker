import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      await Permission.notification.request();
      
      // Request exact alarm permission for Android 12+
      if (Platform.version.contains('31') || Platform.version.contains('32') || Platform.version.contains('33')) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    print('Notification tapped with payload: $payload');
    
    // Handle notification tap based on payload
    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }

  void _handleNotificationPayload(String payload) {
    // Parse payload and navigate accordingly
    // This can be expanded to handle different types of notifications
    switch (payload) {
      case 'daily_reminder':
        // Navigate to add transaction screen
        break;
      case 'weekly_summary':
        // Navigate to reports screen
        break;
      case 'budget_alert':
        // Navigate to budget screen
        break;
      default:
        // Navigate to dashboard
        break;
    }
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      channelDescription: 'Immediate notifications for important events',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Expense Tracker',
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Daily reminders to track expenses',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Daily Reminder',
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for today first, then it will repeat daily
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If the time has already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // This makes it repeat daily
      payload: payload,
    );
  }

  Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int weekday, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'weekly_reminders',
      'Weekly Reminders',
      channelDescription: 'Weekly financial summary reminders',
      importance: Importance.default_,
      priority: Priority.defaultPriority,
      ticker: 'Weekly Reminder',
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Calculate next occurrence of the specified weekday
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    // Adjust to the correct weekday
    final daysToAdd = (weekday - scheduledTime.weekday) % 7;
    scheduledTime = scheduledTime.add(Duration(days: daysToAdd));
    
    // If it's the same day but time has passed, add a week
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 7));
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  Future<void> scheduleMonthlyReminder({
    required int id,
    required String title,
    required String body,
    required int day, // Day of month (1-31)
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'monthly_reminders',
      'Monthly Reminders',
      channelDescription: 'Monthly financial review reminders',
      importance: Importance.default_,
      priority: Priority.defaultPriority,
      ticker: 'Monthly Reminder',
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Calculate next occurrence of the specified day of month
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, day, hour, minute);
    
    // If the date has passed this month, schedule for next month
    if (scheduledTime.isBefore(now)) {
      if (now.month == 12) {
        scheduledTime = DateTime(now.year + 1, 1, day, hour, minute);
      } else {
        scheduledTime = DateTime(now.year, now.month + 1, day, hour, minute);
      }
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> showBudgetAlert({
    required String categoryName,
    required double spentAmount,
    required double budgetLimit,
  }) async {
    final percentage = (spentAmount / budgetLimit * 100).round();
    
    await showInstantNotification(
      id: 1000, // Use a high ID for budget alerts
      title: '⚠️ Budget Alert',
      body: 'You\'ve spent $percentage% of your $categoryName budget (\$${spentAmount.toStringAsFixed(2)}/\$${budgetLimit.toStringAsFixed(2)})',
      payload: 'budget_alert',
    );
  }

  Future<void> showTransactionReminder() async {
    await showInstantNotification(
      id: 2000, // Use a specific ID for transaction reminders
      title: '💰 Don\'t forget!',
      body: 'Have you tracked all your expenses today?',
      payload: 'daily_reminder',
    );
  }

  Future<void> showWeeklySummaryNotification({
    required double weeklyExpense,
    required double weeklyIncome,
  }) async {
    final balance = weeklyIncome - weeklyExpense;
    final balanceText = balance >= 0 ? 'saved \$${balance.toStringAsFixed(2)}' : 'overspent \$${(-balance).toStringAsFixed(2)}';
    
    await showInstantNotification(
      id: 3000, // Use a specific ID for weekly summaries
      title: '📊 Weekly Summary',
      body: 'This week you $balanceText. Income: \$${weeklyIncome.toStringAsFixed(2)}, Expenses: \$${weeklyExpense.toStringAsFixed(2)}',
      payload: 'weekly_summary',
    );
  }

  Future<void> showMonthlySummaryNotification({
    required double monthlyExpense,
    required double monthlyIncome,
    required String month,
  }) async {
    final balance = monthlyIncome - monthlyExpense;
    final balanceText = balance >= 0 ? 'saved \$${balance.toStringAsFixed(2)}' : 'overspent \$${(-balance).toStringAsFixed(2)}';
    
    await showInstantNotification(
      id: 4000, // Use a specific ID for monthly summaries
      title: '📈 Monthly Report - $month',
      body: 'You $balanceText this month. Tap to view detailed report.',
      payload: 'monthly_summary',
    );
  }

  // Setup default reminders
  Future<void> setupDefaultReminders() async {
    // Daily reminder at 9 PM
    await scheduleDailyReminder(
      id: 100,
      title: '💰 Expense Tracker',
      body: 'Don\'t forget to log your expenses today!',
      hour: 21, // 9 PM
      minute: 0,
      payload: 'daily_reminder',
    );

    // Weekly summary on Sunday at 7 PM
    await scheduleWeeklyReminder(
      id: 101,
      title: '📊 Weekly Financial Summary',
      body: 'Check your weekly spending patterns and progress.',
      weekday: 7, // Sunday
      hour: 19, // 7 PM
      minute: 0,
      payload: 'weekly_summary',
    );

    // Monthly reminder on the 1st at 10 AM
    await scheduleMonthlyReminder(
      id: 102,
      title: '📈 Monthly Financial Review',
      body: 'Time to review your monthly financial goals and spending.',
      day: 1, // 1st of month
      hour: 10, // 10 AM
      minute: 0,
      payload: 'monthly_summary',
    );
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return false;
  }
}
