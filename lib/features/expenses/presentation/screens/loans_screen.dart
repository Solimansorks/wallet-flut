import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/loan_controller.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';
import 'package:personal_wallet/core/theme/app_theme.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  String _filterType = 'all'; // 'all', 'lent', 'borrowed', 'overdue'
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = ref.watch(l10nProvider);
    final isDark = theme.brightness == Brightness.dark;
    final loanState = ref.watch(loanControllerProvider);

    // Compute metrics dynamically
    double totalLent = 0.0; // money people owe me (lent)
    double totalBorrowed = 0.0; // money I owe people (borrowed)
    int openCount = 0;

    for (var l in loanState.loans) {
      final remaining = l.totalAmount - l.paidAmount;
      if (l.status != 'paid') {
        openCount++;
        if (l.type == 'lent') {
          totalLent += remaining;
        } else {
          totalBorrowed += remaining;
        }
      }
    }

    // Filter list
    var filtered = loanState.loans.where((l) {
      final isPaid = l.status == 'paid';
      if (_showArchived) {
        return isPaid; // Show only paid loans in archive
      } else {
        return !isPaid; // Show open/partial loans in active list
      }
    }).toList();

    if (_filterType == 'lent') {
      filtered = filtered.where((l) => l.type == 'lent').toList();
    } else if (_filterType == 'borrowed') {
      filtered = filtered.where((l) => l.type == 'borrowed').toList();
    } else if (_filterType == 'overdue') {
      filtered = filtered.where((l) => l.status != 'paid' && l.dueDate.isBefore(DateTime.now())).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('loans_debts')),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () => context.push('/financial-contacts'),
            tooltip: l10n.translate('financial_contacts'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(loanControllerProvider.notifier).loadLoans();
          },
          child: CustomScrollView(
            slivers: [
              // Header cards for Lent vs Borrowed totals
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          l10n.translate('my_loans'),
                          totalLent,
                          Colors.green,
                          isDark,
                          theme,
                          l10n,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          l10n.translate('my_debts'),
                          totalBorrowed,
                          Colors.red,
                          isDark,
                          theme,
                          l10n,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Active vs Archived toggle tab row
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(l10n.translate('active_loans')),
                        selected: !_showArchived,
                        onSelected: (val) {
                          if (val) setState(() => _showArchived = false);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(l10n.translate('archived_loans')),
                        selected: _showArchived,
                        onSelected: (val) {
                          if (val) setState(() => _showArchived = true);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Chips
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', l10n.locale.languageCode == 'ar' ? 'الكل' : 'All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('lent', l10n.translate('money_lent')),
                        const SizedBox(width: 8),
                        _buildFilterChip('borrowed', l10n.translate('money_borrowed')),
                        const SizedBox(width: 8),
                        _buildFilterChip('overdue', l10n.locale.languageCode == 'ar' ? 'متأخرة' : 'Overdue'),
                      ],
                    ),
                  ),
                ),
              ),

              // List of loans
              filtered.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            l10n.locale.languageCode == 'ar'
                                ? 'لا يوجد ديون أو سلف في هذه القائمة'
                                : 'No loans found in this category',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final loan = filtered[index];
                            final remaining = loan.totalAmount - loan.paidAmount;
                            final diff = loan.dueDate.difference(DateTime.now()).inDays;
                            final isOverdue = loan.status != 'paid' && diff < 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                leading: CircleAvatar(
                                  backgroundColor: loan.type == 'lent' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  child: Icon(
                                    loan.type == 'lent' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                    color: loan.type == 'lent' ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(loan.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      '${remaining.toStringAsFixed(0)} ${l10n.translate('currency')}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(loan.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(
                                        isOverdue
                                            ? (l10n.locale.languageCode == 'ar' ? 'متأخرة!' : 'Overdue!')
                                            : '${l10n.translate('due_date')}: ${loan.dueDate.day}/${loan.dueDate.month}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isOverdue ? Colors.red : Colors.grey,
                                          fontWeight: isOverdue ? FontWeight.bold : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () => context.push('/loan-details/${loan.id}'),
                              ),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-loan'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final selected = _filterType == type;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (sel) {
        if (sel) setState(() => _filterType = type);
      },
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
    );
  }

  Widget _buildMetricCard(String title, double amount, Color color, bool isDark, ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${amount.toStringAsFixed(0)} ${l10n.translate('currency')}',
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
        ],
      ),
    );
  }
}
