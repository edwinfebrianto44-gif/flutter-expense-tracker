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
