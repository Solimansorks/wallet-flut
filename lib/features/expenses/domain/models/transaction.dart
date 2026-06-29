import 'package:isar/isar.dart';

part 'transaction.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  @Index()
  late double amount;

  @Index(type: IndexType.hash)
  late String type; // 'deposit', 'expense', 'transfer', 'loan_repayment'

  @Index(type: IndexType.hash)
  late String category;

  late String description;

  @Index(type: IndexType.hash)
  late String date; // dd/MM/yyyy

  late String time; // hh:mm a

  late DateTime createdAt;

  late DateTime updatedAt;

  @Index(type: IndexType.hash)
  late String paymentMethod; // Cash, Visa, Bank, Instapay, Vodafone Cash, E-Wallet

  late String notes;

  late String location;

  @Index(type: IndexType.hash)
  late String uuid;

  late String receiptImagePath;

  @Index()
  late int walletId; // Source wallet id

  // Advanced Ledger Fields
  @Index()
  int toWalletId = 0; // Destination wallet id (for transfers)

  @Index()
  int loanId = 0; // Linked loan ID (for loan repayments)

  late int day;
  late int month;
  late int year;
  late String dayOfWeek;
}
