import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/budget_controller.dart';
import 'package:personal_wallet/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/core/theme/app_theme.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';
import 'package:personal_wallet/shared/widgets/expense_card.dart';
import 'package:personal_wallet/features/settings/presentation/controllers/settings_controller.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/loan_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _quickAmountController = TextEditingController();
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  
  String _selectedType = 'expense'; // 'deposit' or 'expense'
  String _selectedCategory = 'Food';
  String _selectedPaymentMethod = 'Cash';
  int _selectedWalletId = 1;

  // Filters state
  String _filterPaymentMethod = 'all';
  double? _filterMinAmount;
  double? _filterMaxAmount;

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

  // Quick favorites shortcuts (Category, Amount, Type, Icon)
  final List<Map<String, dynamic>> _quickFavorites = [
    {'category': 'Food', 'amount': 150.0, 'type': 'expense', 'icon': Icons.restaurant_rounded, 'label': '🍔 أكل'},
    {'category': 'Transport', 'amount': 30.0, 'type': 'expense', 'icon': Icons.directions_car_rounded, 'label': '🚕 مواصلات'},
    {'category': 'Bills', 'amount': 50.0, 'type': 'expense', 'icon': Icons.flash_on_rounded, 'label': '☕ قهوة'},
    {'category': 'Other', 'amount': 500.0, 'type': 'expense', 'icon': Icons.local_gas_station_rounded, 'label': '⛽ بنزين'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastUsedCategory();
    });
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

  @override
  void dispose() {
    _quickAmountController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _addQuickTransaction() async {
    final amountText = _quickAmountController.text;
    final amount = double.tryParse(amountText);
    final l10n = ref.read(l10nProvider);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('invalid_amount')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref.read(expenseControllerProvider.notifier).addTransaction(
          amount: amount,
          type: _selectedType,
          category: _selectedCategory,
          description: '',
        );

    _quickAmountController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.translate('fast_entry')}: ${l10n.translate('transaction_saved')}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _addFavoriteTransaction(Map<String, dynamic> fav) async {
    final l10n = ref.read(l10nProvider);
    await ref.read(expenseControllerProvider.notifier).addTransaction(
          amount: fav['amount'],
          type: fav['type'],
          category: fav['category'],
          description: fav['label'],
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${fav['label']} (${fav['amount']} ${l10n.translate('currency')}) - ${l10n.translate('transaction_saved')}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatMoney(double amount, AppLocalizations l10n, bool hide) {
    if (hide) return '***';
    return '${amount.toStringAsFixed(2)} ${l10n.translate('currency')}';
  }

  void _showAddWalletDialog(AppLocalizations l10n) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.translate('add_wallet')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name / الاسم'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Initial Balance / الرصيد الافتتاحي'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.translate('cancel'))),
            TextButton(
              onPressed: () async {
                final balance = double.tryParse(balanceCtrl.text) ?? 0.0;
                if (nameCtrl.text.isNotEmpty) {
                  await ref.read(budgetControllerProvider.notifier).addWallet(
                    nameCtrl.text,
                    0xef63,
                    0xFF0EA5E9,
                    balance,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: Text(l10n.translate('save')),
            ),
          ],
        );
      },
    );
  }

  void _showAddBudgetDialog(AppLocalizations l10n) {
    final limitCtrl = TextEditingController();
    String cat = _expenseCategories.first;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.translate('add_budget')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: cat,
                items: _expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(l10n.getCategoryTranslation(c)))).toList(),
                onChanged: (val) {
                  if (val != null) cat = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Limit / الحد المالي'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.translate('cancel'))),
            TextButton(
              onPressed: () async {
                final limit = double.tryParse(limitCtrl.text) ?? 0.0;
                if (limit > 0) {
                  await ref.read(budgetControllerProvider.notifier).addBudget(cat, limit);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: Text(l10n.translate('save')),
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
    final stats = ref.watch(dashboardStatsProvider);
    final txState = ref.watch(expenseControllerProvider);
    final budgetState = ref.watch(budgetControllerProvider);
    final controller = ref.read(expenseControllerProvider.notifier);
    final settings = ref.watch(settingsControllerProvider);
    final settingsCtrl = ref.read(settingsControllerProvider.notifier);

    final categories = _selectedType == 'deposit' ? _depositCategories : _expenseCategories;

    // Filter transactions list locally to support advanced filter rules
    var filteredTxs = txState.transactions;
    if (_filterPaymentMethod != 'all') {
      filteredTxs = filteredTxs.where((t) => t.paymentMethod == _filterPaymentMethod).toList();
    }
    if (_filterMinAmount != null) {
      filteredTxs = filteredTxs.where((t) => t.amount >= _filterMinAmount!).toList();
    }
    if (_filterMaxAmount != null) {
      filteredTxs = filteredTxs.where((t) => t.amount <= _filterMaxAmount!).toList();
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await controller.loadTransactions();
            await ref.read(budgetControllerProvider.notifier).loadAll();
          },
          child: CustomScrollView(
            slivers: [
              // premium app bar
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('app_name'),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            l10n.translate('dashboard'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              settings.hideBalances ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                            onPressed: () => settingsCtrl.toggleHideBalances(!settings.hideBalances),
                          ),
                          IconButton(
                            icon: const Icon(Icons.handshake_outlined),
                            onPressed: () => context.push('/loans'),
                            tooltip: l10n.translate('loans_debts'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bar_chart_rounded),
                            onPressed: () => context.push('/statistics'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // swipable Wallet Carousel
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: budgetState.wallets.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Net Worth Wallet
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [theme.colorScheme.primary.withOpacity(0.8), theme.colorScheme.secondary.withOpacity(0.8)]
                                    : [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate('net_worth'),
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatMoney(stats.currentBalance, l10n, settings.hideBalances),
                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('💳 All Accounts', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                                      onPressed: () => _showAddWalletDialog(l10n),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        
                        final wallet = budgetState.wallets[index - 1];
                        final loans = ref.watch(loanControllerProvider).loans;
                        final walletTransactions = txState.transactions.where((t) => t.walletId == wallet.id || t.toWalletId == wallet.id);
                        double currentWalletBalance = wallet.initialBalance;

                        for (var t in walletTransactions) {
                          if (t.type == 'deposit') {
                            if (t.walletId == wallet.id) {
                              currentWalletBalance += t.amount;
                            }
                          } else if (t.type == 'expense') {
                            if (t.walletId == wallet.id) {
                              currentWalletBalance -= t.amount;
                            }
                          } else if (t.type == 'transfer') {
                            if (t.walletId == wallet.id) {
                              currentWalletBalance -= t.amount;
                            }
                            if (t.toWalletId == wallet.id) {
                              currentWalletBalance += t.amount;
                            }
                          } else if (t.type == 'loan_repayment') {
                            final l = loans.where((item) => item.id == t.loanId);
                            if (l.isNotEmpty) {
                              final parentLoan = l.first;
                              if (parentLoan.type == 'lent') {
                                if (t.walletId == wallet.id) {
                                  currentWalletBalance += t.amount;
                                }
                              } else {
                                if (t.walletId == wallet.id) {
                                  currentWalletBalance -= t.amount;
                                }
                              }
                            }
                          }
                        }

                        return Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Color(wallet.colorValue).withOpacity(isDark ? 0.3 : 0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallet.name,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatMoney(currentWalletBalance, l10n, settings.hideBalances),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                              ),
                              const Spacer(),
                              Text('Cash source', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Stats Row (Today / Week / Month spent)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTimeStatCard('today_spent', stats.todayTotal, l10n, settings.hideBalances, isDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTimeStatCard('this_week', stats.weeklyTotal, l10n, settings.hideBalances, isDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTimeStatCard('month_spent', stats.monthlyTotal, l10n, settings.hideBalances, isDark),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick-Add favorites shortcuts
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('quick_add'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _quickFavorites.length,
                        itemBuilder: (context, index) {
                          final fav = _quickFavorites[index];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              onTap: () => _addFavoriteTransaction(fav),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Icon(fav['icon'], color: theme.colorScheme.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(fav['label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text('${fav['amount']} ${l10n.translate('currency')}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Budgets progress ceilings
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.translate('active_budgets'),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: () => _showAddBudgetDialog(l10n),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      budgetState.budgets.isEmpty
                          ? const Text('No Budgets set / لا يوجد ميزانيات محددة')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: budgetState.budgets.length,
                              itemBuilder: (context, index) {
                                final budget = budgetState.budgets[index];
                                // compute current monthly spent for this category
                                final monthlySpent = txState.transactions
                                    .where((t) => t.type == 'expense' && t.category == budget.category && t.createdAt.month == DateTime.now().month)
                                    .fold(0.0, (sum, item) => sum + item.amount);
                                final progress = budget.limitAmount > 0 ? (monthlySpent / budget.limitAmount).clamp(0.0, 1.0) : 0.0;
                                final percent = (progress * 100).toStringAsFixed(0);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(l10n.getCategoryTranslation(budget.category), style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text('$monthlySpent / ${budget.limitAmount} ($percent%)'),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: progress,
                                          color: progress >= 0.8 ? Colors.red : theme.colorScheme.primary,
                                          backgroundColor: Colors.grey.withOpacity(0.2),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),

              // Fast Entry Form
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.translate('fast_entry'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
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
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedType = 'deposit');
                                  _loadLastUsedCategory();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedType = 'expense');
                                  _loadLastUsedCategory();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _quickAmountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: l10n.translate('amount'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(l10n.getCategoryTranslation(cat)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCategory = val);
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              icon: const Icon(Icons.check),
                              onPressed: _addQuickTransaction,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search & Advanced Filters
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => controller.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: l10n.translate('search_placeholder'),
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          filled: true,
                          fillColor: isDark ? AppTheme.surfaceDark : Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Filter options row
                      ExpansionTile(
                        title: Text(l10n.locale.languageCode == 'ar' ? 'خيارات الفلترة المتقدمة' : 'Advanced Filters'),
                        leading: const Icon(Icons.filter_list_rounded),
                        children: [
                          // Min / Max Price Filter
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _minPriceController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => setState(() => _filterMinAmount = double.tryParse(val)),
                                    decoration: const InputDecoration(labelText: 'Min EGP / الحد الأدنى'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _maxPriceController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => setState(() => _filterMaxAmount = double.tryParse(val)),
                                    decoration: const InputDecoration(labelText: 'Max EGP / الحد الأقصى'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Payment Method Filter dropdown
                          DropdownButtonFormField<String>(
                            value: _filterPaymentMethod,
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('All Payment Methods / كل وسائل الدفع')),
                              ..._paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _filterPaymentMethod = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      
                      // Type Chip filters
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text(l10n.locale.languageCode == 'ar' ? 'الكل' : 'All'),
                            selected: txState.filterType == 'all',
                            onSelected: (sel) => controller.setFilterType('all'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(l10n.translate('deposit')),
                            selected: txState.filterType == 'deposit',
                            onSelected: (sel) => controller.setFilterType('deposit'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(l10n.translate('expense')),
                            selected: txState.filterType == 'expense',
                            onSelected: (sel) => controller.setFilterType('expense'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Ledger Transactions
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    l10n.translate('recent_expenses'),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              filteredTxs.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(l10n.translate('no_expenses')),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tx = filteredTxs[index];
                            return ExpenseCard(
                              expense: tx,
                              onTap: () => context.push('/transaction-details/${tx.id}'),
                            );
                          },
                          childCount: filteredTxs.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-transaction'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.translate('add_transaction')),
      ),
    );
  }

  Widget _buildTimeStatCard(String labelKey, double amount, AppLocalizations l10n, bool hide, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.translate(labelKey), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            hide ? '***' : amount.toStringAsFixed(0),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Outfit'),
          ),
        ],
      ),
    );
  }
}
