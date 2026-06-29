import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/loan_controller.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/budget_controller.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';
import 'package:personal_wallet/shared/widgets/custom_button.dart';
import 'package:personal_wallet/shared/widgets/custom_text_field.dart';
import 'package:personal_wallet/core/services/service_providers.dart';

class LoanDetailsScreen extends ConsumerStatefulWidget {
  final int loanId;

  const LoanDetailsScreen({super.key, required this.loanId});

  @override
  ConsumerState<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends ConsumerState<LoanDetailsScreen> {
  final _repayAmountController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  int _selectedWalletId = 1;

  final List<String> _paymentMethods = [
    'Cash',
    'Visa',
    'Bank',
    'Instapay',
    'Vodafone Cash',
    'E-Wallet',
  ];

  @override
  void dispose() {
    _repayAmountController.dispose();
    super.dispose();
  }

  void _showRepaymentSheet(AppLocalizations l10n, double remainingAmount, BudgetState budgetState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('repay_loan'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              
              // Amount
              CustomTextField(
                controller: _repayAmountController,
                labelText: l10n.translate('amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money_rounded,
              ),
              const SizedBox(height: 16),

              // Target wallet
              const Text('Target Wallet / محفظة الاستلام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return DropdownButtonFormField<int>(
                    value: budgetState.wallets.any((w) => w.id == _selectedWalletId) ? _selectedWalletId : (budgetState.wallets.isNotEmpty ? budgetState.wallets.first.id : 1),
                    items: budgetState.wallets.map<DropdownMenuItem<int>>((w) {
                      return DropdownMenuItem<int>(value: w.id, child: Text(w.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _selectedWalletId = val);
                        _selectedWalletId = val;
                      }
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  );
                }
              ),
              const SizedBox(height: 16),

              // Payment Method
              const Text('Payment Method / وسيلة الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    items: _paymentMethods.map<DropdownMenuItem<String>>((m) {
                      return DropdownMenuItem<String>(value: m, child: Text(m));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _selectedPaymentMethod = val);
                        _selectedPaymentMethod = val;
                      }
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  );
                }
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: l10n.translate('save'),
                onPressed: () async {
                  final amount = double.tryParse(_repayAmountController.text);
                  if (amount != null && amount > 0 && amount <= remainingAmount) {
                    await ref.read(loanControllerProvider.notifier).registerRepayment(
                          loanId: widget.loanId,
                          amount: amount,
                          walletId: _selectedWalletId,
                          paymentMethod: _selectedPaymentMethod,
                        );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.translate('transaction_saved')),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid payment amount / القيمة غير صالحة'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = ref.watch(l10nProvider);
    final loanState = ref.watch(loanControllerProvider);
    final txs = ref.watch(expenseControllerProvider).transactions;
    final budgetState = ref.watch(budgetControllerProvider);

    final loanList = loanState.loans.where((l) => l.id == widget.loanId);
    if (loanList.isEmpty) {
      return Scaffold(body: const Center(child: Text('Loan not found')));
    }

    final loan = loanList.first;
    final remaining = loan.totalAmount - loan.paidAmount;
    final progress = loan.totalAmount > 0 ? (loan.paidAmount / loan.totalAmount).clamp(0.0, 1.0) : 0.0;
    
    // Days remaining to due date
    final diff = loan.dueDate.difference(DateTime.now()).inDays;
    final daysRemainingText = diff >= 0 
        ? (l10n.locale.languageCode == 'ar' ? 'متبقي $diff يوم' : '$diff days remaining')
        : (l10n.locale.languageCode == 'ar' ? 'متأخرة بـ ${diff.abs()} يوم' : 'Overdue by ${diff.abs()} days');

    // Associated repayment transactions list
    final repaymentTxs = txs.where((t) => t.type == 'loan_repayment' && t.loanId == loan.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.personName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.translate('delete_confirm_title')),
                  content: const Text('Delete this loan? / حذف هذه السلفة؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.translate('no'))),
                    TextButton(
                      onPressed: () async {
                        await ref.read(loanControllerProvider.notifier).deleteLoan(loan.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) context.pop();
                      },
                      child: Text(l10n.translate('yes')),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loan status card summary
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loan.type == 'lent' ? l10n.translate('money_lent') : l10n.translate('money_borrowed'),
                            style: TextStyle(color: loan.type == 'lent' ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: loan.status == 'paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.translate('loan_status_${loan.status}'),
                              style: TextStyle(color: loan.status == 'paid' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.translate('remaining'), style: const TextStyle(color: Colors.grey)),
                          Text(
                            '${remaining.toStringAsFixed(2)} ${l10n.translate('currency')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Outfit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.locale.languageCode == 'ar' ? 'القيمة الكلية' : 'Total Amount', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('${loan.totalAmount.toStringAsFixed(2)} ${l10n.translate('currency')}', style: const TextStyle(fontFamily: 'Outfit', fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        color: loan.type == 'lent' ? Colors.green : Colors.red,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(daysRemainingText, style: TextStyle(color: diff >= 0 ? Colors.grey : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notes & dates info
              const Text('Details / التفاصيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Start Date / تاريخ البداية', style: TextStyle(color: Colors.grey)),
                          Text(loan.date, style: const TextStyle(fontFamily: 'Outfit')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Due Date / تاريخ الاستحقاق', style: TextStyle(color: Colors.grey)),
                          Text("${loan.dueDate.day}/${loan.dueDate.month}/${loan.dueDate.year}", style: const TextStyle(fontFamily: 'Outfit')),
                        ],
                      ),
                      if (loan.notes.isNotEmpty) ...[
                        const Divider(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Notes / ملاحظات: ', style: TextStyle(color: Colors.grey)),
                            Expanded(child: Text(loan.notes)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Repayment logs list
              const Text('Payments History / سجل السداد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              repaymentTxs.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No payments recorded yet / لم يتم سداد أي دفعات')))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: repaymentTxs.length,
                      itemBuilder: (context, index) {
                        final tx = repaymentTxs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.check, color: Colors.green)),
                            title: Text('${tx.amount.toStringAsFixed(0)} ${l10n.translate('currency')}'),
                            subtitle: Text('${tx.date} - ${tx.time} (${tx.paymentMethod})'),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: loan.status == 'paid'
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showRepaymentSheet(l10n, remaining, budgetState),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(l10n.translate('repay_loan')),
            ),
    );
  }
}
