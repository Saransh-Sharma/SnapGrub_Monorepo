import 'package:drift/drift.dart';

class DevicesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get installId => text()();
  TextColumn get platform => text()();
  TextColumn get appVersion => text().nullable()();
  TextColumn get buildNumber => text().nullable()();
  DateTimeColumn get lastSeenAt => dateTime()();
  TextColumn get lastSyncCursor => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
