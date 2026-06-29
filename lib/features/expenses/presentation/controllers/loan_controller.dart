import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/features/expenses/domain/models/loan.dart';
import 'package:personal_wallet/features/expenses/domain/models/transaction.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';

class LoanState {
  final List<Loan> loans;
  final bool isLoading;

  LoanState({
    this.loans = const [],
    this.isLoading = false,
  });

  LoanState copyWith({
    List<Loan>? loans,
    bool? isLoading,
  }) {
    return LoanState(
      loans: loans ?? this.loans,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LoanController extends StateNotifier<LoanState> {
  final Ref _ref;

  LoanController(this._ref) : super(LoanState()) {
    loadLoans();
  }

  Future<void> loadLoans() async {
    state = state.copyWith(isLoading: true);
    final db = _ref.read(databaseServiceProvider);
    final list = await db.getLoans();
    state = LoanState(loans: list, isLoading: false);
  }

  Future<void> addLoan({
    required String personName,
    required double amount,
    required String type, // 'lent' or 'borrowed'
    required int walletId,
    required DateTime dueDate,
    required String notes,
  }) async {
    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    final loan = Loan()
      ..personName = personName
      ..totalAmount = amount
      ..paidAmount = 0.0
      ..type = type
      ..walletId = walletId
      ..date = dateStr
      ..dueDate = dueDate
      ..notes = notes
      ..status = 'open'
      ..createdAt = now
      ..updatedAt = now;

    final db = _ref.read(databaseServiceProvider);
    await db.saveLoan(loan);

    // Create an associated ledger transaction so it immediately affects wallet balance!
    // If we lend money -> it is an expense (-) from our wallet.
    // If we borrow money -> it is a deposit (+) to our wallet.
    final txType = type == 'lent' ? 'expense' : 'deposit';
    final category = type == 'lent' ? 'Other' : 'Salary';
    final desc = type == 'lent' ? 'Lent to / سلّفت: $personName' : 'Borrowed from / استلفّت من: $personName';

    int hour = now.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final timeStr = "${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm";

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayOfWeek = days[now.weekday - 1];

    final transaction = Transaction()
      ..amount = amount
      ..type = txType
      ..category = category
      ..description = desc
      ..date = dateStr
      ..time = timeStr
      ..walletId = walletId
      ..toWalletId = 0
      ..loanId = 0 // represents initial loan creation transaction
      ..paymentMethod = 'Cash'
      ..notes = notes
      ..location = ''
      ..receiptImagePath = ''
      ..day = now.day
      ..month = now.month
      ..year = now.year
      ..dayOfWeek = dayOfWeek
      ..uuid = DateTime.now().microsecondsSinceEpoch.toString()
      ..createdAt = now
      ..updatedAt = now;

    await db.saveExpense(transaction);
    await _ref.read(expenseControllerProvider.notifier).loadTransactions();
    await loadLoans();
  }

  Future<void> registerRepayment({
    required int loanId,
    required double amount,
    required int walletId,
    required String paymentMethod,
  }) async {
    final db = _ref.read(databaseServiceProvider);
    final loan = await db.getLoan(loanId);
    if (loan == null) return;

    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    // Update loan details
    loan.paidAmount += amount;
    if (loan.paidAmount >= loan.totalAmount) {
      loan.status = 'paid';
    } else {
      loan.status = 'partial';
    }
    loan.updatedAt = now;
    await db.saveLoan(loan);

    // Create dynamic associated repayment transaction in ledger!
    // Repayment of money we lent -> acts like a Deposit (+) to our selected wallet.
    // Repayment of money we borrowed -> acts like an Expense (-) from our selected wallet.
    final txType = loan.type == 'lent' ? 'deposit' : 'expense';
    final category = loan.type == 'lent' ? 'Other' : 'Other';
    final desc = loan.type == 'lent'
        ? 'Repayment from / سداد من: ${loan.personName}'
        : 'Repaid to / سددت لـ: ${loan.personName}';

    int hour = now.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final timeStr = "${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm";

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayOfWeek = days[now.weekday - 1];

    final transaction = Transaction()
      ..amount = amount
      ..type = txType
      ..category = category
      ..description = desc
      ..date = dateStr
      ..time = timeStr
      ..walletId = walletId
      ..toWalletId = 0
      ..loanId = loanId // link back to loan parent!
      ..paymentMethod = paymentMethod
      ..notes = 'Repayment payment / دفعة سداد'
      ..location = ''
      ..receiptImagePath = ''
      ..day = now.day
      ..month = now.month
      ..year = now.year
      ..dayOfWeek = dayOfWeek
      ..uuid = DateTime.now().microsecondsSinceEpoch.toString()
      ..createdAt = now
      ..updatedAt = now;

    await db.saveExpense(transaction);
    await _ref.read(expenseControllerProvider.notifier).loadTransactions();
    await loadLoans();
  }

  Future<void> deleteLoan(int id) async {
    final db = _ref.read(databaseServiceProvider);
    await db.deleteLoan(id);
    await loadLoans();
  }
}

final loanControllerProvider = StateNotifierProvider<LoanController, LoanState>((ref) {
  return LoanController(ref);
});

// Dynamic financial contacts profiling provider
class ContactProfile {
  final String name;
  final double netBalance; // positive = people owe me (+), negative = I owe them (-)
  final int activeLoansCount;
  final String lastActiveDate;

  ContactProfile({
    required this.name,
    required this.netBalance,
    required this.activeLoansCount,
    required this.lastActiveDate,
  });
}

final contactProfilesProvider = Provider<List<ContactProfile>>((ref) {
  final loanState = ref.watch(loanControllerProvider);
  final Map<String, List<Loan>> grouped = {};
  
  for (var loan in loanState.loans) {
    grouped.putIfAbsent(loan.personName, () => []).add(loan);
  }

  final List<ContactProfile> profiles = [];
  
  grouped.forEach((name, loans) {
    double net = 0.0;
    int activeCount = 0;
    DateTime? lastActive;

    for (var l in loans) {
      final remaining = l.totalAmount - l.paidAmount;
      if (l.type == 'lent') {
        net += remaining;
      } else {
        net -= remaining;
      }

      if (l.status != 'paid') {
        activeCount++;
      }

      if (lastActive == null || l.updatedAt.isAfter(lastActive)) {
        lastActive = l.updatedAt;
      }
    }

    final dateStr = lastActive != null 
        ? "${lastActive.day}/${lastActive.month}/${lastActive.year}"
        : 'N/A';

    profiles.add(ContactProfile(
      name: name,
      netBalance: net,
      activeLoansCount: activeCount,
      lastActiveDate: dateStr,
    ));
  });

  return profiles;
});
