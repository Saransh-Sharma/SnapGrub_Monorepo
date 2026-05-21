import 'package:drift/drift.dart';

class MealTemplatesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get clientId => text()();
  TextColumn get title => text()();
  TextColumn get snapshotJson => text()();
  TextColumn get sourceMealId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
