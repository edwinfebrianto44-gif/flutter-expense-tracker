import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_button.dart';
import '../../generated/l10n.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  
  String _transactionType = 'expense';
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormatter.formatDate(_selectedDate);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoryProvider);
    final filteredCategories = categories.where((c) => c.type == _transactionType).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addTransaction),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Transaction Type Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _setTransactionType('income'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _transactionType == 'income'
                                    ? Theme.of(context).colorScheme.secondary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: _transactionType == 'income'
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.income,
                                    style: TextStyle(
                                      color: _transactionType == 'income'
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _setTransactionType('expense'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _transactionType == 'expense'
                                    ? Theme.of(context).colorScheme.error
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.trending_down,
                                    color: _transactionType == 'expense'
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.expense,
                                    style: TextStyle(
                                      color: _transactionType == 'expense'
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: AppValidators.amount,
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      hintText: l10n.enterAmount,
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: _transactionType == 'income'
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.error,
                      ),
                      prefixText: 'Rp ',
                    ),
                    onChanged: (value) {
                      // Format number with thousand separators
                      if (value.isNotEmpty) {
                        final number = int.tryParse(value.replaceAll('.', ''));
                        if (number != null) {
                          final formatted = NumberFormat('#,###', 'id_ID').format(number).replaceAll(',', '.');
                          if (formatted != value) {
                            _amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    validator: AppValidators.category,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      hintText: l10n.selectCategory,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: filteredCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Text(category.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    validator: AppValidators.description,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.description,
                      hintText: l10n.enterDescription,
                      prefixIcon: const Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Field
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    validator: AppValidators.date,
                    decoration: InputDecoration(
                      labelText: l10n.date,
                      hintText: l10n.selectDate,
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  LoadingButton(
                    isLoading: _isLoading,
                    onPressed: _handleSubmit,
                    text: l10n.saveTransaction,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: _transactionType == 'income'
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setTransactionType(String type) {
    setState(() {
      _transactionType = type;
      _selectedCategory = null; // Reset category when type changes
    });
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = DateFormatter.formatDate(date);
      });
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final l10n = AppLocalizations.of(context)!;
        
        // Parse amount
        final amountText = _amountController.text.replaceAll('.', '');
        final amount = double.parse(amountText);

        // Create new transaction
        final newTransaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch, // Simple ID generation
          amount: amount,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          type: _transactionType,
          categoryId: _selectedCategory!.id,
          userId: 1, // Demo user ID
          category: _selectedCategory,
        );

        // Add to provider
        ref.read(transactionProvider.notifier).addTransaction(newTransaction);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.transactionAdded),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
