import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/screens/transaction/add_transaction_screen.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/providers/category_provider.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';

void main() {
  group('Transaction Form Widget Tests', () {
    late List<Category> mockCategories;

    setUpAll(() {
      mockCategories = [
        Category(
          id: 1,
          name: 'Food & Dining',
          type: TransactionType.expense,
          color: '#FF5722',
          icon: 'restaurant',
          userId: 1,
        ),
        Category(
          id: 2,
          name: 'Transportation',
          type: TransactionType.expense,
          color: '#2196F3',
          icon: 'directions_car',
          userId: 1,
        ),
        Category(
          id: 3,
          name: 'Salary',
          type: TransactionType.income,
          color: '#4CAF50',
          icon: 'work',
          userId: 1,
        ),
      ];
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) => mockCategories),
        ],
        child: MaterialApp(
          home: AddTransactionScreen(),
        ),
      );
    }

    testWidgets('Transaction form should display all required fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check if all form fields are present
      expect(find.byKey(const Key('amount_field')), findsOneWidget);
      expect(find.byKey(const Key('description_field')), findsOneWidget);
      expect(find.byKey(const Key('date_picker')), findsOneWidget);
      expect(find.byKey(const Key('transaction_type_toggle')), findsOneWidget);
      expect(find.byKey(const Key('category_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('save_button')), findsOneWidget);
    });

    testWidgets('Amount field should accept valid numeric input',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final amountField = find.byKey(const Key('amount_field'));
      
      // Enter valid amount
      await tester.enterText(amountField, '50.75');
      await tester.pump();

      expect(find.text('50.75'), findsOneWidget);
    });

    testWidgets('Amount field should show error for invalid input',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final amountField = find.byKey(const Key('amount_field'));
      final saveButton = find.byKey(const Key('save_button'));

      // Enter invalid amount
      await tester.enterText(amountField, '-10');
      await tester.pump();

      // Try to save
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Amount must be greater than 0'), findsOneWidget);
    });

    testWidgets('Description field should accept text input',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final descriptionField = find.byKey(const Key('description_field'));
      
      await tester.enterText(descriptionField, 'Lunch at restaurant');
      await tester.pump();

      expect(find.text('Lunch at restaurant'), findsOneWidget);
    });

    testWidgets('Date picker should show date selection dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final datePicker = find.byKey(const Key('date_picker'));
      
      await tester.tap(datePicker);
      await tester.pumpAndSettle();

      // Should show date picker dialog
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('Transaction type toggle should switch between expense and income',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final typeToggle = find.byKey(const Key('transaction_type_toggle'));
      
      // Initially should be expense
      expect(find.text('Expense'), findsOneWidget);

      // Tap to switch to income
      await tester.tap(find.text('Income'));
      await tester.pump();

      // Should show income categories
      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets('Category dropdown should show filtered categories based on type',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final categoryDropdown = find.byKey(const Key('category_dropdown'));
      
      // Tap dropdown
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();

      // Should show expense categories (default)
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
      // Should not show income categories
      expect(find.text('Salary'), findsNothing);
    });

    testWidgets('Form validation should prevent submission with empty required fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('save_button'));
      
      // Try to save without filling required fields
      await tester.tap(saveButton);
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter an amount'), findsOneWidget);
      expect(find.text('Please enter a description'), findsOneWidget);
      expect(find.text('Please select a category'), findsOneWidget);
    });

    testWidgets('Form should submit successfully with valid data',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Fill in all required fields
      await tester.enterText(
        find.byKey(const Key('amount_field')), 
        '25.50'
      );
      await tester.enterText(
        find.byKey(const Key('description_field')), 
        'Coffee and snacks'
      );

      // Select a category
      await tester.tap(find.byKey(const Key('category_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pump();

      // Should navigate back or show success message
      // This would depend on your implementation
    });

    testWidgets('Form should handle category selection correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final categoryDropdown = find.byKey(const Key('category_dropdown'));
      
      // Select a category
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transportation'));
      await tester.pumpAndSettle();

      // Verify category is selected
      expect(find.text('Transportation'), findsOneWidget);
    });

    testWidgets('Form should reset when switching transaction types',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Select expense category
      await tester.tap(find.byKey(const Key('category_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();

      // Switch to income
      await tester.tap(find.text('Income'));
      await tester.pump();

      // Category should be cleared
      expect(find.text('Select Category'), findsOneWidget);
    });

    testWidgets('Amount field should format decimal input correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final amountField = find.byKey(const Key('amount_field'));
      
      // Test various decimal inputs
      await tester.enterText(amountField, '1.5');
      await tester.pump();
      expect(find.text('1.5'), findsOneWidget);

      await tester.enterText(amountField, '1.50');
      await tester.pump();
      expect(find.text('1.50'), findsOneWidget);

      await tester.enterText(amountField, '100');
      await tester.pump();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('Save button should be disabled when form is invalid',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('save_button'));
      
      // Initially button should be disabled (if implemented)
      final button = tester.widget<ElevatedButton>(saveButton);
      expect(button.onPressed, isNull);
    });
  });

  group('Transaction Form Edge Cases', () {
    testWidgets('Should handle very large amounts',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final amountField = find.byKey(const Key('amount_field'));
      
      await tester.enterText(amountField, '999999.99');
      await tester.pump();

      expect(find.text('999999.99'), findsOneWidget);
    });

    testWidgets('Should handle very long descriptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final descriptionField = find.byKey(const Key('description_field'));
      const longDescription = 'This is a very long description that should be handled properly by the form and should not break the UI even if it exceeds normal length limits';
      
      await tester.enterText(descriptionField, longDescription);
      await tester.pump();

      expect(find.text(longDescription), findsOneWidget);
    });

    testWidgets('Should handle special characters in description',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final descriptionField = find.byKey(const Key('description_field'));
      const specialDescription = 'Café & Restaurant @ 123 Main St. (50% off!)';
      
      await tester.enterText(descriptionField, specialDescription);
      await tester.pump();

      expect(find.text(specialDescription), findsOneWidget);
    });
  });
}

Widget createWidgetUnderTest() {
  return ProviderScope(
    child: MaterialApp(
      home: AddTransactionScreen(),
    ),
  );
}
