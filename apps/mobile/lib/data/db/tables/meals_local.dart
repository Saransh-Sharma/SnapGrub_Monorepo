import 'package:drift/drift.dart';

class MealsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get clientId => text()();
  TextColumn get analysisJobId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get mealType => text()();
  TextColumn get source => text()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get timezone => text()();
  RealColumn get caloriesKcal => real().withDefault(const Constant(0))();
  RealColumn get proteinG => real().withDefault(const Constant(0))();
  RealColumn get carbsG => real().withDefault(const Constant(0))();
  RealColumn get fatG => real().withDefault(const Constant(0))();
  RealColumn get confidenceOverall => real().nullable()();
  TextColumn get provenanceType => text().nullable()();
  TextColumn get photoAssetId => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
