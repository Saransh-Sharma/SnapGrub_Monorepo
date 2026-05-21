import 'package:drift/drift.dart';

class OutboxCommands extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get commandType => text()();
  TextColumn get payloadJson => text()();
  TextColumn get payloadHash => text().nullable()();
  TextColumn get clientRequestId => text()();
  TextColumn get dependencyCommandId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
