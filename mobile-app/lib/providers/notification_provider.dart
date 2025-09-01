import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/firebase_messaging_service.dart';

// Notification settings state
class NotificationSettings {
  final bool dailyReminders;
  final bool weeklyReports;
  final bool monthlyReports;
  final bool budgetAlerts;
  final bool pushNotifications;
  final int reminderHour;
  final int reminderMinute;

  const NotificationSettings({
    required this.dailyReminders,
    required this.weeklyReports,
    required this.monthlyReports,
    required this.budgetAlerts,
    required this.pushNotifications,
    required this.reminderHour,
    required this.reminderMinute,
  });

  NotificationSettings copyWith({
    bool? dailyReminders,
    bool? weeklyReports,
    bool? monthlyReports,
    bool? budgetAlerts,
    bool? pushNotifications,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return NotificationSettings(
      dailyReminders: dailyReminders ?? this.dailyReminders,
      weeklyReports: weeklyReports ?? this.weeklyReports,
      monthlyReports: monthlyReports ?? this.monthlyReports,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  static const defaultSettings = NotificationSettings(
    dailyReminders: false,
    weeklyReports: false,
    monthlyReports: false,
    budgetAlerts: true,
    pushNotifications: false,
    reminderHour: 20,
    reminderMinute: 0,
  );
}

// Notification settings provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  final firebaseService = ref.watch(firebaseMessagingServiceProvider);
  return NotificationSettingsNotifier(firebaseService);
});

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final FirebaseMessagingService _firebaseService;
  final NotificationService _notificationService = NotificationService();

  NotificationSettingsNotifier(this._firebaseService) : super(NotificationSettings.defaultSettings) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      dailyReminders: prefs.getBool('daily_reminders') ?? false,
      weeklyReports: prefs.getBool('weekly_reports') ?? false,
      monthlyReports: prefs.getBool('monthly_reports') ?? false,
      budgetAlerts: prefs.getBool('budget_alerts') ?? true,
      pushNotifications: prefs.getBool('push_notifications') ?? false,
      reminderHour: prefs.getInt('reminder_hour') ?? 20,
      reminderMinute: prefs.getInt('reminder_minute') ?? 0,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminders', state.dailyReminders);
    await prefs.setBool('weekly_reports', state.weeklyReports);
    await prefs.setBool('monthly_reports', state.monthlyReports);
    await prefs.setBool('budget_alerts', state.budgetAlerts);
    await prefs.setBool('push_notifications', state.pushNotifications);
    await prefs.setInt('reminder_hour', state.reminderHour);
    await prefs.setInt('reminder_minute', state.reminderMinute);
  }

  Future<void> updateDailyReminders(bool enabled) async {
    state = state.copyWith(dailyReminders: enabled);
    await _saveSettings();
    await _updateNotificationSchedule();
  }

  Future<void> updateWeeklyReports(bool enabled) async {
    state = state.copyWith(weeklyReports: enabled);
    await _saveSettings();
    await _updateNotificationSchedule();
  }

  Future<void> updateMonthlyReports(bool enabled) async {
    state = state.copyWith(monthlyReports: enabled);
    await _saveSettings();
    await _updateNotificationSchedule();
  }

  Future<void> updateBudgetAlerts(bool enabled) async {
    state = state.copyWith(budgetAlerts: enabled);
    await _saveSettings();
  }

  Future<void> updatePushNotifications(bool enabled) async {
    if (enabled) {
      // Request permission first
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        return; // Don't update if permission denied
      }
    }

    state = state.copyWith(pushNotifications: enabled);
    await _saveSettings();
    await _updatePushNotificationSubscriptions();
  }

  Future<void> updateReminderTime(int hour, int minute) async {
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    await _saveSettings();
    
    if (state.dailyReminders) {
      await _updateNotificationSchedule();
    }
  }

  Future<void> _updateNotificationSchedule() async {
    // Cancel all scheduled notifications first
    await _notificationService.cancelAllNotifications();
    
    // Set up new notifications based on current settings
    if (state.dailyReminders) {
      await _notificationService.scheduleDailyReminder(
        TimeOfDay(hour: state.reminderHour, minute: state.reminderMinute)
      );
    }
    
    if (state.weeklyReports) {
      await _notificationService.scheduleWeeklyReport();
    }
    
    if (state.monthlyReports) {
      await _notificationService.scheduleMonthlyReport();
    }
  }

  Future<void> _updatePushNotificationSubscriptions() async {
    if (state.pushNotifications) {
      // Initialize Firebase and subscribe to topics
      await _firebaseService.initialize();
      
      if (state.budgetAlerts) {
        await _firebaseService.subscribeToTopic('budget_alerts');
      }
      if (state.weeklyReports) {
        await _firebaseService.subscribeToTopic('weekly_summaries');
      }
      if (state.monthlyReports) {
        await _firebaseService.subscribeToTopic('monthly_summaries');
      }
    } else {
      // Unsubscribe from all topics
      await _firebaseService.unsubscribeFromTopic('budget_alerts');
      await _firebaseService.unsubscribeFromTopic('weekly_summaries');
      await _firebaseService.unsubscribeFromTopic('monthly_summaries');
    }
  }

  Future<void> initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.setupDefaultReminders();
    
    if (state.pushNotifications) {
      await _firebaseService.initialize();
      await _updatePushNotificationSubscriptions();
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  Future<void> testLocalNotification() async {
    await _notificationService.showInstantNotification(
      title: '💰 Test Notification',
      body: 'This is a test notification from Expense Tracker!',
      payload: 'test',
    );
  }

  Future<void> testBudgetAlert() async {
    await _notificationService.showBudgetAlert(
      categoryName: 'Food',
      spentAmount: 850.0,
      budgetLimit: 1000.0,
    );
  }
}

// Provider for checking if notifications are initialized
final notificationInitializedProvider = FutureProvider<bool>((ref) async {
  final notificationSettings = ref.watch(notificationSettingsProvider.notifier);
  await notificationSettings.initializeNotifications();
  return true;
});

// Helper extension for TimeOfDay
extension TimeOfDayExtension on TimeOfDay {
  static TimeOfDay fromSettings(NotificationSettings settings) {
    return TimeOfDay(hour: settings.reminderHour, minute: settings.reminderMinute);
  }
}
