import 'package:drift/drift.dart';

class UserFoodDefaultsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get foodRefKind => text()();
  TextColumn get foodRefId => text()();
  TextColumn get foodName => text()();
  RealColumn get preferredQuantity => real().withDefault(const Constant(1))();
  TextColumn get preferredUnit => text()();
  RealColumn get preferredGrams => real().nullable()();
  RealColumn get caloriesKcal => real().withDefault(const Constant(0))();
  RealColumn get proteinG => real().withDefault(const Constant(0))();
  RealColumn get carbsG => real().withDefault(const Constant(0))();
  RealColumn get fatG => real().withDefault(const Constant(0))();
  IntColumn get useCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
