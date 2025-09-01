import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/transaction/add_transaction_screen.dart';
import '../screens/transaction/edit_transaction_screen.dart';
import '../screens/category/category_management_screen.dart';
import '../screens/splash_screen.dart';
import '../models/transaction.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.isAuthenticated;
      final location = state.uri.path;

      // Show splash while loading
      if (isLoading && location != '/splash') {
        return '/splash';
      }

      // Redirect to login if not authenticated
      if (!isAuthenticated && 
          location != '/login' && 
          location != '/register' && 
          location != '/splash') {
        return '/login';
      }

      // Redirect to dashboard if authenticated and on auth pages
      if (isAuthenticated && 
          (location == '/login' || location == '/register' || location == '/splash')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
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
        routes: [
          GoRoute(
            path: 'add-transaction',
            name: 'add-transaction',
            builder: (context, state) => const AddTransactionScreen(),
          ),
          GoRoute(
            path: 'edit-transaction/:id',
            name: 'edit-transaction',
            builder: (context, state) {
              final transactionId = int.parse(state.pathParameters['id']!);
              final transaction = state.extra as Transaction?;
              return EditTransactionScreen(
                transactionId: transactionId,
                transaction: transaction,
              );
            },
          ),
          GoRoute(
            path: 'categories',
            name: 'categories',
            builder: (context, state) => const CategoryManagementScreen(),
          ),
        ],
      ),
    ],
  );
});
