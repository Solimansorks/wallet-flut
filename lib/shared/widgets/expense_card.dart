import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/features/expenses/domain/models/transaction.dart';
import 'package:personal_wallet/core/theme/app_theme.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';

class ExpenseCard extends ConsumerWidget {
  final Transaction expense;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ExpenseCard({
    Key? key,
    required this.expense,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isDeposit = expense.type == 'deposit';
    final categoryColor = isDeposit ? const Color(0xFF10B981) : AppTheme.getCategoryColor(expense.category); // Green for deposits, standard for expenses
    final categoryTranslation = l10n.getCategoryTranslation(expense.category);

    final sign = isDeposit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon Wrapper
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.category, expense.type),
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDeposit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: isDeposit ? Colors.green : Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            categoryTranslation,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expense.description.isNotEmpty
                            ? expense.description
                            : l10n.translate('no_description'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Date & Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign${expense.amount.toStringAsFixed(2)} ${l10n.translate('currency')}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDeposit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expense.date} • ${expense.time}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
