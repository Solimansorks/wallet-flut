import 'package:isar/isar.dart';

part 'budget.g.dart';

@collection
class Budget {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, type: IndexType.hash)
  late String category;

  late double limitAmount;
}
