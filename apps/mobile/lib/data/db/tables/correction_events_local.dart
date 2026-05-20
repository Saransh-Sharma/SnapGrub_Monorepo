import 'package:drift/drift.dart';

class CorrectionEventsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get mealId => text().nullable()();
  TextColumn get analysisJobId => text().nullable()();
  TextColumn get eventType => text()();
  TextColumn get fieldName => text().nullable()();
  TextColumn get beforeValueJson => text().nullable()();
  TextColumn get afterValueJson => text().nullable()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
