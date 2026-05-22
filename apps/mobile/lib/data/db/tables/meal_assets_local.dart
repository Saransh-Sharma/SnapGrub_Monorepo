import 'package:drift/drift.dart';

class MealAssetsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get localPath => text()();
  TextColumn get storageBucket =>
      text().withDefault(const Constant('meal-originals-private'))();
  TextColumn get storagePath => text()();
  TextColumn get thumbLocalPath => text().nullable()();
  TextColumn get thumbStoragePath => text().nullable()();
  TextColumn get sha256 => text()();
  TextColumn get mimeType => text().withDefault(const Constant('image/jpeg'))();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get uploadStatus =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get uploadedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
