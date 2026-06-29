import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/features/expenses/domain/models/wallet.dart';
import 'package:personal_wallet/features/expenses/domain/models/budget.dart';
import 'package:personal_wallet/features/expenses/domain/models/savings_goal.dart';
import 'package:personal_wallet/features/expenses/domain/models/custom_category.dart';

class BudgetState {
  final List<Wallet> wallets;
  final List<Budget> budgets;
  final List<SavingsGoal> savingsGoals;
  final List<CustomCategory> customCategories;
  final bool isLoading;

  BudgetState({
    this.wallets = const [],
    this.budgets = const [],
    this.savingsGoals = const [],
    this.customCategories = const [],
    this.isLoading = false,
  });

  BudgetState copyWith({
    List<Wallet>? wallets,
    List<Budget>? budgets,
    List<SavingsGoal>? savingsGoals,
    List<CustomCategory>? customCategories,
    bool? isLoading,
  }) {
    return BudgetState(
      wallets: wallets ?? this.wallets,
      budgets: budgets ?? this.budgets,
      savingsGoals: savingsGoals ?? this.savingsGoals,
      customCategories: customCategories ?? this.customCategories,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BudgetController extends StateNotifier<BudgetState> {
  final Ref _ref;

  BudgetController(this._ref) : super(BudgetState()) {
    initDefaultsAndLoad();
  }

  Future<void> initDefaultsAndLoad() async {
    state = state.copyWith(isLoading: true);
    final db = _ref.read(databaseServiceProvider);
    
    // Check if we need to seed default wallets
    final existingWallets = await db.getWallets();
    if (existingWallets.isEmpty) {
      final defaultWallets = [
        Wallet()..name = 'Cash'..iconCode = 0xef63..colorValue = 0xFF0EA5E9..initialBalance = 0.0,
        Wallet()..name = 'Bank'..iconCode = 0xf04e2..colorValue = 0xFF10B981..initialBalance = 0.0,
        Wallet()..name = 'Vodafone Cash'..iconCode = 0xe4e2..colorValue = 0xFFEF4444..initialBalance = 0.0,
        Wallet()..name = 'Instapay'..iconCode = 0xf05a6..colorValue = 0xFF6366F1..initialBalance = 0.0,
      ];
      for (var w in defaultWallets) {
        await db.saveWallet(w);
      }
    }

    await loadAll();
  }

  Future<void> loadAll() async {
    final db = _ref.read(databaseServiceProvider);
    final wallets = await db.getWallets();
    final budgets = await db.getBudgets();
    final goals = await db.getSavingsGoals();
    final customCats = await db.getCustomCategories();

    state = BudgetState(
      wallets: wallets,
      budgets: budgets,
      savingsGoals: goals,
      customCategories: customCats,
      isLoading: false,
    );
  }

  // Wallets
  Future<void> addWallet(String name, int iconCode, int colorValue, double initialBalance) async {
    final wallet = Wallet()
      ..name = name
      ..iconCode = iconCode
      ..colorValue = colorValue
      ..initialBalance = initialBalance;
    final db = _ref.read(databaseServiceProvider);
    await db.saveWallet(wallet);
    await loadAll();
  }

  Future<void> deleteWallet(int id) async {
    final db = _ref.read(databaseServiceProvider);
    await db.deleteWallet(id);
    await loadAll();
  }

  // Budgets
  Future<void> addBudget(String category, double limitAmount) async {
    final budget = Budget()
      ..category = category
      ..limitAmount = limitAmount;
    final db = _ref.read(databaseServiceProvider);
    await db.saveBudget(budget);
    await loadAll();
  }

  Future<void> deleteBudget(int id) async {
    final db = _ref.read(databaseServiceProvider);
    await db.deleteBudget(id);
    await loadAll();
  }

  // Savings Goals
  Future<void> addSavingsGoal(String title, double targetAmount, double savedAmount) async {
    final goal = SavingsGoal()
      ..title = title
      ..targetAmount = targetAmount
      ..savedAmount = savedAmount;
    final db = _ref.read(databaseServiceProvider);
    await db.saveSavingsGoal(goal);
    await loadAll();
  }

  Future<void> updateSavingsGoal(int id, double newSavedAmount) async {
    final db = _ref.read(databaseServiceProvider);
    final goal = state.savingsGoals.firstWhere((g) => g.id == id);
    goal.savedAmount = newSavedAmount;
    await db.saveSavingsGoal(goal);
    await loadAll();
  }

  Future<void> deleteSavingsGoal(int id) async {
    final db = _ref.read(databaseServiceProvider);
    await db.deleteSavingsGoal(id);
    await loadAll();
  }

  // Custom Categories
  Future<void> addCustomCategory(String name, String type) async {
    final cat = CustomCategory()
      ..name = name
      ..type = type;
    final db = _ref.read(databaseServiceProvider);
    await db.saveCustomCategory(cat);
    await loadAll();
  }

  Future<void> deleteCustomCategory(int id) async {
    final db = _ref.read(databaseServiceProvider);
    await db.deleteCustomCategory(id);
    await loadAll();
  }
}

final budgetControllerProvider = StateNotifierProvider<BudgetController, BudgetState>((ref) {
  return BudgetController(ref);
});
