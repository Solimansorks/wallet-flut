import 'package:isar/isar.dart';

part 'savings_goal.g.dart';

@collection
class SavingsGoal {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, type: IndexType.hash)
  late String title;

  late double targetAmount;
  late double savedAmount;
}
