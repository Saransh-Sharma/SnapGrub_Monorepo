import 'package:drift/drift.dart';

class DailyRollupsLocal extends Table {
  TextColumn get userId => text()();
  DateTimeColumn get day => dateTime()();
  RealColumn get caloriesKcal => real().withDefault(const Constant(0))();
  RealColumn get proteinG => real().withDefault(const Constant(0))();
  RealColumn get carbsG => real().withDefault(const Constant(0))();
  RealColumn get fatG => real().withDefault(const Constant(0))();
  IntColumn get mealCount => integer().withDefault(const Constant(0))();
  BoolColumn get hasPhotoMeal => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {userId, day};
}
