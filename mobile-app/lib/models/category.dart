import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final String icon;
  final Color color;
  final String type; // 'income' or 'expense'
  final int userId;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.userId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: Color(json['color']),
      type: json['type'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
      'type': type,
      'user_id': userId,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? icon,
    Color? color,
    String? type,
    int? userId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      userId: userId ?? this.userId,
    );
  }
}

// Demo categories
final List<Category> demoCategories = [
  Category(
    id: 1,
    name: 'Gaji',
    icon: '💰',
    color: const Color(0xFF10B981),
    type: 'income',
    userId: 1,
  ),
  Category(
    id: 2,
    name: 'Makanan',
    icon: '🍔',
    color: const Color(0xFFEF4444),
    type: 'expense',
    userId: 1,
  ),
  Category(
    id: 3,
    name: 'Transportasi',
    icon: '🚗',
    color: const Color(0xFF3B82F6),
    type: 'expense',
    userId: 1,
  ),
  Category(
    id: 4,
    name: 'Investasi',
    icon: '📈',
    color: const Color(0xFF10B981),
    type: 'income',
    userId: 1,
  ),
  Category(
    id: 5,
    name: 'Belanja',
    icon: '🛒',
    color: const Color(0xFFF59E0B),
    type: 'expense',
    userId: 1,
  ),
];
