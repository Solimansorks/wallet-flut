import 'package:isar/isar.dart';

part 'loan.g.dart';

@collection
class Loan {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.hash)
  late String personName;

  late double totalAmount;
  late double paidAmount;

  @Index(type: IndexType.hash)
  late String type; // 'lent' (Money Lent) or 'borrowed' (Money Borrowed)

  @Index()
  late int walletId; // Initial source or destination account ID

  late String date; // dd/MM/yyyy
  late DateTime dueDate;
  late String notes;
  late String status; // 'open', 'partial', 'paid'
  late DateTime createdAt;
  late DateTime updatedAt;
}
