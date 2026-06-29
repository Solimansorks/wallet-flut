import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:personal_wallet/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/loan_controller.dart';
import 'package:personal_wallet/features/expenses/domain/models/transaction.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/core/theme/app_theme.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _activeChartIndex = 0; // 0 = Line, 1 = Pie, 2 = Bar, 3 = Heatmap
  String _dateFilter = 'this_month'; // 'today', 'this_week', 'this_month', 'this_year', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<Transaction> _filteredTxs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportData();
    });
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });
    final db = ref.read(databaseServiceProvider);
    final txs = await db.getExpenses(
      dateFilter: _dateFilter,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
    );
    setState(() {
      _filteredTxs = txs;
      _isLoading = false;
    });
  }

  void _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      _loadReportData();
    }
  }

  double get _totalDeposits {
    final loans = ref.read(loanControllerProvider).loans;
    double sum = 0;
    for (var tx in _filteredTxs) {
      if (tx.type == 'deposit') {
        sum += tx.amount;
      } else if (tx.type == 'loan_repayment') {
        final parent = loans.where((l) => l.id == tx.loanId);
        if (parent.isNotEmpty && parent.first.type == 'lent') {
          sum += tx.amount;
        }
      }
    }
    return sum;
  }

  double get _totalExpenses {
    final loans = ref.read(loanControllerProvider).loans;
    double sum = 0;
    for (var tx in _filteredTxs) {
      if (tx.type == 'expense') {
        sum += tx.amount;
      } else if (tx.type == 'loan_repayment') {
        final parent = loans.where((l) => l.id == tx.loanId);
        if (parent.isNotEmpty && parent.first.type == 'borrowed') {
          sum += tx.amount;
        }
      }
    }
    return sum;
  }

  double get _highestExpense {
    double max = 0;
    for (var tx in _filteredTxs.where((t) => t.type == 'expense')) {
      if (tx.amount > max) max = tx.amount;
    }
    return max;
  }

  double get _averageExpense {
    final expenses = _filteredTxs.where((t) => t.type == 'expense');
    if (expenses.isEmpty) return 0;
    final total = expenses.fold(0.0, (sum, item) => sum + item.amount);
    return total / expenses.length;
  }

  List<CategoryStat> get _categoryStats {
    final expenses = _filteredTxs.where((t) => t.type == 'expense').toList();
    if (expenses.isEmpty) return [];

    final Map<String, double> totals = {};
    double totalSpent = 0;

    for (var exp in expenses) {
      totals[exp.category] = (totals[exp.category] ?? 0) + exp.amount;
      totalSpent += exp.amount;
    }

    return totals.entries.map((e) {
      return CategoryStat(
        category: e.key,
        amount: e.value,
        percentage: totalSpent > 0 ? (e.value / totalSpent) * 100 : 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  LedgerTrend get _dailyTrend {
    final Map<String, double> depTrend = {};
    final Map<String, double> expTrend = {};
    
    final Set<String> uniqueDates = _filteredTxs.map((t) => t.date).toSet();
    final List<String> sortedDates = uniqueDates.toList()..sort((a, b) {
      try {
        final partsA = a.split('/');
        final partsB = b.split('/');
        final dateA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
        final dateB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
        return dateA.compareTo(dateB);
      } catch (_) {
        return a.compareTo(b);
      }
    });

    if (sortedDates.isEmpty) {
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
        depTrend[key] = 0.0;
        expTrend[key] = 0.0;
      }
    } else {
      final datesToShow = sortedDates.length > 10 ? sortedDates.sublist(sortedDates.length - 10) : sortedDates;
      for (var date in datesToShow) {
        depTrend[date] = 0.0;
        expTrend[date] = 0.0;
      }
    }

    final loans = ref.read(loanControllerProvider).loans;
    for (var tx in _filteredTxs) {
      if (depTrend.containsKey(tx.date)) {
        bool isDep = tx.type == 'deposit';
        if (tx.type == 'loan_repayment') {
          final parent = loans.where((l) => l.id == tx.loanId);
          if (parent.isNotEmpty && parent.first.type == 'lent') {
            isDep = true;
          }
        }
        if (isDep) {
          depTrend[tx.date] = depTrend[tx.date]! + tx.amount;
        } else {
          expTrend[tx.date] = expTrend[tx.date]! + tx.amount;
        }
      }
    }

    return LedgerTrend(deposits: depTrend, expenses: expTrend);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = ref.watch(l10nProvider);
    final isDark = theme.brightness == Brightness.dark;

    final categoryStats = _categoryStats;
    final dailyTrend = _dailyTrend;
    final transactions = _filteredTxs;

    final hasTransactions = _filteredTxs.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locale.languageCode == 'ar' ? 'التقارير والإحصائيات' : 'Reports & Statistics'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Period selector card at the top
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.date_range_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _dateFilter,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'today', child: Text(l10n.translate('today'))),
                              DropdownMenuItem(value: 'yesterday', child: Text(l10n.translate('yesterday'))),
                              DropdownMenuItem(value: 'last_7_days', child: Text(l10n.translate('last_7_days'))),
                              DropdownMenuItem(value: 'this_month', child: Text(l10n.translate('this_month'))),
                              DropdownMenuItem(value: 'this_year', child: Text(l10n.translate('this_year'))),
                              DropdownMenuItem(value: 'custom', child: Text(l10n.translate('custom_range'))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                if (val != 'custom') {
                                  setState(() {
                                    _dateFilter = val;
                                  });
                                  _loadReportData();
                                } else {
                                  _pickCustomDateRange();
                                  setState(() {
                                    _dateFilter = val;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_dateFilter == 'custom' && _customStartDate != null && _customEndDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year} - ${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),

            // Main screen content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !hasTransactions
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pie_chart_outline_rounded,
                                  size: 80,
                                  color: theme.colorScheme.primary.withOpacity(0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.translate('no_expenses'),
                                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Income vs Expenses Comparison Card (The requested report)
                              Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 4,
                                shadowColor: theme.colorScheme.primary.withOpacity(0.1),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                          : [Colors.white, const Color(0xFFF8FAFC)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.locale.languageCode == 'ar'
                                            ? 'تقرير الإيرادات والمصروفات للفترة المحددة'
                                            : 'Period Income vs Expenses Report',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.translate('total_deposits'),
                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_totalDeposits.toStringAsFixed(2)} ${l10n.translate('currency')}',
                                                style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                l10n.translate('total_expenses'),
                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_totalExpenses.toStringAsFixed(2)} ${l10n.translate('currency')}',
                                                style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Comparative Progress Bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          height: 10,
                                          child: Builder(
                                            builder: (context) {
                                              final total = _totalDeposits + _totalExpenses;
                                              final progress = total > 0 ? _totalDeposits / total : 0.5;
                                              return LinearProgressIndicator(
                                                value: progress,
                                                color: Colors.green,
                                                backgroundColor: Colors.red,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            l10n.locale.languageCode == 'ar' ? 'الإيداعات' : 'Deposits',
                                            style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            l10n.locale.languageCode == 'ar' ? 'المصروفات' : 'Expenses',
                                            style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      // Net Saving
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            l10n.locale.languageCode == 'ar' ? 'صافي التوفير / الفائض' : 'Net Savings / Deficit',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${(_totalDeposits - _totalExpenses).toStringAsFixed(2)} ${l10n.translate('currency')}',
                                            style: TextStyle(
                                              color: (_totalDeposits - _totalExpenses) >= 0 ? Colors.green : Colors.red,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Outfit',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Quick Stats indicators
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMiniStat(
                                      l10n.translate('largest_expense'),
                                      _highestExpense,
                                      Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMiniStat(
                                      l10n.translate('daily_avg'),
                                      _averageExpense,
                                      Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMiniStat(
                                      l10n.translate('total_transactions'),
                                      _filteredTxs.length.toDouble(),
                                      Colors.blue,
                                      isCount: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Chart navigation slider tabs
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildTabButton(0, 'Trends / المنحنى', Icons.show_chart_rounded),
                                    const SizedBox(width: 8),
                                    _buildTabButton(1, 'Share / التصنيفات', Icons.pie_chart_rounded),
                                    const SizedBox(width: 8),
                                    _buildTabButton(2, 'Monthly / الشهري', Icons.bar_chart_rounded),
                                    const SizedBox(width: 8),
                                    _buildTabButton(3, 'Heatmap / الخريطة', Icons.calendar_month_rounded),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Render active visual layout
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _buildActiveChart(dailyTrend, categoryStats, transactions, isDark, theme, l10n),
                              ),
                              const SizedBox(height: 24),

                              // Category shares log list
                              if (_activeChartIndex == 1 && categoryStats.isNotEmpty) ...[
                                Text(
                                  l10n.locale.languageCode == 'ar' ? 'توزيع المصروفات' : 'Expense Distribution',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: categoryStats.length,
                                  itemBuilder: (context, index) {
                                    final stat = categoryStats[index];
                                    final color = AppTheme.getCategoryColor(stat.category);
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                        ),
                                        title: Text(l10n.getCategoryTranslation(stat.category)),
                                        subtitle: Text('${stat.percentage.toStringAsFixed(1)}%'),
                                        trailing: Text(
                                          '${stat.amount.toStringAsFixed(2)} ${l10n.translate('currency')}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final selected = _activeChartIndex == index;
    final theme = Theme.of(context);
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : theme.colorScheme.primary),
      label: Text(label),
      selected: selected,
      onSelected: (sel) {
        if (sel) setState(() => _activeChartIndex = index);
      },
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
    );
  }

  Widget _buildActiveChart(
    dynamic dailyTrend,
    List<CategoryStat> categoryStats,
    dynamic transactions,
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    switch (_activeChartIndex) {
      case 0:
        return _buildLineChart(dailyTrend, isDark, theme);
      case 1:
        return _buildPieChart(categoryStats, l10n, theme);
      case 2:
        return _buildBarChart(transactions, isDark, theme);
      case 3:
        return _buildHeatMapCalendar(transactions, isDark, theme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMiniStat(String label, double amount, Color color, {bool isCount = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            isCount ? '${amount.toInt()}' : amount.toStringAsFixed(0),
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(dynamic dailyTrend, bool isDark, ThemeData theme) {
    final depositSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    final dates = dailyTrend.deposits.keys.toList();

    for (int i = 0; i < dates.length; i++) {
      depositSpots.add(FlSpot(i.toDouble(), dailyTrend.deposits[dates[i]] ?? 0.0));
      expenseSpots.add(FlSpot(i.toDouble(), dailyTrend.expenses[dates[i]] ?? 0.0));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Deposit / إيداع', Colors.green),
                const SizedBox(width: 16),
                _buildLegendItem('Expense / مصروف', Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dates.length) {
                            final parts = dates[index].split('/');
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text('${parts[0]}/${parts[1]}', style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(spots: depositSpots, isCurved: true, color: Colors.green, barWidth: 3),
                    LineChartBarData(spots: expenseSpots, isCurved: true, color: Colors.red, barWidth: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildPieChart(List<CategoryStat> categoryStats, AppLocalizations l10n, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: categoryStats.map((stat) {
                final color = AppTheme.getCategoryColor(stat.category);
                return PieChartSectionData(
                  color: color,
                  value: stat.amount,
                  title: '${stat.percentage.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(dynamic transactions, bool isDark, ThemeData theme) {
    final Map<int, double> monthlySpent = {};
    final now = DateTime.now();

    // Group expenses by month index for the past 6 months
    for (int i = 0; i < 6; i++) {
      final month = (now.month - i - 1 + 12) % 12 + 1;
      monthlySpent[month] = 0.0;
    }

    for (var t in transactions) {
      if (t.type == 'expense' && monthlySpent.containsKey(t.createdAt.month)) {
        monthlySpent[t.createdAt.month] = monthlySpent[t.createdAt.month]! + t.amount;
      }
    }

    final barGroups = <BarChartGroupData>[];
    final sortedMonths = monthlySpent.keys.toList()..sort();

    for (int i = 0; i < sortedMonths.length; i++) {
      final m = sortedMonths[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthlySpent[m]!,
              color: theme.colorScheme.primary,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Expenses per Month / المصروفات شهرياً', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < sortedMonths.length) {
                            final m = sortedMonths[idx];
                            final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(monthNames[m - 1], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Calendar Spent intensity heatmap
  Widget _buildHeatMapCalendar(dynamic transactions, bool isDark, ThemeData theme) {
    final now = DateTime.now();
    final totalDays = DateUtils.getDaysInMonth(now.year, now.month);
    
    // Group expenses by calendar date
    final Map<int, double> dailyExpenses = {};
    for (int i = 1; i <= totalDays; i++) {
      dailyExpenses[i] = 0.0;
    }

    for (var t in transactions) {
      if (t.type == 'expense' && t.createdAt.year == now.year && t.createdAt.month == now.month) {
        dailyExpenses[t.createdAt.day] = (dailyExpenses[t.createdAt.day] ?? 0.0) + t.amount;
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Spend Calendar Heatmap / خريطة الصرف اليومي (${now.month}/${now.year})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: totalDays,
              itemBuilder: (context, index) {
                final day = index + 1;
                final spent = dailyExpenses[day] ?? 0.0;
                
                // Color intensity calculation
                Color cellColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
                if (spent > 0) {
                  if (spent < 100) {
                    cellColor = Colors.red.withOpacity(0.15);
                  } else if (spent < 500) {
                    cellColor = Colors.red.withOpacity(0.35);
                  } else if (spent < 1500) {
                    cellColor = Colors.red.withOpacity(0.65);
                  } else {
                    cellColor = Colors.red;
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: spent > 1000 ? Colors.white : null,
                          ),
                        ),
                        if (spent > 0)
                          Text(
                            spent.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 8,
                              color: spent > 1000 ? Colors.white70 : Colors.grey[700],
                            ),
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
    );
  }
}
