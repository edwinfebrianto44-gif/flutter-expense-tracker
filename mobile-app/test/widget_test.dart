import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/main.dart';

void main() {
  group('Expense Tracker App Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Splash screen should be displayed initially', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
      await tester.pump();
      
      // Should show loading indicator on splash screen
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Expense Tracker'), findsOneWidget);
    });
  });
}
