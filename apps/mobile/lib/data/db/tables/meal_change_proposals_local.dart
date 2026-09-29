import 'package:drift/drift.dart';

class MealChangeProposalsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get threadId => text()();
  TextColumn get userId => text()();
  TextColumn get messageId => text().nullable()();
  TextColumn get operation => text()();
  TextColumn get targetMealId => text().nullable()();
  IntColumn get expectedRevision => integer().nullable()();
  TextColumn get draftJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
