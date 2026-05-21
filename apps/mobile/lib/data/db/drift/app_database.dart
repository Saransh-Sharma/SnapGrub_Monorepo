import 'package:drift/drift.dart';
import 'package:snapgrub/data/db/drift/connection.dart';
import 'package:snapgrub/data/db/tables/body_measurements_local.dart';
import 'package:snapgrub/data/db/tables/correction_events_local.dart';
import 'package:snapgrub/data/db/tables/custom_foods_local.dart';
import 'package:snapgrub/data/db/tables/daily_rollups_local.dart';
import 'package:snapgrub/data/db/tables/devices_local.dart';
import 'package:snapgrub/data/db/tables/feature_flags_local.dart';
import 'package:snapgrub/data/db/tables/meal_assets_local.dart';
import 'package:snapgrub/data/db/tables/meal_items_local.dart';
import 'package:snapgrub/data/db/tables/meal_templates_local.dart';
import 'package:snapgrub/data/db/tables/meals_local.dart';
import 'package:snapgrub/data/db/tables/nutrition_goals_local.dart';
import 'package:snapgrub/data/db/tables/outbox_commands.dart';
import 'package:snapgrub/data/db/tables/profiles_local.dart';
import 'package:snapgrub/data/db/tables/sync_state.dart';
import 'package:snapgrub/data/db/tables/user_food_defaults_local.dart';
import 'package:snapgrub/data/db/tables/weekly_insights_local.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ProfilesLocal,
    NutritionGoalsLocal,
    BodyMeasurementsLocal,
    DevicesLocal,
    FeatureFlagsLocal,
    SyncState,
    OutboxCommands,
    MealAssetsLocal,
    MealsLocal,
    MealItemsLocal,
    MealTemplatesLocal,
    CustomFoodsLocal,
    DailyRollupsLocal,
    CorrectionEventsLocal,
    WeeklyInsightsLocal,
    UserFoodDefaultsLocal,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(mealsLocal);
            await m.createTable(mealItemsLocal);
            await m.createTable(mealTemplatesLocal);
            await m.createTable(customFoodsLocal);
            await m.createTable(dailyRollupsLocal);
            await m.createTable(correctionEventsLocal);
          }
          if (from < 3) {
            await m.createTable(mealAssetsLocal);
          }
          if (from < 4) {
            await m.addColumn(outboxCommands, outboxCommands.payloadHash);
            await m.addColumn(
                outboxCommands, outboxCommands.dependencyCommandId);
            await m.addColumn(outboxCommands, outboxCommands.lastError);
          }
          if (from < 5) {
            await m.createTable(weeklyInsightsLocal);
            await m.createTable(userFoodDefaultsLocal);
          }
        },
      );
}
