import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/features/expenses/domain/models/transaction.dart';

class TransactionListState {
  final List<Transaction> transactions;
  final List<Transaction> allTransactions;
  final bool isLoading;
  final String searchQuery;
  final String dateFilter; // today, yesterday, last_7_days, this_month, this_year, custom
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String sortBy; // newest, oldest, highest_amount, lowest_amount, category
  final String filterCategory;
  final String filterType; // 'all', 'deposit', 'expense'
  final int limit;
  final bool hasMore;

  TransactionListState({
    this.transactions = const [],
    this.allTransactions = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.dateFilter = 'today',
    this.customStartDate,
    this.customEndDate,
    this.sortBy = 'newest',
    this.filterCategory = 'All',
    this.filterType = 'all',
    this.limit = 20,
    this.hasMore = false,
  });

  TransactionListState copyWith({
    List<Transaction>? transactions,
    List<Transaction>? allTransactions,
    bool? isLoading,
    String? searchQuery,
    String? dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? sortBy,
    String? filterCategory,
    String? filterType,
    int? limit,
    bool? hasMore,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      allTransactions: allTransactions ?? this.allTransactions,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      sortBy: sortBy ?? this.sortBy,
      filterCategory: filterCategory ?? this.filterCategory,
      filterType: filterType ?? this.filterType,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class TransactionController extends StateNotifier<TransactionListState> {
  final Ref _ref;

  TransactionController(this._ref) : super(TransactionListState()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);
    try {
      final db = _ref.read(databaseServiceProvider);
      
      // Load all transactions for global balances and stats calculation
      final allTxs = await db.getExpenses();

      // Load filtered transactions for the main list
      final txs = await db.getExpenses(
        searchQuery: state.searchQuery,
        filterCategory: state.filterCategory == 'All' ? null : state.filterCategory,
        filterType: state.filterType,
        dateFilter: state.dateFilter,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        sortBy: state.sortBy,
      );
      
      final paginatedTxs = txs.take(state.limit).toList();
      final hasMore = txs.length > state.limit;

      state = state.copyWith(
        transactions: paginatedTxs,
        allTransactions: allTxs,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void loadMore() {
    state = state.copyWith(limit: state.limit + 20);
    loadTransactions();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, limit: 20);
    loadTransactions();
  }

  void setDateFilter(String filter, {DateTime? start, DateTime? end}) {
    state = state.copyWith(
      dateFilter: filter,
      customStartDate: start,
      customEndDate: end,
      limit: 20,
    );
    loadTransactions();
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy, limit: 20);
    loadTransactions();
  }

  void setFilterCategory(String category) {
    state = state.copyWith(filterCategory: category, limit: 20);
    loadTransactions();
  }

  void setFilterType(String type) {
    state = state.copyWith(filterType: type, limit: 20);
    loadTransactions();
  }

  Future<void> addTransaction({
    required double amount,
    required String type, // 'deposit' or 'expense'
    required String category,
    required String description,
    int walletId = 1,
    String paymentMethod = 'Cash',
    String notes = '',
    String location = '',
    String receiptImagePath = '',
  }) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setLastUsedCategory(category);

    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    
    int hour = now.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final timeStr = "${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm";

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayOfWeek = days[now.weekday - 1];

    final transaction = Transaction()
      ..amount = amount
      ..type = type
      ..category = category
      ..description = description
      ..date = dateStr
      ..time = timeStr
      ..walletId = walletId
      ..paymentMethod = paymentMethod
      ..notes = notes
      ..location = location
      ..receiptImagePath = receiptImagePath
      ..day = now.day
      ..month = now.month
      ..year = now.year
      ..dayOfWeek = dayOfWeek
      ..uuid = DateTime.now().microsecondsSinceEpoch.toString()
      ..createdAt = now
      ..updatedAt = now;

    final db = _ref.read(databaseServiceProvider);
    await db.saveExpense(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction({
    required int id,
    required double amount,
    required String type,
    required String category,
    required String description,
    int walletId = 1,
    String paymentMethod = 'Cash',
    String notes = '',
    String location = '',
    String receiptImagePath = '',
  }) async {
    final db = _ref.read(databaseServiceProvider);
    final existing = await db.getExpense(id);
    if (existing == null) return;

    existing.amount = amount;
    existing.type = type;
    existing.category = category;
    existing.description = description;
    existing.walletId = walletId;
    existing.paymentMethod = paymentMethod;
    existing.notes = notes;
    existing.location = location;
    existing.receiptImagePath = receiptImagePath;
    existing.updatedAt = DateTime.now();

    await db.saveExpense(existing);
    await loadTransactions();
  }

  Future<void> deleteExpense(int id) async {
    final db = _ref.read(databaseServiceProvider);
    await db.deleteExpense(id);
    await loadTransactions();
  }

  Future<void> wipeAllData() async {
    final db = _ref.read(databaseServiceProvider);
    await db.clearAllData();
    await loadTransactions();
  }

  Future<void> importBackup(List<Transaction> transactions) async {
    final db = _ref.read(databaseServiceProvider);
    await db.importExpenses(transactions);
    await loadTransactions();
  }
}

// Retain variables to avoid breaking bindings
final expenseControllerProvider = StateNotifierProvider<TransactionController, TransactionListState>((ref) {
  return TransactionController(ref);
});

final expenseProvider = FutureProvider.family<Transaction?, int>((ref, id) async {
  final db = ref.read(databaseServiceProvider);
  return db.getExpense(id);
});
