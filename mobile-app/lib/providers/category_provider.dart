import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super(demoCategories);

  void addCategory(Category category) {
    state = [...state, category];
  }

  void updateCategory(Category category) {
    state = state.map((c) => c.id == category.id ? category : c).toList();
  }

  void deleteCategory(int id) {
    state = state.where((c) => c.id != id).toList();
  }

  List<Category> getCategoriesByType(String type) {
    return state.where((c) => c.type == type).toList();
  }

  Category? getCategoryById(int id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
