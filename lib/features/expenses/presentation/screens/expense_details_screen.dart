import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';
import 'package:personal_wallet/core/theme/app_theme.dart';

class ExpenseDetailsScreen extends ConsumerWidget {
  final int expenseId;

  const ExpenseDetailsScreen({super.key, required this.expenseId});

  IconData _getCategoryIcon(String category, String type) {
    if (type == 'deposit') {
      switch (category.toLowerCase()) {
        case 'salary':
          return Icons.work_rounded;
        case 'investment':
          return Icons.trending_up_rounded;
        case 'gift':
          return Icons.card_giftcard_rounded;
        default:
          return Icons.account_balance_wallet_rounded;
      }
    } else {
      switch (category.toLowerCase()) {
        case 'food':
          return Icons.restaurant_rounded;
        case 'transport':
          return Icons.directions_car_rounded;
        case 'shopping':
          return Icons.shopping_bag_rounded;
        case 'bills':
          return Icons.receipt_long_rounded;
        case 'entertainment':
          return Icons.sports_esports_rounded;
        case 'health':
          return Icons.medical_services_rounded;
        case 'education':
          return Icons.school_rounded;
        default:
          return Icons.category_rounded;
      }
    }
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.translate('delete_confirm_title')),
          content: Text(l10n.translate('delete_confirm_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(expenseControllerProvider.notifier).deleteExpense(expenseId);
                if (context.mounted) {
                  Navigator.pop(context); // Pop dialog
                  context.pop(); // Pop details screen
                }
              },
              child: Text(
                l10n.translate('delete'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final txAsyncValue = ref.watch(expenseProvider(expenseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('recent_expenses')),
        actions: [
          txAsyncValue.when(
            data: (tx) {
              if (tx == null) return const SizedBox();
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.push('/add-transaction?id=$expenseId'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () => _confirmDelete(context, ref, l10n),
                  ),
                ],
              );
            },
            error: (_, __) => const SizedBox(),
            loading: () => const SizedBox(),
          ),
        ],
      ),
      body: txAsyncValue.when(
        data: (tx) {
          if (tx == null) {
            return Center(
              child: Text(l10n.translate('no_expenses')),
            );
          }

          final isDeposit = tx.type == 'deposit';
          final categoryColor = isDeposit ? const Color(0xFF10B981) : AppTheme.getCategoryColor(tx.category);
          final categoryTranslation = l10n.getCategoryTranslation(tx.category);
          final sign = isDeposit ? '+' : '-';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Icon wrapper
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(tx.category, tx.type),
                      color: categoryColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category name
                  Text(
                    categoryTranslation,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Transaction Type Badge
                  Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDeposit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 14,
                          color: isDeposit ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDeposit ? l10n.translate('deposit') : l10n.translate('expense'),
                          style: TextStyle(
                            color: isDeposit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: (isDeposit ? Colors.green : Colors.red).withOpacity(0.1),
                  ),
                  const SizedBox(height: 32),

                  // Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.grey[50],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount Row
                        _buildDetailItem(
                          l10n.translate('amount'),
                          '$sign${tx.amount.toStringAsFixed(2)} ${l10n.translate('currency')}',
                          theme,
                          valueColor: isDeposit ? Colors.green : Colors.red,
                          isAmount: true,
                        ),
                        const Divider(height: 32),

                        // Date Row
                        _buildDetailItem(
                          l10n.translate('today'),
                          '${tx.date} • ${tx.time}',
                          theme,
                        ),
                        const Divider(height: 32),

                        // Description Row
                        _buildDetailItem(
                          l10n.translate('description'),
                          tx.description.isNotEmpty
                              ? tx.description
                              : l10n.translate('no_description'),
                          theme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        error: (err, __) => Center(child: Text(err.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
    bool isAmount = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
            fontSize: isAmount ? 24 : 16,
            fontFamily: isAmount ? 'Outfit' : null,
          ),
        ),
      ],
    );
  }
}
