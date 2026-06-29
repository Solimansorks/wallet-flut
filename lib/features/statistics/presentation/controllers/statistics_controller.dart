import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:personal_wallet/features/expenses/domain/models/transaction.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/loan_controller.dart';

class CategoryStat {
  final String category;
  final double amount;
  final double percentage;

  CategoryStat({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class DashboardStats {
  final double currentBalance;
  final double totalDeposits;
  final double totalExpenses;
  final double todayTotal;
  final double yesterdayTotal;
  final double weeklyTotal;
  final double monthlyTotal;
  final int totalTransactions;
  final double highestExpense;
  final double lowestExpense;
  final double averageExpense;

  DashboardStats({
    required this.currentBalance,
    required this.totalDeposits,
    required this.totalExpenses,
    required this.todayTotal,
    required this.yesterdayTotal,
    required this.weeklyTotal,
    required this.monthlyTotal,
    required this.totalTransactions,
    required this.highestExpense,
    required this.lowestExpense,
    required this.averageExpense,
  });
}

class LedgerTrend {
  final Map<String, double> deposits;
  final Map<String, double> expenses;

  LedgerTrend({
    required this.deposits,
    required this.expenses,
  });
}

// Watch transactions and compute dashboard statistics
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final txs = ref.watch(expenseControllerProvider).transactions;
  final loans = ref.watch(loanControllerProvider).loans;
  final storage = ref.watch(storageServiceProvider);
  final initialBalance = storage.getInitialBalance();
  
  if (txs.isEmpty) {
    return DashboardStats(
      currentBalance: initialBalance,
      totalDeposits: 0,
      totalExpenses: 0,
      todayTotal: 0,
      yesterdayTotal: 0,
      weeklyTotal: 0,
      monthlyTotal: 0,
      totalTransactions: 0,
      highestExpense: 0,
      lowestExpense: 0,
      averageExpense: 0,
    );
  }

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  
  final yesterdayStart = todayStart.subtract(const Duration(days: 1));
  final yesterdayEnd = todayEnd.subtract(const Duration(days: 1));

  final weekStart = todayStart.subtract(const Duration(days: 7));
  final monthStart = DateTime(now.year, now.month, 1);

  double totalDeposits = 0;
  double totalExpenses = 0;
  double todayTotal = 0;
  double yesterdayTotal = 0;
  double weeklyTotal = 0;
  double monthlyTotal = 0;

  double highest = 0;
  double lowest = double.maxFinite;

  for (var tx in txs) {
    bool isDep = false;
    bool isExp = false;
    
    if (tx.type == 'deposit') {
      isDep = true;
    } else if (tx.type == 'expense') {
      isExp = true;
    } else if (tx.type == 'loan_repayment') {
      final parent = loans.where((l) => l.id == tx.loanId);
      if (parent.isNotEmpty) {
        if (parent.first.type == 'lent') {
          isDep = true;
        } else {
          isExp = true;
        }
      }
    }

    final amount = tx.amount;

    if (isDep) {
      totalDeposits += amount;
    } else if (isExp) {
      totalExpenses += amount;
      if (amount > highest) highest = amount;
      if (amount < lowest) lowest = amount;
    }

    if (tx.createdAt.isAfter(todayStart) && tx.createdAt.isBefore(todayEnd)) {
      if (isExp) todayTotal += amount;
    }
    if (tx.createdAt.isAfter(yesterdayStart) && tx.createdAt.isBefore(yesterdayEnd)) {
      if (isExp) yesterdayTotal += amount;
    }
    if (tx.createdAt.isAfter(weekStart)) {
      if (isExp) weeklyTotal += amount;
    }
    if (tx.createdAt.isAfter(monthStart)) {
      if (isExp) monthlyTotal += amount;
    }
  }

  final currentBalance = initialBalance + totalDeposits - totalExpenses;
  final expenseCount = txs.where((t) => t.type == 'expense').length;

  return DashboardStats(
    currentBalance: currentBalance,
    totalDeposits: totalDeposits,
    totalExpenses: totalExpenses,
    todayTotal: todayTotal,
    yesterdayTotal: yesterdayTotal,
    weeklyTotal: weeklyTotal,
    monthlyTotal: monthlyTotal,
    totalTransactions: txs.length,
    highestExpense: highest,
    lowestExpense: lowest == double.maxFinite ? 0.0 : lowest,
    averageExpense: expenseCount > 0 ? totalExpenses / expenseCount : 0.0,
  );
});

// Watch transactions and group expenses by category
final categoryStatsProvider = Provider<List<CategoryStat>>((ref) {
  final txs = ref.watch(expenseControllerProvider).transactions;
  final expenses = txs.where((t) => t.type == 'expense').toList();
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
});

// Watch transactions and group by date for Double Trend charts
final dailyTrendProvider = Provider<LedgerTrend>((ref) {
  final txs = ref.watch(expenseControllerProvider).transactions;
  final Map<String, double> depTrend = {};
  final Map<String, double> expTrend = {};
  
  final now = DateTime.now();
  for (int i = 6; i >= 0; i--) {
    final d = now.subtract(Duration(days: i));
    final key = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    depTrend[key] = 0.0;
    expTrend[key] = 0.0;
  }

  for (var tx in txs) {
    if (depTrend.containsKey(tx.date)) {
      if (tx.type == 'deposit') {
        depTrend[tx.date] = depTrend[tx.date]! + tx.amount;
      } else {
        expTrend[tx.date] = expTrend[tx.date]! + tx.amount;
      }
    }
  }

  return LedgerTrend(deposits: depTrend, expenses: expTrend);
});
