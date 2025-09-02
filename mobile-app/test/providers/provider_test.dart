import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/providers/category_provider.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('TransactionProvider Tests', () {
    late MockApiService mockApiService;
    late ProviderContainer container;

    setUp(() {
      mockApiService = MockApiService();
      TestHelpers.setupMockApiService(mockApiService);
      
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should load transactions on initialization', () async {
      final transactionNotifier = container.read(transactionProvider.notifier);
      await transactionNotifier.loadTransactions();

      final state = container.read(transactionProvider);
      expect(state.transactions.length, equals(3));
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('should add transaction successfully', () async {
      final transactionNotifier = container.read(transactionProvider.notifier);
      
      final newTransaction = Transaction(
        amount: 75000,
        description: 'New transaction',
        date: DateTime.now(),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      await transactionNotifier.addTransaction(newTransaction);

      verify(mockApiService.createTransaction(any)).called(1);
      
      final state = container.read(transactionProvider);
      expect(state.transactions.any((t) => t.description == 'New transaction'), isTrue);
    });

    test('should update transaction successfully', () async {
      final transactionNotifier = container.read(transactionProvider.notifier);
      await transactionNotifier.loadTransactions();

      final updatedTransaction = Transaction(
        id: 1,
        amount: 60000,
        description: 'Updated lunch',
        date: DateTime.now(),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      await transactionNotifier.updateTransaction(updatedTransaction);

      verify(mockApiService.updateTransaction(1, any)).called(1);
      
      final state = container.read(transactionProvider);
      final transaction = state.transactions.firstWhere((t) => t.id == 1);
      expect(transaction.description, equals('Updated lunch'));
      expect(transaction.amount, equals(60000));
    });

    test('should delete transaction successfully', () async {
      final transactionNotifier = container.read(transactionProvider.notifier);
      await transactionNotifier.loadTransactions();

      await transactionNotifier.deleteTransaction(1);

      verify(mockApiService.deleteTransaction(1)).called(1);
      
      final state = container.read(transactionProvider);
      expect(state.transactions.any((t) => t.id == 1), isFalse);
    });

    test('should filter transactions by type', () async {
      final transactionNotifier = container.read(transactionProvider.notifier);
      await transactionNotifier.loadTransactions();

      transactionNotifier.setTransactionTypeFilter('expense');

      final state = container.read(transactionProvider);
      expect(state.filteredTransactions.every((t) => t.type == 'expense'), isTrue);
    });

    test('should filter transactions by category', () async {
      final transactionNotifier = container.read(transactionProvider.notifier);
      await transactionNotifier.loadTransactions();

      transactionNotifier.setCategoryFilter(1);

      final state = container.read(transactionProvider);
      expect(state.filteredTransactions.every((t) => t.categoryId == 1), isTrue);
    });

    test('should filter transactions by date range', () async {
      final transactionNotifier = container.read(transactionProvider.notifier);
      await transactionNotifier.loadTransactions();

      final startDate = DateTime(2025, 9, 1);
      final endDate = DateTime(2025, 9, 30);

      transactionNotifier.setDateRangeFilter(startDate, endDate);

      final state = container.read(transactionProvider);
      expect(
        state.filteredTransactions.every((t) => 
          t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endDate.add(const Duration(days: 1)))
        ), 
        isTrue
      );
    });

    test('should handle API errors gracefully', () async {
      when(mockApiService.getTransactions()).thenThrow(Exception('Network error'));

      final transactionNotifier = container.read(transactionProvider.notifier);
      await transactionNotifier.loadTransactions();

      final state = container.read(transactionProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      expect(state.error, contains('Network error'));
    });

    test('should calculate total income and expenses correctly', () async {
      final transactionNotifier = container.read(transactionProvider.notifier);
      await transactionNotifier.loadTransactions();

      final state = container.read(transactionProvider);
      expect(state.totalIncome, equals(3000000)); // Monthly salary
      expect(state.totalExpense, equals(75000)); // Lunch + Bus fare
      expect(state.netAmount, equals(2925000)); // Income - Expenses
    });
  });

  group('CategoryProvider Tests', () {
    late MockApiService mockApiService;
    late ProviderContainer container;

    setUp(() {
      mockApiService = MockApiService();
      TestHelpers.setupMockApiService(mockApiService);
      
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should load categories on initialization', () async {
      final categoryNotifier = container.read(categoryProvider.notifier);
      await categoryNotifier.loadCategories();

      final state = container.read(categoryProvider);
      expect(state.categories.length, equals(3));
      expect(state.isLoading, isFalse);
    });

    test('should filter categories by type', () async {
      final categoryNotifier = container.read(categoryProvider.notifier);
      await categoryNotifier.loadCategories();

      final expenseCategories = categoryNotifier.getCategoriesByType('expense');
      final incomeCategories = categoryNotifier.getCategoriesByType('income');

      expect(expenseCategories.length, equals(2));
      expect(incomeCategories.length, equals(1));
      expect(expenseCategories.every((c) => c.type == 'expense'), isTrue);
      expect(incomeCategories.every((c) => c.type == 'income'), isTrue);
    });

    test('should add category successfully', () async {
      final categoryNotifier = container.read(categoryProvider.notifier);
      
      final newCategory = Category(
        name: 'Entertainment',
        icon: '🎮',
        color: const Color(0xFF9C27B0),
        type: 'expense',
        userId: 1,
      );

      await categoryNotifier.addCategory(newCategory);

      verify(mockApiService.createCategory(any)).called(1);
      
      final state = container.read(categoryProvider);
      expect(state.categories.any((c) => c.name == 'Entertainment'), isTrue);
    });

    test('should update category successfully', () async {
      final categoryNotifier = container.read(categoryProvider.notifier);
      await categoryNotifier.loadCategories();

      final updatedCategory = Category(
        id: 1,
        name: 'Updated Food',
        icon: '🍕',
        color: const Color(0xFFFF5722),
        type: 'expense',
        userId: 1,
      );

      await categoryNotifier.updateCategory(updatedCategory);

      verify(mockApiService.updateCategory(1, any)).called(1);
      
      final state = container.read(categoryProvider);
      final category = state.categories.firstWhere((c) => c.id == 1);
      expect(category.name, equals('Updated Food'));
      expect(category.icon, equals('🍕'));
    });

    test('should delete category successfully', () async {
      final categoryNotifier = container.read(categoryProvider.notifier);
      await categoryNotifier.loadCategories();

      await categoryNotifier.deleteCategory(1);

      verify(mockApiService.deleteCategory(1)).called(1);
      
      final state = container.read(categoryProvider);
      expect(state.categories.any((c) => c.id == 1), isFalse);
    });
  });

  group('AuthProvider Tests', () {
    late MockAuthService mockAuthService;
    late ProviderContainer container;

    setUp(() {
      mockAuthService = MockAuthService();
      TestHelpers.setupMockAuthService(mockAuthService);
      
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should login successfully with valid credentials', () async {
      final authNotifier = container.read(authProvider.notifier);
      
      await authNotifier.login('test@example.com', 'testpassword123');

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, isNotNull);
      expect(state.error, isNull);
    });

    test('should fail login with invalid credentials', () async {
      final authNotifier = container.read(authProvider.notifier);
      
      await authNotifier.login('test@example.com', 'wrongpassword');

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.error, isNotNull);
    });

    test('should register successfully', () async {
      final authNotifier = container.read(authProvider.notifier);
      
      await authNotifier.register(
        'newuser@example.com',
        'password123',
        'newuser',
        'New User'
      );

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, isNotNull);
      expect(state.user?.email, equals('newuser@example.com'));
    });

    test('should logout successfully', () async {
      final authNotifier = container.read(authProvider.notifier);
      
      // First login
      await authNotifier.login('test@example.com', 'testpassword123');
      expect(container.read(authProvider).isAuthenticated, isTrue);
      
      // Then logout
      await authNotifier.logout();

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
    });

    test('should check authentication status on initialization', () async {
      final authNotifier = container.read(authProvider.notifier);
      
      await authNotifier.checkAuthStatus();

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue); // Mock service returns true
      expect(state.user, isNotNull);
    });

    test('should handle authentication errors gracefully', () async {
      when(mockAuthService.login(any, any)).thenThrow(Exception('Network error'));
      
      final authNotifier = container.read(authProvider.notifier);
      
      await authNotifier.login('test@example.com', 'testpassword123');

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, isNotNull);
      expect(state.error, contains('Network error'));
    });
  });
}
