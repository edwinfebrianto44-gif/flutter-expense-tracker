import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/firebase_messaging_service.dart';
import '../generated/l10n.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _dailyReminders = false;
  bool _weeklyReports = false;
  bool _monthlyReports = false;
  bool _budgetAlerts = false;
  bool _pushNotifications = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  
  final NotificationService _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminders = prefs.getBool('daily_reminders') ?? false;
      _weeklyReports = prefs.getBool('weekly_reports') ?? false;
      _monthlyReports = prefs.getBool('monthly_reports') ?? false;
      _budgetAlerts = prefs.getBool('budget_alerts') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? false;
      
      final hour = prefs.getInt('reminder_hour') ?? 20;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminders', _dailyReminders);
    await prefs.setBool('weekly_reports', _weeklyReports);
    await prefs.setBool('monthly_reports', _monthlyReports);
    await prefs.setBool('budget_alerts', _budgetAlerts);
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);
  }

  Future<void> _updateNotificationSettings() async {
    await _saveSettings();
    
    // Cancel all scheduled notifications first
    await _notificationService.cancelAllNotifications();
    
    // Set up new notifications based on settings
    if (_dailyReminders) {
      await _notificationService.scheduleDailyReminder(_reminderTime);
    }
    
    if (_weeklyReports) {
      await _notificationService.scheduleWeeklyReport();
    }
    
    if (_monthlyReports) {
      await _notificationService.scheduleMonthlyReport();
    }
    
    // Initialize or disable push notifications
    if (_pushNotifications) {
      final firebaseService = ref.read(firebaseMessagingServiceProvider);
      await firebaseService.initialize();
      
      // Subscribe to relevant topics
      await firebaseService.subscribeToTopic('budget_alerts');
      await firebaseService.subscribeToTopic('weekly_summaries');
      await firebaseService.subscribeToTopic('monthly_summaries');
    } else {
      final firebaseService = ref.read(firebaseMessagingServiceProvider);
      
      // Unsubscribe from topics
      await firebaseService.unsubscribeFromTopic('budget_alerts');
      await firebaseService.unsubscribeFromTopic('weekly_summaries');
      await firebaseService.unsubscribeFromTopic('monthly_summaries');
    }
    
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.success['dataSaved'] ?? 'Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationSettings),
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Local Notifications'),
            const SizedBox(height: 8),
            _buildNotificationCard(
              icon: Icons.schedule,
              title: l10n.dailyReminders,
              subtitle: 'Get reminded to record your daily transactions',
              value: _dailyReminders,
              onChanged: (value) {
                setState(() {
                  _dailyReminders = value;
                });
              },
            ),
            
            if (_dailyReminders) ...[
              const SizedBox(height: 8),
              _buildTimeSelector(l10n),
            ],
            
            const SizedBox(height: 16),
            _buildNotificationCard(
              icon: Icons.bar_chart,
              title: l10n.weeklyReports,
              subtitle: 'Receive weekly spending summaries',
              value: _weeklyReports,
              onChanged: (value) {
                setState(() {
                  _weeklyReports = value;
                });
              },
            ),
            
            const SizedBox(height: 8),
            _buildNotificationCard(
              icon: Icons.calendar_month,
              title: l10n.monthlyReports,
              subtitle: 'Get monthly financial summaries',
              value: _monthlyReports,
              onChanged: (value) {
                setState(() {
                  _monthlyReports = value;
                });
              },
            ),
            
            const SizedBox(height: 8),
            _buildNotificationCard(
              icon: Icons.warning_amber,
              title: l10n.budgetAlerts,
              subtitle: 'Alert when you exceed budget limits',
              value: _budgetAlerts,
              onChanged: (value) {
                setState(() {
                  _budgetAlerts = value;
                });
              },
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Push Notifications'),
            const SizedBox(height: 8),
            _buildNotificationCard(
              icon: Icons.cloud_queue,
              title: l10n.pushNotifications,
              subtitle: 'Receive notifications even when app is closed',
              value: _pushNotifications,
              onChanged: (value) async {
                if (value) {
                  // Request permission first
                  final hasPermission = await _notificationService.requestPermissions();
                  if (!hasPermission) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification permission is required'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                }
                setState(() {
                  _pushNotifications = value;
                });
              },
            ),
            
            const SizedBox(height: 32),
            _buildActionButtons(l10n),
            
            const SizedBox(height: 24),
            _buildTestNotificationSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          icon,
          color: value ? Colors.blue : Colors.grey,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTimeSelector(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(left: 16),
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Colors.blue),
        title: Text(l10n.reminderTime),
        subtitle: Text(_reminderTime.format(context)),
        trailing: const Icon(Icons.chevron_right),
        onTap: _selectReminderTime,
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _updateNotificationSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.save,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              await _notificationService.cancelAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cancelled'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestNotificationSection(AppLocalizations l10n) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.testNotification,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _notificationService.showInstantNotification(
                        title: '💰 Test Notification',
                        body: 'This is a test notification from Expense Tracker!',
                        payload: 'test',
                      );
                    },
                    icon: const Icon(Icons.notifications, size: 20),
                    label: const Text('Test Local'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _notificationService.showBudgetAlert(
                        categoryName: 'Food',
                        spentAmount: 850.0,
                        budgetLimit: 1000.0,
                      );
                    },
                    icon: const Icon(Icons.warning, size: 20),
                    label: const Text('Test Budget'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
