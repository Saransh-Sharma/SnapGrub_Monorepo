import 'package:drift/drift.dart';

class CustomFoodsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get clientId => text()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  RealColumn get servingQuantity => real().nullable()();
  TextColumn get servingUnit => text().nullable()();
  RealColumn get servingGrams => real().nullable()();
  RealColumn get caloriesKcal => real().withDefault(const Constant(0))();
  RealColumn get proteinG => real().withDefault(const Constant(0))();
  RealColumn get carbsG => real().withDefault(const Constant(0))();
  RealColumn get fatG => real().withDefault(const Constant(0))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
