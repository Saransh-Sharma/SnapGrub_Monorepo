import 'package:drift/drift.dart';

class WeeklyInsightsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get weekStart => dateTime()();
  TextColumn get insightType => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  TextColumn get status => text().withDefault(const Constant('ready'))();
  DateTimeColumn get generatedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
