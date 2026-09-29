import 'package:drift/drift.dart';

class MealVisualsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get mealId => text()();
  TextColumn get userId => text()();
  TextColumn get promptSignature => text()();
  TextColumn get styleVersion =>
      text().withDefault(const Constant('studio-v1'))();
  TextColumn get status => text().withDefault(const Constant('queued'))();
  TextColumn get localPath => text().nullable()();
  TextColumn get remotePath => text().nullable()();
  TextColumn get thumbRemotePath => text().nullable()();
  TextColumn get dominantColor => text().nullable()();
  TextColumn get provider => text().nullable()();
  TextColumn get modelName => text().nullable()();
  TextColumn get errorCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {mealId, promptSignature},
      ];
}
