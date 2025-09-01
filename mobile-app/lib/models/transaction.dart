import 'category.dart';

class Transaction {
  final int id;
  final double amount;
  final String description;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final int categoryId;
  final int userId;
  final Category? category;

  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
    required this.categoryId,
    required this.userId,
    this.category,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      categoryId: json['category_id'],
      userId: json['user_id'],
      category: json['category'] != null 
          ? Category.fromJson(json['category'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
      'category_id': categoryId,
      'user_id': userId,
      if (category != null) 'category': category!.toJson(),
    };
  }

  Transaction copyWith({
    int? id,
    double? amount,
    String? description,
    DateTime? date,
    String? type,
    int? categoryId,
    int? userId,
    Category? category,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      category: category ?? this.category,
    );
  }
}

// Demo transactions
final List<Transaction> demoTransactions = [
  Transaction(
    id: 1,
    amount: 5000000,
    description: 'Gaji bulan September',
    date: DateTime(2025, 9, 1),
    type: 'income',
    categoryId: 1,
    userId: 1,
    category: demoCategories[0],
  ),
  Transaction(
    id: 2,
    amount: 150000,
    description: 'Makan siang di restaurant',
    date: DateTime(2025, 8, 30),
    type: 'expense',
    categoryId: 2,
    userId: 1,
    category: demoCategories[1],
  ),
  Transaction(
    id: 3,
    amount: 75000,
    description: 'Bensin motor',
    date: DateTime(2025, 8, 29),
    type: 'expense',
    categoryId: 3,
    userId: 1,
    category: demoCategories[2],
  ),
  Transaction(
    id: 4,
    amount: 1000000,
    description: 'Investasi saham',
    date: DateTime(2025, 8, 28),
    type: 'income',
    categoryId: 4,
    userId: 1,
    category: demoCategories[3],
  ),
  Transaction(
    id: 5,
    amount: 250000,
    description: 'Belanja groceries',
    date: DateTime(2025, 8, 27),
    type: 'expense',
    categoryId: 5,
    userId: 1,
    category: demoCategories[4],
  ),
  Transaction(
    id: 6,
    amount: 120000,
    description: 'Makan malam keluarga',
    date: DateTime(2025, 8, 26),
    type: 'expense',
    categoryId: 2,
    userId: 1,
    category: demoCategories[1],
  ),
  Transaction(
    id: 7,
    amount: 50000,
    description: 'Ongkos ojek online',
    date: DateTime(2025, 8, 25),
    type: 'expense',
    categoryId: 3,
    userId: 1,
    category: demoCategories[2],
  ),
  Transaction(
    id: 8,
    amount: 300000,
    description: 'Belanja pakaian',
    date: DateTime(2025, 8, 24),
    type: 'expense',
    categoryId: 5,
    userId: 1,
    category: demoCategories[4],
  ),
  Transaction(
    id: 9,
    amount: 500000,
    description: 'Bonus kerja',
    date: DateTime(2025, 8, 23),
    type: 'income',
    categoryId: 1,
    userId: 1,
    category: demoCategories[0],
  ),
  Transaction(
    id: 10,
    amount: 85000,
    description: 'Kopi dan snack',
    date: DateTime(2025, 8, 22),
    type: 'expense',
    categoryId: 2,
    userId: 1,
    category: demoCategories[1],
  ),
];
