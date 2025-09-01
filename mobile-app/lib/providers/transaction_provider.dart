import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier();
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  TransactionNotifier() : super(demoTransactions);

  void addTransaction(Transaction transaction) {
    state = [...state, transaction];
  }

  void updateTransaction(Transaction transaction) {
    state = state.map((t) => t.id == transaction.id ? transaction : t).toList();
  }

  void deleteTransaction(int id) {
    state = state.where((t) => t.id != id).toList();
  }

  List<Transaction> getTransactionsByType(String type) {
    return state.where((t) => t.type == type).toList();
  }

  List<Transaction> getRecentTransactions({int limit = 5}) {
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  double getTotalIncome() {
    return state
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpense() {
    return state
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getBalance() {
    return getTotalIncome() - getTotalExpense();
  }

  Map<String, double> getMonthlyData() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    
    double thisMonthIncome = 0;
    double thisMonthExpense = 0;
    double lastMonthIncome = 0;
    double lastMonthExpense = 0;

    for (final transaction in state) {
      final transactionMonth = DateTime(transaction.date.year, transaction.date.month);
      
      if (transactionMonth == thisMonth) {
        if (transaction.type == 'income') {
          thisMonthIncome += transaction.amount;
        } else {
          thisMonthExpense += transaction.amount;
        }
      } else if (transactionMonth == lastMonth) {
        if (transaction.type == 'income') {
          lastMonthIncome += transaction.amount;
        } else {
          lastMonthExpense += transaction.amount;
        }
      }
    }

    return {
      'thisMonthIncome': thisMonthIncome,
      'thisMonthExpense': thisMonthExpense,
      'lastMonthIncome': lastMonthIncome,
      'lastMonthExpense': lastMonthExpense,
    };
  }
}
