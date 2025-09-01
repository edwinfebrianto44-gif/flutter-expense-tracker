import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/empty_state.dart';
import '../../utils/validators.dart';
import '../../generated/l10n.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoryProvider);
    final incomeCategories = categories.where((c) => c.type == 'income').toList();
    final expenseCategories = categories.where((c) => c.type == 'expense').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageCategories),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.trending_up),
              text: l10n.income,
            ),
            Tab(
              icon: const Icon(Icons.trending_down),
              text: l10n.expense,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(incomeCategories, 'income'),
          _buildCategoryList(expenseCategories, 'expense'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        child: const Icon(Icons.add),
        heroTag: 'add_category_fab',
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, String type) {
    final l10n = AppLocalizations.of(context)!;
    
    if (categories.isEmpty) {
      return EmptyState(
        icon: Icons.category_outlined,
        title: l10n.noCategoriesYet,
        description: 'Add your first ${type == 'income' ? l10n.income.toLowerCase() : l10n.expense.toLowerCase()} category',
        actionText: l10n.addCategory,
        onActionPressed: () => _showAddCategoryDialog(type: type),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              category.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              category.type == 'income' ? l10n.income : l10n.expense,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditCategoryDialog(category);
                    break;
                  case 'delete':
                    _showDeleteCategoryDialog(category);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined),
                      const SizedBox(width: 12),
                      Text(l10n.edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline),
                      const SizedBox(width: 12),
                      Text(l10n.delete),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog({String? type}) {
    final selectedType = type ?? (_tabController.index == 0 ? 'income' : 'expense');
    _showCategoryDialog(null, selectedType);
  }

  void _showEditCategoryDialog(Category category) {
    _showCategoryDialog(category, category.type);
  }

  void _showCategoryDialog(Category? category, String type) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedIcon = category?.icon ?? '💰';
    Color selectedColor = category?.color ?? Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? l10n.addCategory : l10n.editCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.categoryName,
                  hintText: l10n.enterCategoryName,
                ),
                validator: AppValidators.categoryName,
              ),
              const SizedBox(height: 16),
              
              // Icon Selector
              Row(
                children: [
                  Text(
                    '${l10n.icon}: ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showIconPicker(context, (icon) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    }),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selectedColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Center(
                        child: Text(
                          selectedIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Color Selector
              Row(
                children: [
                  Text(
                    '${l10n.color}: ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: _predefinedColors.map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                              border: selectedColor == color
                                  ? Border.all(color: Theme.of(context).colorScheme.outline, width: 2)
                                  : null,
                            ),
                            child: selectedColor == color
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final newCategory = Category(
                    id: category?.id ?? DateTime.now().millisecondsSinceEpoch,
                    name: nameController.text.trim(),
                    icon: selectedIcon,
                    color: selectedColor,
                    type: type,
                    userId: 1, // Demo user ID
                  );

                  if (category == null) {
                    ref.read(categoryProvider.notifier).addCategory(newCategory);
                  } else {
                    ref.read(categoryProvider.notifier).updateCategory(newCategory);
                  }

                  Navigator.of(context).pop();
                }
              },
              child: Text(category == null ? l10n.add : l10n.update),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker(BuildContext context, Function(String) onSelected) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectIcon),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _predefinedIcons.length,
            itemBuilder: (context, index) {
              final icon = _predefinedIcons[index];
              return GestureDetector(
                onTap: () {
                  onSelected(icon);
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(Category category) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text('${l10n.areYouSureDelete} "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(categoryProvider.notifier).deleteCategory(category.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.category} "${category.name}" ${l10n.success['deleted'] ?? 'successfully deleted'}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  final List<String> _predefinedIcons = [
    '💰', '💵', '💳', '🏦', '📈', '📊', '💼', '💎', '🎯', '🎁',
    '🍔', '🍕', '☕', '🛒', '🛍️', '👕', '👟', '🎮', '📱', '💻',
    '🚗', '⛽', '🚌', '🚇', '✈️', '🏠', '💡', '💊', '🎓', '📚',
    '🎬', '🎵', '🏋️', '⚽', '🎾', '🏊', '🧘', '💅', '💇', '🎂',
  ];

  final List<Color> _predefinedColors = [
    const Color(0xFF6366F1), // Purple
    const Color(0xFF10B981), // Green
    const Color(0xFFEF4444), // Red
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFF97316), // Orange
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFEC4899), // Pink
    const Color(0xFF84CC16), // Lime
  ];
}
