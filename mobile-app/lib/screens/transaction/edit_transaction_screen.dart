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

class EditTransactionScreen extends ConsumerStatefulWidget {
  final int transactionId;
  final Transaction? transaction;

  const EditTransactionScreen({
    super.key,
    required this.transactionId,
    this.transaction,
  });

  @override
  ConsumerState<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen>
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
    _initializeData();
    
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

  void _initializeData() {
    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      _transactionType = transaction.type;
      _selectedDate = transaction.date;
      _selectedCategory = transaction.category;
      
      _amountController.text = NumberFormat('#,###', 'id_ID')
          .format(transaction.amount.toInt())
          .replaceAll(',', '.');
      _descriptionController.text = transaction.description;
      _dateController.text = DateFormatter.formatDate(transaction.date);
    }
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
    final categories = ref.watch(categoryProvider);
    final filteredCategories = categories.where((c) => c.type == _transactionType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showDeleteDialog,
          ),
        ],
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
                                    'Pemasukan',
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
                                    'Pengeluaran',
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
                      labelText: 'Jumlah',
                      hintText: 'Masukkan jumlah uang',
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
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      hintText: 'Pilih kategori',
                      prefixIcon: Icon(Icons.category_outlined),
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
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      hintText: 'Masukkan deskripsi transaksi',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Field
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    validator: AppValidators.date,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      hintText: 'Pilih tanggal transaksi',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  LoadingButton(
                    isLoading: _isLoading,
                    onPressed: _handleSubmit,
                    text: 'Update Transaksi',
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
      // Reset category if it doesn't match the new type
      if (_selectedCategory != null && _selectedCategory!.type != type) {
        _selectedCategory = null;
      }
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
        // Parse amount
        final amountText = _amountController.text.replaceAll('.', '');
        final amount = double.parse(amountText);

        // Create updated transaction
        final updatedTransaction = Transaction(
          id: widget.transactionId,
          amount: amount,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          type: _transactionType,
          categoryId: _selectedCategory!.id,
          userId: 1, // Demo user ID
          category: _selectedCategory,
        );

        // Update in provider
        ref.read(transactionProvider.notifier).updateTransaction(updatedTransaction);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaksi berhasil diupdate'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengupdate transaksi: $e'),
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleDelete();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _handleDelete() {
    ref.read(transactionProvider.notifier).deleteTransaction(widget.transactionId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaksi berhasil dihapus'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    
    context.pop();
  }
}
