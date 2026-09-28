import 'package:drift/drift.dart';

class AgentRunsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get threadId => text()();
  TextColumn get userId => text()();
  TextColumn get clientRequestId => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get cursor => integer().withDefault(const Constant(0))();
  TextColumn get provider => text().nullable()();
  TextColumn get modelName => text().nullable()();
  TextColumn get errorCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {userId, clientRequestId},
      ];
}
