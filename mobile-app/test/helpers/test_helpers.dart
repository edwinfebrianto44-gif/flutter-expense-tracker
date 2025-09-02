import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/user.dart';

// Mock classes for testing
class MockApiService extends Mock implements ApiService {}
class MockAuthService extends Mock implements AuthService {}

// Test helper methods
class TestHelpers {
  static List<Transaction> createMockTransactions() {
    return [
      Transaction(
        id: 1,
        amount: 50000,
        description: 'Lunch at restaurant',
        date: DateTime(2025, 9, 1),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      ),
      Transaction(
        id: 2,
        amount: 25000,
        description: 'Bus fare',
        date: DateTime(2025, 9, 2),
        type: 'expense',
        categoryId: 2,
        userId: 1,
      ),
      Transaction(
        id: 3,
        amount: 3000000,
        description: 'Monthly salary',
        date: DateTime(2025, 9, 3),
        type: 'income',
        categoryId: 3,
        userId: 1,
      ),
    ];
  }

  static List<Category> createMockCategories() {
    return [
      Category(
        id: 1,
        name: 'Food & Dining',
        icon: '🍔',
        color: const Color(0xFFFF5722),
        type: 'expense',
        userId: 1,
      ),
      Category(
        id: 2,
        name: 'Transportation',
        icon: '🚗',
        color: const Color(0xFF2196F3),
        type: 'expense',
        userId: 1,
      ),
      Category(
        id: 3,
        name: 'Salary',
        icon: '💼',
        color: const Color(0xFF4CAF50),
        type: 'income',
        userId: 1,
      ),
    ];
  }

  static User createMockUser() {
    return User(
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      fullName: 'Test User',
    );
  }

  static void setupMockApiService(MockApiService mockApiService) {
    // Setup common API responses
    when(mockApiService.getTransactions()).thenAnswer(
      (_) async => createMockTransactions(),
    );

    when(mockApiService.getCategories()).thenAnswer(
      (_) async => createMockCategories(),
    );

    when(mockApiService.createTransaction(any)).thenAnswer(
      (invocation) async {
        final transaction = invocation.positionalArguments[0] as Transaction;
        return transaction.copyWith(id: 999); // Mock created transaction with ID
      },
    );

    when(mockApiService.updateTransaction(any, any)).thenAnswer(
      (invocation) async {
        final transaction = invocation.positionalArguments[1] as Transaction;
        return transaction; // Return updated transaction
      },
    );

    when(mockApiService.deleteTransaction(any)).thenAnswer(
      (_) async => true,
    );

    when(mockApiService.createCategory(any)).thenAnswer(
      (invocation) async {
        final category = invocation.positionalArguments[0] as Category;
        return category.copyWith(id: 999); // Mock created category with ID
      },
    );
  }

  static void setupMockAuthService(MockAuthService mockAuthService) {
    when(mockAuthService.login(any, any)).thenAnswer(
      (invocation) async {
        final email = invocation.positionalArguments[0] as String;
        final password = invocation.positionalArguments[1] as String;
        
        if (email == 'test@example.com' && password == 'testpassword123') {
          return 'mock_jwt_token';
        } else {
          throw Exception('Invalid credentials');
        }
      },
    );

    when(mockAuthService.register(any, any, any, any)).thenAnswer(
      (_) async => createMockUser(),
    );

    when(mockAuthService.getCurrentUser()).thenAnswer(
      (_) async => createMockUser(),
    );

    when(mockAuthService.isLoggedIn()).thenAnswer(
      (_) async => true,
    );

    when(mockAuthService.logout()).thenAnswer(
      (_) async => true,
    );
  }

  // Widget test helpers
  static Future<void> enterTextAndPump(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  static Future<void> tapAndPump(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pump();
  }

  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // Common test expectations
  static void expectTextFieldValue(String key, String expectedValue) {
    final textField = find.byKey(Key(key));
    expect(textField, findsOneWidget);
    expect(find.text(expectedValue), findsOneWidget);
  }

  static void expectWidgetExists(String key) {
    expect(find.byKey(Key(key)), findsOneWidget);
  }

  static void expectTextExists(String text) {
    expect(find.text(text), findsOneWidget);
  }

  static void expectWidgetNotExists(String key) {
    expect(find.byKey(Key(key)), findsNothing);
  }

  // Date helpers for testing
  static DateTime createTestDate(int year, int month, int day) {
    return DateTime(year, month, day);
  }

  static String formatDateForTest(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
           '${_getMonthName(date.month)} '
           '${date.year}';
  }

  static String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  // Amount formatting helpers
  static String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  // Test data validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidAmount(String amount) {
    final numericAmount = double.tryParse(amount);
    return numericAmount != null && numericAmount > 0;
  }

  static bool isValidDescription(String description) {
    return description.isNotEmpty && description.trim().length > 0;
  }

  // Mock network responses
  static Map<String, dynamic> createSuccessResponse(dynamic data) {
    return {
      'status': 'success',
      'data': data,
      'message': 'Operation successful',
    };
  }

  static Map<String, dynamic> createErrorResponse(String message) {
    return {
      'status': 'error',
      'message': message,
    };
  }

  // Test environment setup
  static void setupTestEnvironment() {
    // Add any global test setup here
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  static void tearDownTestEnvironment() {
    // Add any global test cleanup here
  }
}
