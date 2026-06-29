import 'package:isar/isar.dart';

part 'commitment.g.dart';

@collection
class Commitment {
  Id id = Isar.autoIncrement;
  late String name;
  late double amount;
  late int dueDate; // Day of the month (1-31)
  late String category;
  late int walletId;
  late bool isPaid;
  late DateTime? lastPaidDate;
}
