import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _selectedToWalletId = 2;
  String _receiptPath = '';
  bool _isEdit = false;
  bool _isLoading = false;

  void _handleClipboardParse(AppLocalizations l10n) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(l10n.locale.languageCode == 'ar' ? 'تحليل الرسالة الذكي' : 'Smart Message Parser'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.locale.languageCode == 'ar'
                    ? 'الصق هنا نص رسالة التحويل أو فودافون كاش أو إنستاباي وسنقوم بملء البيانات بالكامل تلقائياً:'
                    : 'Paste the transaction message text here (Instapay, Bank SMS, or Vodafone Cash):',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.locale.languageCode == 'ar'
                      ? 'مثال: تم تحويل 500.00 ج.م إلى رقم...'
                      : 'e.g., You received 500 EGP from...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final message = textController.text.trim();
                Navigator.pop(context);
                if (message.isNotEmpty) {
                  _parseMessage(message, l10n);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.locale.languageCode == 'ar' ? 'تحليل' : 'Parse'),
            ),
          ],
        );
      },
    );
  }

  void _parseMessage(String text, AppLocalizations l10n) {
    double? parsedAmount;
    String parsedType = 'expense'; // default to expense
    String parsedPaymentMethod = _selectedPaymentMethod;
    
    // 1. Parse amount: Search for digits, e.g. 500, 1250.50, followed/preceded by EGP, ج.م, جنيه
    final regEx = RegExp(r'(\d+[\.,]?\d*)');
    final matches = regEx.allMatches(text);
    if (matches.isNotEmpty) {
      for (var match in matches) {
        final val = double.tryParse(match.group(0)!.replaceAll(',', ''));
        if (val != null && val > 0) {
          parsedAmount = val;
          break;
        }
      }
    }
    
    // 2. Parse type:
    // If it contains "استقبال", "استلام", "إيداع", "تحويل إليك", "وارد", "received", "deposit", "credited" -> deposit
    final lowerText = text.toLowerCase();
    if (text.contains('استلام') || 
        text.contains('استقبال') || 
        text.contains('إيداع') || 
        text.contains('وارد') ||
        text.contains('إليك') ||
        lowerText.contains('received') || 
        lowerText.contains('deposit') || 
        lowerText.contains('credited') || 
        lowerText.contains('added')) {
      parsedType = 'deposit';
    } else if (text.contains('تحويل') || 
               text.contains('سحب') || 
               text.contains('خصم') || 
               text.contains('دفع') || 
               text.contains('شراء') || 
               lowerText.contains('sent') || 
               lowerText.contains('paid') || 
               lowerText.contains('withdrawn') || 
               lowerText.contains('debited') || 
               lowerText.contains('transfer')) {
      parsedType = 'expense';
    }

    // 3. Parse payment method:
    if (text.contains('فودافون') || lowerText.contains('vodafone') || lowerText.contains('vf')) {
      parsedPaymentMethod = 'Vodafone Cash';
    } else if (text.contains('إنستاباي') || lowerText.contains('instapay') || lowerText.contains('insta')) {
      parsedPaymentMethod = 'Instapay';
    } else if (text.contains('بنك') || lowerText.contains('bank')) {
      parsedPaymentMethod = 'Bank';
    }

    if (parsedAmount != null) {
      setState(() {
        _amountController.text = parsedAmount!.toStringAsFixed(2);
        _selectedType = parsedType;
        _selectedPaymentMethod = parsedPaymentMethod;
        
        final categories = parsedType == 'deposit' ? _depositCategories : _expenseCategories;
        _selectedCategory = categories.first;
        
        _descriptionController.text = l10n.locale.languageCode == 'ar'
            ? 'تحويل ذكي تلقائي'
            : 'Smart Auto Parse';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.locale.languageCode == 'ar' 
                ? 'تم تحليل الرسالة وتعبئة البيانات بنجاح!' 
                : 'Message parsed and fields populated successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.locale.languageCode == 'ar' 
                ? 'لم نتمكن من العثور على قيمة المبلغ في الرسالة.' 
                : 'Could not detect amount value in the message.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

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
        _selectedToWalletId = tx.toWalletId != 0 ? tx.toWalletId : 2;
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

      if ((_selectedType == 'expense' || _selectedType == 'transfer') && !_isEdit) {
        final walletBalances = ref.read(walletBalancesProvider);
        final currentBalance = walletBalances[_selectedWalletId] ?? 0.0;
        
        if (amount > currentBalance) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(l10n.locale.languageCode == 'ar' ? 'تحذير: رصيد غير كافٍ' : 'Warning: Low Balance'),
              content: Text(
                l10n.locale.languageCode == 'ar'
                    ? 'المبلغ المراد تحويله ($amount ج.م) أكبر من الرصيد المتوفر في المحفظة المصدر ($currentBalance ج.م). هل تريد الاستمرار بالخصم ورؤية رصيد سالب؟'
                    : 'The amount to be transferred ($amount EGP) is greater than the available balance in the source wallet ($currentBalance EGP). Do you want to proceed and allow a negative balance?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(l10n.locale.languageCode == 'ar' ? 'الاستمرار' : 'Proceed'),
                ),
              ],
            ),
          );
          if (proceed != true) return;
        } else if (currentBalance > 0 && (currentBalance - amount) < (currentBalance * 0.15)) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(l10n.locale.languageCode == 'ar' ? 'تنبيه: اقتراب الحد الأدنى' : 'Alert: Approaching Limit'),
              content: Text(
                l10n.locale.languageCode == 'ar'
                    ? 'رصيد المحفظة المصدر سيقترب من الصفر (سيتبقى أقل من 15% من رصيدك الحالي) بعد هذه العملية. هل ترغب في إتمامها؟'
                    : 'The source wallet balance will drop close to zero (less than 15% remaining) after this transaction. Do you want to proceed?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(l10n.locale.languageCode == 'ar' ? 'الاستمرار' : 'Proceed'),
                ),
              ],
            ),
          );
          if (proceed != true) return;
        }
      }

      if (_selectedType == 'transfer' && _selectedWalletId == _selectedToWalletId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.locale.languageCode == 'ar'
                  ? 'المحفظة المرسلة والمستقبلة متطابقتان! يرجى اختيار محفظة مختلفة.'
                  : 'Source and destination wallets cannot be the same!',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

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
          tx.category = _selectedType == 'transfer' ? 'Transfer' : _selectedCategory;
          tx.description = description.isNotEmpty 
              ? description 
              : (_selectedType == 'transfer' 
                  ? (l10n.locale.languageCode == 'ar' ? 'تحويل بين المحافظ' : 'Transfer Between Wallets')
                  : description);
          tx.location = location;
          tx.notes = notes;
          tx.paymentMethod = _selectedType == 'transfer' ? 'Transfer' : _selectedPaymentMethod;
          tx.walletId = _selectedWalletId;
          tx.toWalletId = _selectedType == 'transfer' ? _selectedToWalletId : 0;
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
          ..category = _selectedType == 'transfer' ? 'Transfer' : _selectedCategory
          ..description = description.isNotEmpty 
              ? description 
              : (_selectedType == 'transfer' 
                  ? (l10n.locale.languageCode == 'ar' ? 'تحويل بين المحافظ' : 'Transfer Between Wallets')
                  : description)
          ..location = location
          ..notes = notes
          ..paymentMethod = _selectedType == 'transfer' ? 'Transfer' : _selectedPaymentMethod
          ..walletId = _selectedWalletId
          ..toWalletId = _selectedType == 'transfer' ? _selectedToWalletId : 0
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

    final customCats = budgetState.customCategories
        .where((c) => c.type == _selectedType)
        .map((c) => c.name)
        .toList();
    final categories = [
      ...(_selectedType == 'deposit' ? _depositCategories : _expenseCategories),
      ...customCats,
    ];

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
                        label: Text(l10n.translate('deposit')),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(l10n.translate('expense')),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(l10n.locale.languageCode == 'ar' ? 'تحويل' : 'Transfer'),
                        selected: _selectedType == 'transfer',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedType = 'transfer';
                              _selectedCategory = 'Transfer';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                // Smart Parser Card
                if (!_isEdit) ...[
                  Card(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                l10n.locale.languageCode == 'ar' ? 'قارئ الرسائل والتحويلات الذكي' : 'Smart SMS/Transfer Parser',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.locale.languageCode == 'ar'
                                      ? 'الصق رسالة فودافون كاش أو إنستاباي لملء البيانات تلقائياً'
                                      : 'Paste Vodafone Cash or Instapay message to fill fields',
                                  style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 11),
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.paste_rounded, size: 14),
                                label: Text(l10n.locale.languageCode == 'ar' ? 'لصق وتحليل' : 'Paste & Parse'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _handleClipboardParse(l10n),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                Text(
                  _selectedType == 'transfer'
                      ? (l10n.locale.languageCode == 'ar' ? 'من محفظة (المصدر)' : 'From Wallet (Source)')
                      : l10n.translate('wallet_name'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
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
                
                if (_selectedType == 'transfer') ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.locale.languageCode == 'ar' ? 'إلى محفظة (المستلم)' : 'To Wallet (Destination)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: budgetState.wallets.any((w) => w.id == _selectedToWalletId) ? _selectedToWalletId : (budgetState.wallets.length > 1 ? budgetState.wallets[1].id : 2),
                    items: budgetState.wallets.map((w) {
                      return DropdownMenuItem<int>(
                        value: w.id,
                        child: Text(w.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedToWalletId = val);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                if (_selectedType != 'transfer') ...[
                  // Category selection dropdown
                  Text(l10n.translate('category'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
                    items: [
                      ...categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(l10n.getCategoryTranslation(cat)),
                        );
                      }),
                      DropdownMenuItem<String>(
                        value: 'ADD_CUSTOM',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.locale.languageCode == 'ar' ? 'إضافة تصنيف مخصص...' : 'Add Custom Category...',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == 'ADD_CUSTOM') {
                        _showAddCustomCategoryDialog(l10n);
                      } else if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
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
                ],
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
  }

  void _showAddCustomCategoryDialog(AppLocalizations l10n) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.locale.languageCode == 'ar' ? 'إضافة تصنيف مخصص جديد' : 'Add New Custom Category'),
          content: CustomTextField(
            controller: nameCtrl,
            labelText: l10n.locale.languageCode == 'ar' ? 'اسم التصنيف' : 'Category Name',
            hintText: 'e.g. Car',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  await ref.read(budgetControllerProvider.notifier).addCustomCategory(name, _selectedType);
                  setState(() {
                    _selectedCategory = name;
                  });
                }
              },
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(l10n.locale.languageCode == 'ar' ? 'إضافة' : 'Add'),
            ),
          ],
        );
      },
    );
  }
}
