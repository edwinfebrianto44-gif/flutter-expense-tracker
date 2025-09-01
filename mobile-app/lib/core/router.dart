import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/transaction/add_transaction_screen.dart';
import '../screens/transaction/edit_transaction_screen.dart';
import '../screens/category/category_management_screen.dart';
import '../screens/notification_settings_page.dart';
import '../screens/settings_page.dart';
import '../pages/reports_page.dart';
import '../models/transaction.dart';
import '../generated/l10n.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      
      // Show splash screen while loading
      if (isLoading) {
        return '/';
      }
      
      final isGoingToLogin = state.fullPath == '/login';
      final isGoingToRegister = state.fullPath == '/register';
      
      // If not logged in and not going to auth pages, redirect to login
      if (!isLoggedIn && !isGoingToLogin && !isGoingToRegister) {
        return '/login';
      }
      
      // If logged in and going to auth pages, redirect to dashboard
      if (isLoggedIn && (isGoingToLogin || isGoingToRegister || state.fullPath == '/')) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/add-transaction',
        name: 'add-transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/edit-transaction/:id',
        name: 'edit-transaction',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final transaction = state.extra as Transaction?;
          return EditTransactionScreen(
            transactionId: id,
            transaction: transaction,
          );
        },
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/notification-settings',
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.pageNotFound ?? 'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.goNamed('dashboard'),
                child: Text(l10n?.backToDashboard ?? 'Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    },
  );
});
