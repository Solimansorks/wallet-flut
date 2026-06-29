import 'package:isar/isar.dart';

part 'wallet.g.dart';

@collection
class Wallet {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, type: IndexType.hash)
  late String name;

  late int iconCode;
  late int colorValue;
  late double initialBalance;
}
