import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:flutter/material.dart';

void main() {
  group('Transaction Model Tests', () {
    test('Transaction should be created with correct properties', () {
      final category = Category(
        id: 1,
        name: 'Food',
        icon: '🍔',
        color: Colors.red,
        type: 'expense',
        userId: 1,
      );

      final transaction = Transaction(
        id: 1,
        amount: 50000,
        description: 'Lunch at restaurant',
        date: DateTime(2025, 9, 1),
        type: 'expense',
        categoryId: 1,
        userId: 1,
        category: category,
      );

      expect(transaction.id, 1);
      expect(transaction.amount, 50000);
      expect(transaction.description, 'Lunch at restaurant');
      expect(transaction.type, 'expense');
      expect(transaction.categoryId, 1);
      expect(transaction.category?.name, 'Food');
    });

    test('Transaction.fromJson should create correct object', () {
      final json = {
        'id': 1,
        'amount': 50000.0,
        'description': 'Test transaction',
        'date': '2025-09-01T12:00:00.000Z',
        'type': 'expense',
        'category_id': 1,
        'user_id': 1,
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 1);
      expect(transaction.amount, 50000.0);
      expect(transaction.description, 'Test transaction');
      expect(transaction.type, 'expense');
      expect(transaction.categoryId, 1);
      expect(transaction.userId, 1);
    });

    test('Transaction.toJson should create correct map', () {
      final transaction = Transaction(
        id: 1,
        amount: 50000,
        description: 'Test transaction',
        date: DateTime(2025, 9, 1),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      final json = transaction.toJson();

      expect(json['id'], 1);
      expect(json['amount'], 50000);
      expect(json['description'], 'Test transaction');
      expect(json['type'], 'expense');
      expect(json['category_id'], 1);
      expect(json['user_id'], 1);
    });

    test('Transaction should handle different types correctly', () {
      final expenseTransaction = Transaction(
        id: 1,
        amount: 50000,
        description: 'Expense',
        date: DateTime.now(),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      final incomeTransaction = Transaction(
        id: 2,
        amount: 100000,
        description: 'Income',
        date: DateTime.now(),
        type: 'income',
        categoryId: 2,
        userId: 1,
      );

      expect(expenseTransaction.type, 'expense');
      expect(incomeTransaction.type, 'income');
    });

    test('Transaction should format amount correctly', () {
      final transaction = Transaction(
        id: 1,
        amount: 1234567,
        description: 'Large amount',
        date: DateTime.now(),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      // Assuming you have a formattedAmount getter
      expect(transaction.formattedAmount, 'Rp 1,234,567');
    });

    test('Transaction should validate amount', () {
      // Test positive amount
      final validTransaction = Transaction(
        id: 1,
        amount: 50000,
        description: 'Valid',
        date: DateTime.now(),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      expect(validTransaction.amount, greaterThan(0));

      // Test zero amount
      final zeroTransaction = Transaction(
        id: 2,
        amount: 0,
        description: 'Zero',
        date: DateTime.now(),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      expect(zeroTransaction.amount, equals(0));
    });

    test('Transaction should handle date formatting correctly', () {
      final date = DateTime(2025, 9, 1, 14, 30, 0);
      final transaction = Transaction(
        id: 1,
        amount: 50000,
        description: 'Date test',
        date: date,
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      expect(transaction.date, equals(date));
      expect(transaction.formattedDate, '01 Sep 2025'); // Assuming you have this getter
    });

    test('Transaction equality should work correctly', () {
      final transaction1 = Transaction(
        id: 1,
        amount: 50000,
        description: 'Test',
        date: DateTime(2025, 9, 1),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      final transaction2 = Transaction(
        id: 1,
        amount: 50000,
        description: 'Test',
        date: DateTime(2025, 9, 1),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      expect(transaction1 == transaction2, isTrue);
      expect(transaction1.hashCode == transaction2.hashCode, isTrue);
    });
  });

  group('Category Model Tests', () {
    test('Category should be created with correct properties', () {
      final category = Category(
        id: 1,
        name: 'Food & Dining',
        icon: '🍔',
        color: Colors.red,
        type: 'expense',
        userId: 1,
      );

      expect(category.id, 1);
      expect(category.name, 'Food & Dining');
      expect(category.icon, '🍔');
      expect(category.color, Colors.red);
      expect(category.type, 'expense');
      expect(category.userId, 1);
    });

    test('Category.fromJson should create correct object', () {
      final json = {
        'id': 1,
        'name': 'Food & Dining',
        'icon': '🍔',
        'color': '#F44336',
        'type': 'expense',
        'user_id': 1,
      };

      final category = Category.fromJson(json);

      expect(category.id, 1);
      expect(category.name, 'Food & Dining');
      expect(category.icon, '🍔');
      expect(category.type, 'expense');
      expect(category.userId, 1);
    });

    test('Category.toJson should create correct map', () {
      final category = Category(
        id: 1,
        name: 'Food & Dining',
        icon: '🍔',
        color: Colors.red,
        type: 'expense',
        userId: 1,
      );

      final json = category.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Food & Dining');
      expect(json['icon'], '🍔');
      expect(json['type'], 'expense');
      expect(json['user_id'], 1);
    });

    test('Category should handle different types correctly', () {
      final expenseCategory = Category(
        id: 1,
        name: 'Food',
        icon: '🍔',
        color: Colors.red,
        type: 'expense',
        userId: 1,
      );

      final incomeCategory = Category(
        id: 2,
        name: 'Salary',
        icon: '💼',
        color: Colors.green,
        type: 'income',
        userId: 1,
      );

      expect(expenseCategory.type, 'expense');
      expect(incomeCategory.type, 'income');
    });

    test('Category should validate color correctly', () {
      final category = Category(
        id: 1,
        name: 'Test',
        icon: '🎯',
        color: Colors.blue,
        type: 'expense',
        userId: 1,
      );

      expect(category.color, isA<Color>());
      expect(category.colorHex, startsWith('#'));
    });

    test('Category equality should work correctly', () {
      final category1 = Category(
        id: 1,
        name: 'Food',
        icon: '🍔',
        color: Colors.red,
        type: 'expense',
        userId: 1,
      );

      final category2 = Category(
        id: 1,
        name: 'Food',
        icon: '🍔',
        color: Colors.red,
        type: 'expense',
        userId: 1,
      );

      expect(category1 == category2, isTrue);
      expect(category1.hashCode == category2.hashCode, isTrue);
    });
  });

  group('Model Validation Tests', () {
    test('Should handle null values gracefully', () {
      final json = {
        'id': null,
        'amount': null,
        'description': null,
        'date': null,
        'type': null,
        'category_id': null,
        'user_id': null,
      };

      expect(() => Transaction.fromJson(json), returnsNormally);
    });

    test('Should handle empty strings', () {
      final transaction = Transaction(
        id: 1,
        amount: 50000,
        description: '',
        date: DateTime.now(),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      expect(transaction.description, isEmpty);
    });

    test('Should handle special characters in description', () {
      final transaction = Transaction(
        id: 1,
        amount: 50000,
        description: 'Café & Restaurant @ 123 Main St. (50% off!)',
        date: DateTime.now(),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      expect(transaction.description, contains('&'));
      expect(transaction.description, contains('@'));
      expect(transaction.description, contains('%'));
    });

    test('Should handle large amounts', () {
      final transaction = Transaction(
        id: 1,
        amount: 999999999,
        description: 'Large amount',
        date: DateTime.now(),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      expect(transaction.amount, equals(999999999));
    });
  });
}
      expect(transaction.amount, 50000.0);
      expect(transaction.description, 'Test transaction');
      expect(transaction.type, 'expense');
    });

    test('Transaction.toJson should create correct map', () {
      final transaction = Transaction(
        id: 1,
        amount: 50000,
        description: 'Test transaction',
        date: DateTime(2025, 9, 1),
        type: 'expense',
        categoryId: 1,
        userId: 1,
      );

      final json = transaction.toJson();

      expect(json['id'], 1);
      expect(json['amount'], 50000);
      expect(json['description'], 'Test transaction');
      expect(json['type'], 'expense');
      expect(json['category_id'], 1);
      expect(json['user_id'], 1);
    });

    test('Demo transactions should be properly initialized', () {
      expect(demoTransactions.isNotEmpty, true);
      expect(demoTransactions.length, 10);
      
      // Check first transaction
      final firstTransaction = demoTransactions.first;
      expect(firstTransaction.type, 'income');
      expect(firstTransaction.amount, 5000000);
      expect(firstTransaction.category, isNotNull);
    });
  });
}
