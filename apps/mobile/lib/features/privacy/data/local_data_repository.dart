import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';

final localDataRepositoryProvider = Provider<LocalDataRepository>((ref) {
  return LocalDataRepository(ref.watch(appDatabaseProvider));
});

class LocalDataRepository {
  const LocalDataRepository(this._db);

  final AppDatabase _db;

  Future<void> clearAll() async {
    await _db.transaction(() async {
      for (final table in _tablesInDeleteOrder) {
        await _db.customStatement('delete from $table');
      }
    });
  }
}

const _tablesInDeleteOrder = [
  'meal_items_local',
  'correction_events_local',
  'meal_assets_local',
  'meals_local',
  'meal_templates_local',
  'custom_foods_local',
  'daily_rollups_local',
  'body_measurements_local',
  'nutrition_goals_local',
  'devices_local',
  'feature_flags_local',
  'weekly_insights_local',
  'user_food_defaults_local',
  'sync_state',
  'outbox_commands',
  'profiles_local',
];
