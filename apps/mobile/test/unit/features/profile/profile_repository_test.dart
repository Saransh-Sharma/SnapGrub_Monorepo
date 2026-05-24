import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/repositories/profile_repository.dart';
import 'package:snapgrub/data/services/device_identity_service.dart';
import 'package:snapgrub/data/services/profile_remote_service.dart';
import 'package:snapgrub/data/services/supabase_function_client.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';

void main() {
  test('local profile and goal reads are scoped to the signed-in user',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.profilesLocal).insert(
          ProfilesLocalCompanion.insert(
            id: 'user-a',
            timezone: 'UTC',
            displayName: const Value('A'),
          ),
        );
    await db.into(db.profilesLocal).insert(
          ProfilesLocalCompanion.insert(
            id: 'user-b',
            timezone: 'UTC',
            displayName: const Value('B'),
          ),
        );
    await db.into(db.nutritionGoalsLocal).insert(
          NutritionGoalsLocalCompanion.insert(
            id: 'goal-a',
            userId: 'user-a',
            goalType: 'lose',
            caloriesKcal: 1900,
            proteinG: 130,
            carbsG: 190,
            fatG: 60,
            startsOn: DateTime.utc(2026, 5, 20),
          ),
        );
    await db.into(db.nutritionGoalsLocal).insert(
          NutritionGoalsLocalCompanion.insert(
            id: 'goal-b',
            userId: 'user-b',
            goalType: 'gain',
            caloriesKcal: 2600,
            proteinG: 150,
            carbsG: 280,
            fatG: 80,
            startsOn: DateTime.utc(2026, 5, 20),
          ),
        );

    final repository = ProfileRepository(
      db: db,
      remote: const ProfileRemoteService(SnapGrubFunctionClient(null)),
      outbox: OutboxRepository(db),
      deviceIdentity: const DeviceIdentityService(),
    );

    final state = await repository.loadLocal('user-b');

    expect(state.profile?.displayName, 'B');
    expect(state.activeGoal?.goalType, 'gain');
  });
}
