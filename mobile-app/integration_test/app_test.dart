import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Expense Tracker Integration Tests', () {
    testWidgets('Complete user flow: login → add transaction → view in dashboard', 
        (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      await tester.pumpAndSettle();

      // Step 1: Navigate to login screen if not logged in
      if (find.text('Login').isNotEmpty) {
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();

        // Fill login form
        await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), 'testpassword123');
        
        // Tap login button
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Step 2: Verify we're on the dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byKey(const Key('add_transaction_fab')), findsOneWidget);

      // Step 3: Navigate to add transaction screen
      await tester.tap(find.byKey(const Key('add_transaction_fab')));
      await tester.pumpAndSettle();

      // Step 4: Fill transaction form
      expect(find.text('Add Transaction'), findsOneWidget);
      
      // Enter amount
      await tester.enterText(find.byKey(const Key('amount_field')), '25000');
      await tester.pump();

      // Enter description
      await tester.enterText(find.byKey(const Key('description_field')), 'Coffee and snacks');
      await tester.pump();

      // Select category
      await tester.tap(find.byKey(const Key('category_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();

      // Select transaction type (if not default)
      if (find.text('Expense').isNotEmpty) {
        await tester.tap(find.text('Expense'));
        await tester.pump();
      }

      // Save transaction
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 5: Verify we're back on dashboard
      expect(find.text('Dashboard'), findsOneWidget);

      // Step 6: Verify transaction appears in the list
      expect(find.text('Coffee and snacks'), findsOneWidget);
      expect(find.text('Rp 25,000'), findsOneWidget);
      expect(find.text('Food & Dining'), findsOneWidget);

      // Step 7: Verify dashboard statistics are updated
      expect(find.byKey(const Key('total_expense_card')), findsOneWidget);
      expect(find.byKey(const Key('recent_transactions_list')), findsOneWidget);
    });

    testWidgets('Test navigation between all major screens', 
        (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      await tester.pumpAndSettle();

      // Ensure we're logged in (or skip if login is required)
      if (find.text('Dashboard').isEmpty) {
        // Perform login steps if needed
        await _performLogin(tester);
      }

      // Test bottom navigation
      expect(find.byKey(const Key('bottom_nav_dashboard')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_transactions')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_categories')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_profile')), findsOneWidget);

      // Navigate to Transactions screen
      await tester.tap(find.byKey(const Key('bottom_nav_transactions')));
      await tester.pumpAndSettle();
      expect(find.text('Transactions'), findsOneWidget);

      // Navigate to Categories screen
      await tester.tap(find.byKey(const Key('bottom_nav_categories')));
      await tester.pumpAndSettle();
      expect(find.text('Categories'), findsOneWidget);

      // Navigate to Profile screen
      await tester.tap(find.byKey(const Key('bottom_nav_profile')));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);

      // Navigate back to Dashboard
      await tester.tap(find.byKey(const Key('bottom_nav_dashboard')));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Test add category flow', 
        (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      await tester.pumpAndSettle();

      // Ensure we're logged in
      if (find.text('Dashboard').isEmpty) {
        await _performLogin(tester);
      }

      // Navigate to Categories screen
      await tester.tap(find.byKey(const Key('bottom_nav_categories')));
      await tester.pumpAndSettle();

      // Tap add category button
      await tester.tap(find.byKey(const Key('add_category_fab')));
      await tester.pumpAndSettle();

      // Fill category form
      await tester.enterText(find.byKey(const Key('category_name_field')), 'Test Category');
      await tester.pump();

      // Select category type
      await tester.tap(find.text('Expense'));
      await tester.pump();

      // Select icon (if available)
      if (find.byKey(const Key('icon_selector')).isNotEmpty) {
        await tester.tap(find.byKey(const Key('icon_selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('🎯')); // Select an icon
        await tester.pump();
      }

      // Save category
      await tester.tap(find.byKey(const Key('save_category_button')));
      await tester.pumpAndSettle();

      // Verify category was added
      expect(find.text('Test Category'), findsOneWidget);
    });

    testWidgets('Test transaction filtering and searching', 
        (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      await tester.pumpAndSettle();

      // Ensure we're logged in
      if (find.text('Dashboard').isEmpty) {
        await _performLogin(tester);
      }

      // Navigate to Transactions screen
      await tester.tap(find.byKey(const Key('bottom_nav_transactions')));
      await tester.pumpAndSettle();

      // Test search functionality
      if (find.byKey(const Key('search_field')).isNotEmpty) {
        await tester.enterText(find.byKey(const Key('search_field')), 'coffee');
        await tester.pump();
        
        // Should filter transactions containing 'coffee'
        expect(find.text('Coffee and snacks'), findsWidgets);
      }

      // Test filter by type
      if (find.byKey(const Key('filter_expense')).isNotEmpty) {
        await tester.tap(find.byKey(const Key('filter_expense')));
        await tester.pump();
        
        // Should show only expense transactions
      }

      // Test filter by date range
      if (find.byKey(const Key('date_range_filter')).isNotEmpty) {
        await tester.tap(find.byKey(const Key('date_range_filter')));
        await tester.pumpAndSettle();
        
        // Date picker should appear
        expect(find.byType(DateRangePickerDialog), findsOneWidget);
      }
    });

    testWidgets('Test transaction edit and delete', 
        (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      await tester.pumpAndSettle();

      // Ensure we're logged in
      if (find.text('Dashboard').isEmpty) {
        await _performLogin(tester);
      }

      // Navigate to Transactions screen
      await tester.tap(find.byKey(const Key('bottom_nav_transactions')));
      await tester.pumpAndSettle();

      // Tap on a transaction to view details
      if (find.text('Coffee and snacks').isNotEmpty) {
        await tester.tap(find.text('Coffee and snacks'));
        await tester.pumpAndSettle();

        // Should show transaction details
        expect(find.byKey(const Key('edit_transaction_button')), findsOneWidget);
        expect(find.byKey(const Key('delete_transaction_button')), findsOneWidget);

        // Test edit transaction
        await tester.tap(find.byKey(const Key('edit_transaction_button')));
        await tester.pumpAndSettle();

        // Modify amount
        await tester.enterText(find.byKey(const Key('amount_field')), '30000');
        await tester.pump();

        // Save changes
        await tester.tap(find.byKey(const Key('save_button')));
        await tester.pumpAndSettle();

        // Verify changes
        expect(find.text('Rp 30,000'), findsOneWidget);
      }
    });

    testWidgets('Test logout flow', 
        (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      await tester.pumpAndSettle();

      // Ensure we're logged in
      if (find.text('Dashboard').isEmpty) {
        await _performLogin(tester);
      }

      // Navigate to Profile screen
      await tester.tap(find.byKey(const Key('bottom_nav_profile')));
      await tester.pumpAndSettle();

      // Tap logout button
      if (find.byKey(const Key('logout_button')).isNotEmpty) {
        await tester.tap(find.byKey(const Key('logout_button')));
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        if (find.text('Confirm Logout').isNotEmpty) {
          await tester.tap(find.text('Logout'));
          await tester.pumpAndSettle();
        }

        // Should return to login screen
        expect(find.text('Login'), findsOneWidget);
      }
    });

    testWidgets('Test app state persistence across restarts', 
        (WidgetTester tester) async {
      // This test simulates app restart to check if login state persists
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      await tester.pumpAndSettle();

      // If token is stored, should go directly to dashboard
      // If not, should show login screen
      final hasLoginScreen = find.text('Login').isNotEmpty;
      final hasDashboard = find.text('Dashboard').isNotEmpty;
      
      expect(hasLoginScreen || hasDashboard, isTrue);
    });
  });

  group('Error Handling Integration Tests', () {
    testWidgets('Test network error handling', 
        (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      await tester.pumpAndSettle();

      // Try to perform actions that require network
      // These should gracefully handle network errors
      
      // Test login with network error
      if (find.text('Login').isNotEmpty) {
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), 'wrongpassword');
        
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Should show error message
        expect(find.text('Invalid credentials'), findsOneWidget);
      }
    });

    testWidgets('Test form validation', 
        (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      await tester.pumpAndSettle();

      // Navigate to add transaction (assume logged in)
      if (find.byKey(const Key('add_transaction_fab')).isNotEmpty) {
        await tester.tap(find.byKey(const Key('add_transaction_fab')));
        await tester.pumpAndSettle();

        // Try to save without filling required fields
        await tester.tap(find.byKey(const Key('save_button')));
        await tester.pump();

        // Should show validation errors
        expect(find.text('Please enter an amount'), findsOneWidget);
        expect(find.text('Please enter a description'), findsOneWidget);
      }
    });
  });
}

Future<void> _performLogin(WidgetTester tester) async {
  if (find.text('Login').isNotEmpty) {
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'testpassword123');
    
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
