import 'package:drift/drift.dart';

class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get cursor => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
