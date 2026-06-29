import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/budget_controller.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';
import 'package:personal_wallet/shared/widgets/custom_button.dart';
import 'package:personal_wallet/shared/widgets/custom_text_field.dart';
import 'package:personal_wallet/core/theme/app_theme.dart';
import 'package:personal_wallet/features/expenses/domain/models/transaction.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final int? expenseId;

  const AddExpenseScreen({super.key, this.expenseId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'expense'; // 'deposit' or 'expense'
  String _selectedCategory = 'Food';
  String _selectedPaymentMethod = 'Cash';
  int _selectedWalletId = 1;
  String _receiptPath = '';
  bool _isEdit = false;
  bool _isLoading = false;

  final List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  final List<String> _depositCategories = [
    'Salary',
    'Investment',
    'Gift',
    'Other',
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Visa',
    'Bank',
    'Instapay',
    'Vodafone Cash',
    'E-Wallet',
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.expenseId != null;
    if (_isEdit) {
      _loadExpenseData();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLastUsedCategory();
      });
    }
  }

  void _loadLastUsedCategory() {
    final storage = ref.read(storageServiceProvider);
    final lastCat = storage.getLastUsedCategory();
    final categories = _selectedType == 'deposit' ? _depositCategories : _expenseCategories;

    if (lastCat != null && categories.contains(lastCat)) {
      setState(() {
        _selectedCategory = lastCat;
      });
    } else {
      setState(() {
        _selectedCategory = categories.first;
      });
    }
  }

  Future<void> _loadExpenseData() async {
    setState(() {
      _isLoading = true;
    });

    final tx = await ref.read(databaseServiceProvider).getExpense(widget.expenseId!);
    if (tx != null) {
      setState(() {
        _amountController.text = tx.amount.toString();
        _descriptionController.text = tx.description;
        _selectedType = tx.type;
        _selectedCategory = tx.category;
        _selectedPaymentMethod = tx.paymentMethod.isNotEmpty ? tx.paymentMethod : 'Cash';
        _selectedWalletId = tx.walletId != 0 ? tx.walletId : 1;
        _locationController.text = tx.location;
        _notesController.text = tx.notes;
        _receiptPath = tx.receiptImagePath;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _receiptPath = result.files.single.path!;
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;
      final location = _locationController.text;
      final notes = _notesController.text;
      final l10n = ref.read(l10nProvider);

      setState(() {
        _isLoading = true;
      });

      final controller = ref.read(expenseControllerProvider.notifier);

      if (_isEdit) {
        // Read directly from database
        final db = ref.read(databaseServiceProvider);
        final tx = await db.getExpense(widget.expenseId!);
        if (tx != null) {
          tx.amount = amount;
          tx.type = _selectedType;
          tx.category = _selectedCategory;
          tx.description = description;
          tx.location = location;
          tx.notes = notes;
          tx.paymentMethod = _selectedPaymentMethod;
          tx.walletId = _selectedWalletId;
          tx.receiptImagePath = _receiptPath;
          tx.updatedAt = DateTime.now();
          await db.saveExpense(tx);
          await controller.loadTransactions();
        }
      } else {
        final now = DateTime.now();
        final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
        
        int hour = now.hour;
        final ampm = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour == 0) hour = 12;
        final timeStr = "${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm";

        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final dayOfWeek = days[now.weekday - 1];

        final transaction = Transaction()
          ..amount = amount
          ..type = _selectedType
          ..category = _selectedCategory
          ..description = description
          ..location = location
          ..notes = notes
          ..paymentMethod = _selectedPaymentMethod
          ..walletId = _selectedWalletId
          ..receiptImagePath = _receiptPath
          ..date = dateStr
          ..time = timeStr
          ..day = now.day
          ..month = now.month
          ..year = now.year
          ..dayOfWeek = dayOfWeek
          ..uuid = UniqueKey().toString()
          ..createdAt = now
          ..updatedAt = now;

        await ref.read(databaseServiceProvider).saveExpense(transaction);
        await controller.loadTransactions();
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? l10n.translate('transaction_updated') : l10n.translate('transaction_saved')),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(l10nProvider);
    final budgetState = ref.watch(budgetControllerProvider);

    final categories = _selectedType == 'deposit' ? _depositCategories : _expenseCategories;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.translate('edit_transaction') : l10n.translate('add_transaction')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Type Choice chips
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(l10n.translate('deposit')),
                          ],
                        ),
                        selected: _selectedType == 'deposit',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedType = 'deposit';
                              _selectedCategory = _depositCategories.first;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.remove_circle_outline_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(l10n.translate('expense')),
                          ],
                        ),
                        selected: _selectedType == 'expense',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedType = 'expense';
                              _selectedCategory = _expenseCategories.first;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Amount
                CustomTextField(
                  controller: _amountController,
                  labelText: l10n.translate('amount'),
                  hintText: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.attach_money_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) return l10n.translate('invalid_amount');
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return l10n.translate('invalid_amount');
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Wallet Selection dropdown
                Text(l10n.translate('wallet_name'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: budgetState.wallets.any((w) => w.id == _selectedWalletId) ? _selectedWalletId : (budgetState.wallets.isNotEmpty ? budgetState.wallets.first.id : 1),
                  items: budgetState.wallets.map((w) {
                    return DropdownMenuItem<int>(
                      value: w.id,
                      child: Text(w.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedWalletId = val);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Category selection dropdown
                Text(l10n.translate('category'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
                  items: categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(l10n.getCategoryTranslation(cat)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedCategory = value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Method dropdown
                Text(l10n.translate('payment_method'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  items: _paymentMethods.map((m) {
                    return DropdownMenuItem<String>(
                      value: m,
                      child: Text(l10n.locale.languageCode == 'ar' ? (m == 'Cash' ? 'كاش' : m) : m),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPaymentMethod = value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Location Field
                CustomTextField(
                  controller: _locationController,
                  labelText: l10n.translate('location'),
                  hintText: 'GPS / City',
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 20),

                // Description
                CustomTextField(
                  controller: _descriptionController,
                  labelText: l10n.translate('description'),
                  hintText: 'Notes description / تفاصيل العملية',
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 20),

                // Photo attachment picker
                Text(l10n.translate('receipt_photo'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.photo_camera),
                      label: Text(l10n.translate('add_photo')),
                      onPressed: _pickReceipt,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _receiptPath.isNotEmpty
                            ? _receiptPath.split('/').last
                            : l10n.translate('no_photo'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                CustomButton(
                  text: l10n.translate('save'),
                  onPressed: _saveTransaction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
