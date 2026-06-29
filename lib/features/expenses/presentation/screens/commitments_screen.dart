import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/commitment_controller.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/budget_controller.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';
import 'package:personal_wallet/shared/widgets/custom_button.dart';
import 'package:personal_wallet/shared/widgets/custom_text_field.dart';

class CommitmentsScreen extends ConsumerStatefulWidget {
  const CommitmentsScreen({super.key});

  @override
  ConsumerState<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends ConsumerState<CommitmentsScreen> {
  void _showAddCommitmentDialog(AppLocalizations l10n) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dueDateCtrl = TextEditingController(text: '1');
    final budgetState = ref.read(budgetControllerProvider);
    
    int selectedWalletId = budgetState.wallets.isNotEmpty ? budgetState.wallets.first.id : 1;
    String selectedCategory = 'Bills';

    final categories = ['Bills', 'Food', 'Transport', 'Shopping', 'Entertainment', 'Health', 'Education', 'Other'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(l10n.locale.languageCode == 'ar' ? 'إضافة التزام شهري جديد' : 'Add New Monthly Commitment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: nameCtrl,
                      labelText: l10n.locale.languageCode == 'ar' ? 'اسم الالتزام (مثال: الإيجار)' : 'Commitment Name (e.g. Internet)',
                      hintText: 'Internet',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: amountCtrl,
                      labelText: l10n.translate('amount'),
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: dueDateCtrl,
                      labelText: l10n.locale.languageCode == 'ar' ? 'يوم الاستحقاق في الشهر (1-31)' : 'Due Day of Month (1-31)',
                      hintText: '5',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedWalletId,
                      decoration: InputDecoration(
                        labelText: l10n.translate('wallet_name'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: budgetState.wallets.map((w) {
                        return DropdownMenuItem<int>(
                          value: w.id,
                          child: Text(w.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedWalletId = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: l10n.translate('category'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(l10n.getCategoryTranslation(cat)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                    final dueDay = int.tryParse(dueDateCtrl.text) ?? 1;

                    if (name.isNotEmpty && amount > 0 && dueDay >= 1 && dueDay <= 31) {
                      Navigator.pop(context);
                      await ref.read(commitmentControllerProvider.notifier).addCommitment(
                        name: name,
                        amount: amount,
                        dueDate: dueDay,
                        category: selectedCategory,
                        walletId: selectedWalletId,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.locale.languageCode == 'ar' ? 'إضافة' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCommitment(int id, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.locale.languageCode == 'ar' ? 'حذف الالتزام؟' : 'Delete Commitment?'),
          content: Text(
            l10n.locale.languageCode == 'ar'
                ? 'هل أنت متأكد من رغبتك في حذف هذا الالتزام الشهري؟ لن يتم مسح العمليات التي تم خصمها بالفعل.'
                : 'Are you sure you want to delete this monthly commitment? Already generated transactions will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(commitmentControllerProvider.notifier).deleteCommitment(id);
              },
              child: Text(l10n.locale.languageCode == 'ar' ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(l10nProvider);
    final state = ref.watch(commitmentControllerProvider);
    final budgetState = ref.watch(budgetControllerProvider);

    // Calculate totals
    double totalCommitments = 0;
    double paidCommitments = 0;
    for (var c in state.commitments) {
      totalCommitments += c.amount;
      if (c.isPaid) {
        paidCommitments += c.amount;
      }
    }
    double remainingCommitments = totalCommitments - paidCommitments;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locale.languageCode == 'ar' ? 'الالتزامات الشهرية' : 'Monthly Commitments'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCommitmentDialog(l10n),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Summary Card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 4,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: isDark
                                ? [theme.colorScheme.primary.withOpacity(0.8), theme.colorScheme.secondary.withOpacity(0.8)]
                                : [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.locale.languageCode == 'ar' ? 'ميزانية الالتزامات الدورية' : 'Recurring Commitments Budget',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${totalCommitments.toStringAsFixed(2)} ${l10n.translate('currency')}',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                            ),
                            const Divider(color: Colors.white24, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.locale.languageCode == 'ar' ? 'تم خصمه' : 'Deducted/Paid',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${paidCommitments.toStringAsFixed(2)} ${l10n.translate('currency')}',
                                      style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      l10n.locale.languageCode == 'ar' ? 'متبقي مستحق' : 'Remaining Due',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${remainingCommitments.toStringAsFixed(2)} ${l10n.translate('currency')}',
                                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: totalCommitments > 0 ? paidCommitments / totalCommitments : 0.0,
                                color: Colors.greenAccent,
                                backgroundColor: Colors.white24,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Commitments List
                  Expanded(
                    child: state.commitments.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_turned_in_outlined, size: 70, color: theme.colorScheme.primary.withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.locale.languageCode == 'ar'
                                        ? 'لا توجد التزامات شهرية مسجلة.\nاضغط على زر "+" لإضافة التزاماتك كالإيجار والإنترنت لتخصمها تلقائياً!'
                                        : 'No monthly commitments found.\nTap "+" to add recurring commitments like rent or internet and deduct them instantly!',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.grey, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.commitments.length,
                            itemBuilder: (context, index) {
                              final commitment = state.commitments[index];
                              final walletName = budgetState.wallets.firstWhere((w) => w.id == commitment.walletId, orElse: () => budgetState.wallets.first).name;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  child: Row(
                                    children: [
                                      // Toggle Switch to pay
                                      Switch(
                                        value: commitment.isPaid,
                                        activeColor: Colors.green,
                                        onChanged: (val) async {
                                          await ref.read(commitmentControllerProvider.notifier).togglePaid(commitment, val);
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              commitment.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                decoration: commitment.isPaid ? TextDecoration.lineThrough : null,
                                                color: commitment.isPaid ? Colors.grey : null,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  l10n.locale.languageCode == 'ar'
                                                      ? 'مستحق يوم ${commitment.dueDate} في الشهر'
                                                      : 'Due day ${commitment.dueDate}',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(Icons.account_balance_wallet_outlined, size: 12, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  walletName,
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${commitment.amount.toStringAsFixed(2)} ${l10n.translate('currency')}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              fontFamily: 'Outfit',
                                              color: commitment.isPaid ? Colors.green : Colors.redAccent,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () => _confirmDeleteCommitment(commitment.id, l10n),
                                            child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
