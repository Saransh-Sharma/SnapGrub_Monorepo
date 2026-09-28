import 'package:drift/drift.dart';

class DailyThreadsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get day => dateTime()();
  TextColumn get timezone => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {userId, day},
      ];
}
