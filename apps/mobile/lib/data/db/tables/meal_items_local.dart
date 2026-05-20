import 'package:drift/drift.dart';

class MealItemsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get mealId => text()();
  TextColumn get userId => text()();
  TextColumn get clientId => text()();
  IntColumn get position => integer()();
  TextColumn get name => text()();
  TextColumn get foodRefKind => text().withDefault(const Constant('manual'))();
  TextColumn get canonicalFoodId => text().nullable()();
  TextColumn get brandedProductId => text().nullable()();
  TextColumn get customFoodId => text().nullable()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  RealColumn get gramsEstimated => real().nullable()();
  RealColumn get caloriesKcal => real().withDefault(const Constant(0))();
  RealColumn get proteinG => real().withDefault(const Constant(0))();
  RealColumn get carbsG => real().withDefault(const Constant(0))();
  RealColumn get fatG => real().withDefault(const Constant(0))();
  RealColumn get confidence => real().nullable()();
  TextColumn get sourceType => text().nullable()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
