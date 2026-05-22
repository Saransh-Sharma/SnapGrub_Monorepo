import 'package:drift/drift.dart';

class ProfilesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get locale => text().withDefault(const Constant('en-US'))();
  TextColumn get timezone => text()();
  TextColumn get unitSystem => text().withDefault(const Constant('metric'))();
  TextColumn get countryCode => text().nullable()();
  TextColumn get cuisinePreferencesJson =>
      text().withDefault(const Constant('[]'))();
  BoolColumn get cloudMediaStorage =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get saveOriginalPhotos =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get aiImprovementConsent =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get onboardingCompletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
