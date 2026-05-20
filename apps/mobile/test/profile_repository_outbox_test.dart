import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/repositories/profile_repository.dart';
import 'package:snapgrub/data/services/device_identity_service.dart';
import 'package:snapgrub/data/services/profile_remote_service.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';

void main() {
  test('offline onboarding creates one pending settings.patch command', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final repository = ProfileRepository(
      db: db,
      remote: const ProfileRemoteService(null),
      outbox: OutboxRepository(db),
      deviceIdentity: const DeviceIdentityService(),
    );

    await repository.saveOnboarding('user-a', validDraft());

    final commands = await db.select(db.outboxCommands).get();
    expect(commands, hasLength(1));
    expect(commands.single.userId, 'user-a');
    expect(commands.single.commandType, 'settings.patch');
    expect(commands.single.status, 'pending');
  });

  test('validation error does not enqueue settings.patch command', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final repository = ProfileRepository(
      db: db,
      remote: const ProfileRemoteService(null),
      outbox: OutboxRepository(db),
      deviceIdentity: const DeviceIdentityService(),
    );

    final invalid = validDraft().copyWith(caloriesKcal: 100);

    expect(
      () => repository.saveOnboarding('user-a', invalid),
      throwsArgumentError,
    );
    expect(await db.select(db.outboxCommands).get(), isEmpty);
  });

  test('outbox drain marks command synced and applies server goal', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final outbox = OutboxRepository(db);
    final offlineRepository = ProfileRepository(
      db: db,
      remote: const ProfileRemoteService(null),
      outbox: outbox,
      deviceIdentity: const DeviceIdentityService(),
    );
    await offlineRepository.saveOnboarding('user-a', validDraft());

    final onlineRepository = ProfileRepository(
      db: db,
      remote: FakeProfileRemoteService(),
      outbox: outbox,
      deviceIdentity: const DeviceIdentityService(),
    );
    await onlineRepository.drainSettingsPatchOutbox('user-a');

    final commands = await db.select(db.outboxCommands).get();
    expect(commands.single.status, 'synced');

    final state = await onlineRepository.loadLocal('user-a');
    expect(state.activeGoal?.id, 'server-goal');
  });
}

OnboardingDraft validDraft() {
  return OnboardingDraft(
    displayName: 'A',
    goalType: 'lose',
    unitSystem: 'metric',
    locale: 'en-IN',
    timezone: 'Asia/Kolkata',
    countryCode: 'IN',
    caloriesKcal: 1900,
    proteinG: 130,
    carbsG: 190,
    fatG: 60,
  );
}

class FakeProfileRemoteService extends ProfileRemoteService {
  FakeProfileRemoteService() : super(null);

  @override
  bool get isConfigured => true;

  @override
  Future<SettingsPatchResponseDto> patchSettings({
    required String clientRequestId,
    required SettingsPatchRequestDto request,
  }) async {
    final now = DateTime.utc(2026, 5, 20);
    return SettingsPatchResponseDto(
      profile: ProfileDto(
        id: 'user-a',
        displayName: 'A',
        locale: 'en-IN',
        timezone: 'Asia/Kolkata',
        unitSystem: UnitSystem.metric,
        cuisinePreferences: const [],
        cloudMediaStorage: true,
        saveOriginalPhotos: false,
        aiImprovementConsent: false,
        onboardingCompletedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      activeGoal: NutritionGoalDto(
        id: 'server-goal',
        userId: 'user-a',
        goalType: GoalType.lose,
        caloriesKcal: 1900,
        proteinG: 130,
        carbsG: 190,
        fatG: 60,
        startsOn: now,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      serverTime: now,
      requestId: 'request-id',
    );
  }
}
