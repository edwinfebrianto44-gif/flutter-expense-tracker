import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/custom_card.dart';
import '../../utils/formatters.dart';
import '../../generated/l10n.dart';
import 'widgets/balance_card.dart';
import 'widgets/chart_card.dart';
import 'widgets/recent_transactions_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final transactions = ref.watch(transactionProvider);
    final themeState = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.hello(authState.user?.name ?? 'User'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              DateFormatter.formatDate(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeState.themeMode == AppThemeMode.dark 
                  ? Icons.light_mode 
                  : Icons.dark_mode
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            tooltip: themeState.themeMode == AppThemeMode.dark 
                ? l10n.lightMode 
                : l10n.darkMode,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'categories':
                  context.pushNamed('categories');
                  break;
                case 'reports':
                  context.pushNamed('reports');
                  break;
                case 'notifications':
                  context.pushNamed('notification-settings');
                  break;
                case 'settings':
                  context.pushNamed('settings');
                  break;
                case 'logout':
                  _showLogoutDialog(context, ref, l10n);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined),
                    const SizedBox(width: 12),
                    Text(l10n.manageCategories),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined),
                    const SizedBox(width: 12),
                    Text(l10n.reportsAndAnalytics),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'notifications',
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    const SizedBox(width: 12),
                    Text(l10n.notificationSettings),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined),
                    const SizedBox(width: 12),
                    Text(l10n.settings),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 12),
                    Text(l10n.logout),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data from backend in real implementation
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Cards
              const BalanceCard(),
              const SizedBox(height: 16),
              
              // Chart Card
              const ChartCard(),
              const SizedBox(height: 16),
              
              // Recent Transactions
              const RecentTransactionsCard(),
              const SizedBox(height: 100), // For FAB spacing
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('add-transaction'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addTransaction),
        heroTag: 'add_transaction_fab',
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authStateProvider.notifier).logout();
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
