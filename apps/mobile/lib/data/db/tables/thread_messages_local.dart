import 'package:drift/drift.dart';

class ThreadMessagesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get threadId => text()();
  TextColumn get userId => text()();
  TextColumn get clientId => text()();
  TextColumn get role => text()();
  TextColumn get kind => text().withDefault(const Constant('text'))();
  TextColumn get textContent => text().nullable()();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  IntColumn get sequence => integer()();
  TextColumn get deliveryState =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {userId, clientId},
      ];
}
