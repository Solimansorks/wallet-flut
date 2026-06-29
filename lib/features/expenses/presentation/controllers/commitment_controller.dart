import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/features/expenses/domain/models/commitment.dart';
import 'package:personal_wallet/features/expenses/domain/models/transaction.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:intl/intl.dart';

class CommitmentState {
  final List<Commitment> commitments;
  final bool isLoading;

  CommitmentState({
    this.commitments = const [],
    this.isLoading = false,
  });

  CommitmentState copyWith({
    List<Commitment>? commitments,
    bool? isLoading,
  }) {
    return CommitmentState(
      commitments: commitments ?? this.commitments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CommitmentController extends StateNotifier<CommitmentState> {
  final Ref _ref;

  CommitmentController(this._ref) : super(CommitmentState()) {
    loadCommitments();
  }

  Future<void> loadCommitments() async {
    state = state.copyWith(isLoading: true);
    final db = _ref.read(databaseServiceProvider);
    final list = await db.getCommitments();
    state = state.copyWith(commitments: list, isLoading: false);
  }

  Future<void> addCommitment({
    required String name,
    required double amount,
    required int dueDate,
    required String category,
    required int walletId,
  }) async {
    final commitment = Commitment()
      ..name = name
      ..amount = amount
      ..dueDate = dueDate
      ..category = category
      ..walletId = walletId
      ..isPaid = false
      ..lastPaidDate = null;

    final db = _ref.read(databaseServiceProvider);
    await db.saveCommitment(commitment);
    await loadCommitments();
  }

  Future<void> deleteCommitment(int id) async {
    final db = _ref.read(databaseServiceProvider);
    await db.deleteCommitment(id);
    await loadCommitments();
  }

  Future<void> togglePaid(Commitment commitment, bool paid) async {
    final db = _ref.read(databaseServiceProvider);
    commitment.isPaid = paid;
    
    if (paid) {
      commitment.lastPaidDate = DateTime.now();
      
      // Auto-generate transaction to deduct from wallet!
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy').format(now);
      final timeStr = DateFormat('HH:mm').format(now);
      final dayOfWeek = DateFormat('EEEE').format(now);
      
      final transaction = Transaction()
        ..amount = commitment.amount
        ..type = 'expense'
        ..category = commitment.category
        ..description = 'التزام: ${commitment.name}'
        ..date = dateStr
        ..time = timeStr
        ..walletId = commitment.walletId
        ..paymentMethod = 'Cash'
        ..location = ''
        ..notes = 'تم توليده تلقائياً من الالتزامات الشهرية'
        ..receiptImagePath = ''
        ..toWalletId = 0
        ..loanId = 0
        ..day = now.day
        ..month = now.month
        ..year = now.year
        ..dayOfWeek = dayOfWeek
        ..uuid = 'commitment_${commitment.id}_${now.year}_${now.month}'
        ..createdAt = now
        ..updatedAt = now;

      await db.saveExpense(transaction);
      // Reload transactions to trigger balance updates
      await _ref.read(expenseControllerProvider.notifier).loadTransactions();
    } else {
      // If toggled off, find the generated transaction and delete it
      final allTxs = _ref.read(expenseControllerProvider).allTransactions;
      final now = DateTime.now();
      final targetUuid = 'commitment_${commitment.id}_${now.year}_${now.month}';
      final matchingTx = allTxs.where((t) => t.uuid == targetUuid);
      if (matchingTx.isNotEmpty) {
        await db.deleteExpense(matchingTx.first.id);
        await _ref.read(expenseControllerProvider.notifier).loadTransactions();
      }
      commitment.lastPaidDate = null;
    }

    await db.saveCommitment(commitment);
    await loadCommitments();
  }
}

final commitmentControllerProvider = StateNotifierProvider<CommitmentController, CommitmentState>((ref) {
  return CommitmentController(ref);
});
