import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal_wallet/features/expenses/domain/models/transaction.dart';
import 'package:personal_wallet/features/expenses/domain/models/wallet.dart';
import 'package:personal_wallet/features/expenses/domain/models/budget.dart';
import 'package:personal_wallet/features/expenses/domain/models/savings_goal.dart';
import 'package:personal_wallet/features/expenses/domain/models/custom_category.dart';
import 'package:personal_wallet/features/expenses/domain/models/loan.dart';

class DatabaseService {
  Isar? _isar;
  final List<Transaction> _webMockExpenses = [];
  final List<Wallet> _webMockWallets = [];
  final List<Budget> _webMockBudgets = [];
  final List<SavingsGoal> _webMockSavingsGoals = [];
  final List<CustomCategory> _webMockCustomCategories = [];
  final List<Loan> _webMockLoans = [];
  
  int _webIdCounter = 1;
  int _webWalletIdCounter = 1;
  int _webBudgetIdCounter = 1;
  int _webGoalIdCounter = 1;
  int _webCatIdCounter = 1;
  int _webLoanIdCounter = 1;

  Isar get isar => _isar!;

  Future<void> init() async {
    if (kIsWeb) {
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        TransactionSchema,
        WalletSchema,
        BudgetSchema,
        SavingsGoalSchema,
        CustomCategorySchema,
        LoanSchema
      ],
      directory: dir.path,
    );
  }

  // Transactions
  Future<void> saveExpense(Transaction transaction) async {
    if (kIsWeb) {
      if (transaction.id == Isar.autoIncrement || transaction.id == 0) {
        transaction.id = _webIdCounter++;
        _webMockExpenses.add(transaction);
      } else {
        final index = _webMockExpenses.indexWhere((e) => e.id == transaction.id);
        if (index != -1) {
          _webMockExpenses[index] = transaction;
        }
      }
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.transactions.put(transaction);
    });
  }

  Future<void> deleteExpense(int id) async {
    if (kIsWeb) {
      _webMockExpenses.removeWhere((e) => e.id == id);
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.transactions.delete(id);
    });
  }

  Future<Transaction?> getExpense(int id) async {
    if (kIsWeb) {
      try {
        return _webMockExpenses.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }
    return await _isar!.transactions.get(id);
  }

  Future<List<Transaction>> getExpenses({
    String? searchQuery,
    String? filterCategory,
    String? filterType,
    String? dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? sortBy,
  }) async {
    if (kIsWeb) {
      List<Transaction> results = List.from(_webMockExpenses);

      if (filterCategory != null && filterCategory.toLowerCase() != 'all' && filterCategory.toLowerCase() != 'الكل') {
        results = results.where((e) => e.category.toLowerCase() == filterCategory.toLowerCase()).toList();
      }

      if (filterType != null && filterType != 'all') {
        results = results.where((e) => e.type == filterType).toList();
      }

      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day);
      DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      if (dateFilter != null) {
        DateTime? start;
        DateTime? end;

        if (dateFilter == 'today') {
          start = todayStart;
          end = todayEnd;
        } else if (dateFilter == 'yesterday') {
          start = todayStart.subtract(const Duration(days: 1));
          end = todayEnd.subtract(const Duration(days: 1));
        } else if (dateFilter == 'last_7_days') {
          start = todayStart.subtract(const Duration(days: 7));
          end = todayEnd;
        } else if (dateFilter == 'this_month') {
          start = DateTime(now.year, now.month, 1);
          end = todayEnd;
        } else if (dateFilter == 'this_year') {
          start = DateTime(now.year, 1, 1);
          end = todayEnd;
        } else if (dateFilter == 'custom' && customStartDate != null && customEndDate != null) {
          start = DateTime(customStartDate.year, customStartDate.month, customStartDate.day);
          end = DateTime(customEndDate.year, customEndDate.month, customEndDate.day, 23, 59, 59, 999);
        }

        if (start != null && end != null) {
          results = results.where((e) => e.createdAt.isAfter(start!) && e.createdAt.isBefore(end!)).toList();
        }
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final doubleSearch = double.tryParse(searchQuery);
        if (doubleSearch != null) {
          results = results.where((e) => e.amount == doubleSearch).toList();
        } else {
          final query = searchQuery.toLowerCase();
          results = results.where((e) =>
              e.description.toLowerCase().contains(query) ||
              e.category.toLowerCase().contains(query) ||
              e.date.toLowerCase().contains(query)).toList();
        }
      }

      if (sortBy == 'oldest') {
        results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else if (sortBy == 'highest_amount') {
        results.sort((a, b) => b.amount.compareTo(a.amount));
      } else if (sortBy == 'lowest_amount') {
        results.sort((a, b) => a.amount.compareTo(b.amount));
      } else if (sortBy == 'category') {
        results.sort((a, b) => a.category.compareTo(b.category));
      } else {
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      return results;
    }

    var queryBuilder = _isar!.transactions.where();
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    QueryBuilder<Transaction, Transaction, QAfterFilterCondition> filterQuery;

    if (dateFilter != null || customStartDate != null) {
      DateTime start = todayStart;
      DateTime end = todayEnd;

      if (dateFilter == 'today') {
        start = todayStart;
        end = todayEnd;
      } else if (dateFilter == 'yesterday') {
        start = todayStart.subtract(const Duration(days: 1));
        end = todayEnd.subtract(const Duration(days: 1));
      } else if (dateFilter == 'last_7_days') {
        start = todayStart.subtract(const Duration(days: 7));
        end = todayEnd;
      } else if (dateFilter == 'this_month') {
        start = DateTime(now.year, now.month, 1);
        end = todayEnd;
      } else if (dateFilter == 'this_year') {
        start = DateTime(now.year, 1, 1);
        end = todayEnd;
      } else if (dateFilter == 'custom' && customStartDate != null && customEndDate != null) {
        start = DateTime(customStartDate.year, customStartDate.month, customStartDate.day);
        end = DateTime(customEndDate.year, customEndDate.month, customEndDate.day, 23, 59, 59, 999);
      }

      filterQuery = queryBuilder.filter().createdAtBetween(start, end);
    } else {
      filterQuery = queryBuilder.filter().idGreaterThan(-1);
    }

    if (filterCategory != null && filterCategory.toLowerCase() != 'all' && filterCategory.toLowerCase() != 'الكل') {
      filterQuery = filterQuery.categoryEqualTo(filterCategory);
    }

    if (filterType != null && filterType != 'all') {
      filterQuery = filterQuery.and().typeEqualTo(filterType);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final doubleSearch = double.tryParse(searchQuery);
      if (doubleSearch != null) {
        filterQuery = filterQuery.and().amountEqualTo(doubleSearch);
      } else {
        filterQuery = filterQuery.and().group((q) => q
            .descriptionContains(searchQuery, caseSensitive: false)
            .or()
            .categoryContains(searchQuery, caseSensitive: false)
            .or()
            .dateContains(searchQuery, caseSensitive: false));
      }
    }

    QueryBuilder<Transaction, Transaction, QAfterSortBy> sortQuery;
    if (sortBy == 'oldest') {
      sortQuery = filterQuery.sortByCreatedAt();
    } else if (sortBy == 'highest_amount') {
      sortQuery = filterQuery.sortByAmountDesc();
    } else if (sortBy == 'lowest_amount') {
      sortQuery = filterQuery.sortByAmount();
    } else if (sortBy == 'category') {
      sortQuery = filterQuery.sortByCategory();
    } else {
      sortQuery = filterQuery.sortByCreatedAtDesc();
    }

    return await sortQuery.findAll();
  }

  // Wallets
  Future<List<Wallet>> getWallets() async {
    if (kIsWeb) return List.from(_webMockWallets);
    return await _isar!.wallets.where().findAll();
  }

  Future<void> saveWallet(Wallet wallet) async {
    if (kIsWeb) {
      if (wallet.id == Isar.autoIncrement || wallet.id == 0) {
        wallet.id = _webWalletIdCounter++;
        _webMockWallets.add(wallet);
      } else {
        final index = _webMockWallets.indexWhere((w) => w.id == wallet.id);
        if (index != -1) _webMockWallets[index] = wallet;
      }
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.wallets.put(wallet);
    });
  }

  Future<void> deleteWallet(int id) async {
    if (kIsWeb) {
      _webMockWallets.removeWhere((w) => w.id == id);
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.wallets.delete(id);
    });
  }

  // Budgets
  Future<List<Budget>> getBudgets() async {
    if (kIsWeb) return List.from(_webMockBudgets);
    return await _isar!.budgets.where().findAll();
  }

  Future<void> saveBudget(Budget budget) async {
    if (kIsWeb) {
      if (budget.id == Isar.autoIncrement || budget.id == 0) {
        budget.id = _webBudgetIdCounter++;
        _webMockBudgets.add(budget);
      } else {
        final index = _webMockBudgets.indexWhere((b) => b.id == budget.id);
        if (index != -1) _webMockBudgets[index] = budget;
      }
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.budgets.put(budget);
    });
  }

  Future<void> deleteBudget(int id) async {
    if (kIsWeb) {
      _webMockBudgets.removeWhere((b) => b.id == id);
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.budgets.delete(id);
    });
  }

  // Savings Goals
  Future<List<SavingsGoal>> getSavingsGoals() async {
    if (kIsWeb) return List.from(_webMockSavingsGoals);
    return await _isar!.savingsGoals.where().findAll();
  }

  Future<void> saveSavingsGoal(SavingsGoal goal) async {
    if (kIsWeb) {
      if (goal.id == Isar.autoIncrement || goal.id == 0) {
        goal.id = _webGoalIdCounter++;
        _webMockSavingsGoals.add(goal);
      } else {
        final index = _webMockSavingsGoals.indexWhere((g) => g.id == goal.id);
        if (index != -1) _webMockSavingsGoals[index] = goal;
      }
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.savingsGoals.put(goal);
    });
  }

  Future<void> deleteSavingsGoal(int id) async {
    if (kIsWeb) {
      _webMockSavingsGoals.removeWhere((g) => g.id == id);
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.savingsGoals.delete(id);
    });
  }

  // Custom Categories
  Future<List<CustomCategory>> getCustomCategories() async {
    if (kIsWeb) return List.from(_webMockCustomCategories);
    return await _isar!.customCategorys.where().findAll();
  }

  Future<void> saveCustomCategory(CustomCategory cat) async {
    if (kIsWeb) {
      if (cat.id == Isar.autoIncrement || cat.id == 0) {
        cat.id = _webCatIdCounter++;
        _webMockCustomCategories.add(cat);
      } else {
        final index = _webMockCustomCategories.indexWhere((c) => c.id == cat.id);
        if (index != -1) _webMockCustomCategories[index] = cat;
      }
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.customCategorys.put(cat);
    });
  }

  Future<void> deleteCustomCategory(int id) async {
    if (kIsWeb) {
      _webMockCustomCategories.removeWhere((c) => c.id == id);
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.customCategorys.delete(id);
    });
  }

  // Loans & Debts
  Future<List<Loan>> getLoans() async {
    if (kIsWeb) return List.from(_webMockLoans);
    return await _isar!.loans.where().findAll();
  }

  Future<Loan?> getLoan(int id) async {
    if (kIsWeb) {
      try {
        return _webMockLoans.firstWhere((l) => l.id == id);
      } catch (_) {
        return null;
      }
    }
    return await _isar!.loans.get(id);
  }

  Future<void> saveLoan(Loan loan) async {
    if (kIsWeb) {
      if (loan.id == Isar.autoIncrement || loan.id == 0) {
        loan.id = _webLoanIdCounter++;
        _webMockLoans.add(loan);
      } else {
        final index = _webMockLoans.indexWhere((l) => l.id == loan.id);
        if (index != -1) _webMockLoans[index] = loan;
      }
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.loans.put(loan);
    });
  }

  Future<void> deleteLoan(int id) async {
    if (kIsWeb) {
      _webMockLoans.removeWhere((l) => l.id == id);
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.loans.delete(id);
    });
  }

  // Utility
  Future<void> clearAllData() async {
    if (kIsWeb) {
      _webMockExpenses.clear();
      _webMockWallets.clear();
      _webMockBudgets.clear();
      _webMockSavingsGoals.clear();
      _webMockCustomCategories.clear();
      _webMockLoans.clear();
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.transactions.clear();
      await _isar!.wallets.clear();
      await _isar!.budgets.clear();
      await _isar!.savingsGoals.clear();
      await _isar!.customCategorys.clear();
      await _isar!.loans.clear();
    });
  }

  Future<void> importExpenses(List<Transaction> transactions) async {
    if (kIsWeb) {
      _webMockExpenses.clear();
      _webMockExpenses.addAll(transactions);
      _webIdCounter = transactions.isEmpty ? 1 : transactions.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.transactions.putAll(transactions);
    });
  }
}
