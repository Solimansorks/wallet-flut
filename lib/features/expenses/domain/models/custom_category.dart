import 'package:isar/isar.dart';

part 'custom_category.g.dart';

@collection
class CustomCategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, type: IndexType.hash)
  late String name;

  late String type; // 'deposit' or 'expense'
}
