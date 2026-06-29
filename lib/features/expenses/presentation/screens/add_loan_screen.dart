import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/loan_controller.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/budget_controller.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';
import 'package:personal_wallet/shared/widgets/custom_button.dart';
import 'package:personal_wallet/shared/widgets/custom_text_field.dart';

class AddLoanScreen extends ConsumerStatefulWidget {
  const AddLoanScreen({super.key});

  @override
  ConsumerState<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends ConsumerState<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'lent'; // 'lent' or 'borrowed'
  int _selectedWalletId = 1;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _saveLoan() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text;
      final amount = double.parse(_amountController.text);
      final notes = _notesController.text;
      final l10n = ref.read(l10nProvider);

      await ref.read(loanControllerProvider.notifier).addLoan(
            personName: name,
            amount: amount,
            type: _selectedType,
            walletId: _selectedWalletId,
            dueDate: _dueDate,
            notes: notes,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('transaction_saved')),
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
    final l10n = ref.watch(l10nProvider);
    final budgetState = ref.watch(budgetControllerProvider);
    final contacts = ref.watch(contactProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('loans_debts'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lent vs Borrowed Type
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_upward_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(l10n.translate('money_lent')),
                          ],
                        ),
                        selected: _selectedType == 'lent',
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedType = 'lent');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_downward_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(l10n.translate('money_borrowed')),
                          ],
                        ),
                        selected: _selectedType == 'borrowed',
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedType = 'borrowed');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name Input with suggestions
                Text(l10n.locale.languageCode == 'ar' ? 'الاسم' : 'Person Name', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return contacts
                        .map((c) => c.name)
                        .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (sel) => _nameController.text = sel,
                  fieldViewBuilder: (ctx, textCtrl, focusNode, onFieldSubmitted) {
                    // Keep controllers synced
                    textCtrl.text = _nameController.text;
                    textCtrl.addListener(() {
                      _nameController.text = textCtrl.text;
                    });
                    return CustomTextField(
                      controller: textCtrl,
                      focusNode: focusNode,
                      labelText: l10n.locale.languageCode == 'ar' ? 'ابحث أو اكتب الاسم' : 'Search or enter name',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (val) => (val == null || val.isEmpty) ? 'Name is required / الاسم مطلوب' : null,
                    );
                  },
                ),
                const SizedBox(height: 20),

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

                // Funding Account Wallet
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

                // Due Date selection picker
                Text(l10n.translate('due_date'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDueDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${_dueDate.day}/${_dueDate.month}/${_dueDate.year}", style: const TextStyle(fontSize: 16, fontFamily: 'Outfit')),
                        const Icon(Icons.calendar_month_outlined, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Notes
                CustomTextField(
                  controller: _notesController,
                  labelText: l10n.translate('notes'),
                  hintText: 'Add description details / تفاصيل أو ملاحظات',
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 40),

                CustomButton(
                  text: l10n.translate('save'),
                  onPressed: _saveLoan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
