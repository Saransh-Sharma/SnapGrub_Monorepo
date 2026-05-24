import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/services/supabase_function_client.dart';
import 'package:snapgrub/features/meal_editor/data/meal_remote_service.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';

void main() {
  test('meal save and delete enqueue durable outbox commands', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final repository = MealRepository(
      db: db,
      remote: const MealRemoteService(SnapGrubFunctionClient(null)),
      outbox: OutboxRepository(db),
    );

    final meal = await repository.saveDraft(
      MealDraft(
        userId: 'user-a',
        timezone: 'Asia/Kolkata',
        title: 'Dal chawal',
        items: [
          MealDraftItem(
            name: 'Dal',
            quantity: 1,
            unit: 'bowl',
            caloriesKcal: 220,
            proteinG: 12,
            carbsG: 30,
            fatG: 6,
          ),
        ],
      ),
    );

    var commands = await db.select(db.outboxCommands).get();
    expect(commands, hasLength(1));
    expect(commands.single.commandType, 'meal.create');

    final rollup = await db.select(db.dailyRollupsLocal).getSingle();
    expect(rollup.caloriesKcal, 220);
    expect(rollup.mealCount, 1);

    await repository.deleteMeal(meal);
    commands = await db.select(db.outboxCommands).get();
    expect(commands.map((command) => command.commandType),
        containsAll(['meal.create', 'meal.delete']));

    final deletedMeal = await repository.getMeal(meal.id);
    expect(deletedMeal?.syncStatus, MealSyncStatus.pending);
  });
}
