import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/data/mappers/profile_mappers.dart';
import 'package:snapgrub/data/services/device_identity_service.dart';
import 'package:snapgrub/data/services/profile_remote_service.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/profile/domain/nutrition_goal.dart';
import 'package:snapgrub/features/profile/domain/profile.dart';
import 'package:snapgrub/features/profile/domain/profile_state.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';
import 'package:uuid/uuid.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    db: ref.watch(appDatabaseProvider),
    remote: ref.watch(profileRemoteServiceProvider),
    outbox: ref.watch(outboxRepositoryProvider),
    deviceIdentity: ref.watch(deviceIdentityServiceProvider),
  );
});

class ProfileRepository {
  ProfileRepository({
    required AppDatabase db,
    required ProfileRemoteService remote,
    required OutboxRepository outbox,
    required DeviceIdentityService deviceIdentity,
  })  : _db = db,
        _remote = remote,
        _outbox = outbox,
        _deviceIdentity = deviceIdentity;

  final AppDatabase _db;
  final ProfileRemoteService _remote;
  final OutboxRepository _outbox;
  final DeviceIdentityService _deviceIdentity;

  Future<ProfileState> loadLocal(String userId) async {
    final profileRow = await (_db.select(_db.profilesLocal)..where((tbl) => tbl.id.equals(userId))).getSingleOrNull();
    final goalRow = await (_db.select(_db.nutritionGoalsLocal)
          ..where((tbl) => tbl.userId.equals(userId) & tbl.isActive.equals(true)))
        .getSingleOrNull();
    final flags = await _db.select(_db.featureFlagsLocal).get();

    return ProfileState(
      profile: profileRow == null ? null : _profileFromRow(profileRow),
      activeGoal: goalRow == null ? null : _goalFromRow(goalRow),
      featureFlags: {
        for (final flag in flags) flag.key: jsonDecode(flag.valueJson),
      },
      syncStatus: ProfileSyncStatus.idle,
    );
  }

  Future<ProfileState> bootstrap(String userId) async {
    final local = await loadLocal(userId);
    if (!_remote.isConfigured) return local;

    final installId = await _deviceIdentity.installId();
    final response = await _remote.bootstrap(
      request: ProfileBootstrapRequestDto(
        installId: installId,
        platform: Platform.isIOS ? 'ios' : 'android',
        appVersion: '0.1.0',
        buildNumber: '1',
        locale: local.profile?.locale ?? 'en-IN',
        timezone: local.profile?.timezone ?? 'Asia/Kolkata',
      ),
    );
    await cacheBootstrap(response);
    await drainSettingsPatchOutbox(userId);
    return loadLocal(userId);
  }

  Future<void> saveOnboarding(String userId, OnboardingDraft draft) async {
    draft.validate();
    final clientRequestId = const Uuid().v4();
    await _saveDraftLocally(userId, draft, ProfileSyncStatus.pending.name);

    try {
      final response = await _remote.patchSettings(
        clientRequestId: clientRequestId,
        request: _settingsRequestFromDraft(clientRequestId, draft),
      );
      await cacheSettings(response);
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      await _outbox.enqueue(
        userId: userId,
        commandType: 'settings.patch',
        clientRequestId: clientRequestId,
        payload: _settingsRequestFromDraft(clientRequestId, draft).toJson(),
      );
    }
  }

  Future<void> drainSettingsPatchOutbox(String userId) async {
    if (!_remote.isConfigured) return;
    final pending = await _outbox.pendingSettingsPatchCommands(userId);
    for (final command in pending) {
      try {
        final payload = Map<String, dynamic>.from(jsonDecode(command.payloadJson) as Map);
        final request = SettingsPatchRequestDto(
          clientRequestId: command.clientRequestId,
          profilePatch: _nullableMap(payload['profile_patch']),
          activeGoalPatch: _nullableMap(payload['active_goal_patch']),
          bodyMeasurement: _nullableMap(payload['body_measurement']),
        );
        final response = await _remote.patchSettings(
          clientRequestId: command.clientRequestId,
          request: request,
        );
        await cacheSettings(response);
        await _outbox.markSynced(command.id);
      } catch (error) {
        await _outbox.markFailed(command.id, retryable: _isRetryable(error));
      }
    }
  }

  Future<void> cacheBootstrap(dynamic response) async {
    final profile = profileFromDto(response.profile);
    await _db.into(_db.profilesLocal).insertOnConflictUpdate(
          ProfilesLocalCompanion.insert(
            id: profile.id,
            displayName: Value(profile.displayName),
            locale: Value(profile.locale),
            timezone: profile.timezone,
            unitSystem: Value(profile.unitSystem),
            countryCode: Value(profile.countryCode),
            cuisinePreferencesJson: Value(encodeStringList(profile.cuisinePreferences)),
            cloudMediaStorage: Value(profile.cloudMediaStorage),
            saveOriginalPhotos: Value(profile.saveOriginalPhotos),
            aiImprovementConsent: Value(profile.aiImprovementConsent),
            onboardingCompletedAt: Value(profile.onboardingCompletedAt),
            syncStatus: const Value('synced'),
          ),
        );

    if (response.activeGoal != null) {
      final goal = goalFromDto(response.activeGoal);
      await _deleteLocalActiveGoalPlaceholder(goal.userId);
      await _db.into(_db.nutritionGoalsLocal).insertOnConflictUpdate(
            NutritionGoalsLocalCompanion.insert(
              id: goal.id,
              userId: goal.userId,
              goalType: goal.goalType,
              caloriesKcal: goal.caloriesKcal,
              proteinG: goal.proteinG,
              carbsG: goal.carbsG,
              fatG: goal.fatG,
              fiberG: Value(goal.fiberG),
              startsOn: goal.startsOn,
              endsOn: Value(goal.endsOn),
              isActive: Value(goal.isActive),
              syncStatus: const Value('synced'),
            ),
          );
    }

    for (final entry in (response.featureFlags as Map<String, Object?>).entries) {
      await _db.into(_db.featureFlagsLocal).insertOnConflictUpdate(
            FeatureFlagsLocalCompanion.insert(
              key: entry.key,
              valueJson: jsonEncode(entry.value),
            ),
          );
    }
  }

  Future<void> cacheSettings(dynamic response) async {
    final profile = profileFromDto(response.profile);
    await _db.into(_db.profilesLocal).insertOnConflictUpdate(
          ProfilesLocalCompanion.insert(
            id: profile.id,
            displayName: Value(profile.displayName),
            locale: Value(profile.locale),
            timezone: profile.timezone,
            unitSystem: Value(profile.unitSystem),
            countryCode: Value(profile.countryCode),
            cuisinePreferencesJson: Value(encodeStringList(profile.cuisinePreferences)),
            cloudMediaStorage: Value(profile.cloudMediaStorage),
            saveOriginalPhotos: Value(profile.saveOriginalPhotos),
            aiImprovementConsent: Value(profile.aiImprovementConsent),
            onboardingCompletedAt: Value(profile.onboardingCompletedAt),
            syncStatus: const Value('synced'),
          ),
        );

    if (response.activeGoal != null) {
      final goal = goalFromDto(response.activeGoal);
      await _deleteLocalActiveGoalPlaceholder(goal.userId);
      await _db.into(_db.nutritionGoalsLocal).insertOnConflictUpdate(
            NutritionGoalsLocalCompanion.insert(
              id: goal.id,
              userId: goal.userId,
              goalType: goal.goalType,
              caloriesKcal: goal.caloriesKcal,
              proteinG: goal.proteinG,
              carbsG: goal.carbsG,
              fatG: goal.fatG,
              fiberG: Value(goal.fiberG),
              startsOn: goal.startsOn,
              endsOn: Value(goal.endsOn),
              isActive: Value(goal.isActive),
              syncStatus: const Value('synced'),
            ),
          );
    }
  }

  Future<void> _saveDraftLocally(String userId, OnboardingDraft draft, String syncStatus) async {
    final completedAt = DateTime.now().toUtc();
    await _db.into(_db.profilesLocal).insertOnConflictUpdate(
          ProfilesLocalCompanion.insert(
            id: userId,
            displayName: Value(draft.displayName.trim().isEmpty ? null : draft.displayName.trim()),
            locale: Value(draft.locale),
            timezone: draft.timezone,
            unitSystem: Value(draft.unitSystem),
            countryCode: Value(draft.countryCode),
            cuisinePreferencesJson: Value(encodeStringList(draft.cuisinePreferences)),
            onboardingCompletedAt: Value(completedAt),
            syncStatus: Value(syncStatus),
          ),
        );

    await _db.into(_db.nutritionGoalsLocal).insertOnConflictUpdate(
          NutritionGoalsLocalCompanion.insert(
            id: 'local-active-goal',
            userId: userId,
            goalType: draft.goalType,
            caloriesKcal: draft.caloriesKcal,
            proteinG: draft.proteinG,
            carbsG: draft.carbsG,
            fatG: draft.fatG,
            startsOn: DateTime(completedAt.year, completedAt.month, completedAt.day),
            isActive: const Value(true),
            syncStatus: Value(syncStatus),
          ),
        );

    if (draft.bodyMeasurement != null) {
      await _db.into(_db.bodyMeasurementsLocal).insert(
            BodyMeasurementsLocalCompanion.insert(
              id: const Uuid().v4(),
              userId: userId,
              measuredAt: draft.bodyMeasurement!.measuredAt,
              weightKg: Value(draft.bodyMeasurement!.weightKg),
              bodyFatPct: Value(draft.bodyMeasurement!.bodyFatPct),
              source: Value(draft.bodyMeasurement!.source),
              syncStatus: Value(syncStatus),
            ),
          );
    }
  }

  SettingsPatchRequestDto _settingsRequestFromDraft(String clientRequestId, OnboardingDraft draft) {
    final measurement = draft.bodyMeasurement;
    return SettingsPatchRequestDto(
      clientRequestId: clientRequestId,
      profilePatch: {
        'display_name': draft.displayName.trim().isEmpty ? null : draft.displayName.trim(),
        'locale': draft.locale,
        'timezone': draft.timezone,
        'unit_system': draft.unitSystem,
        'country_code': draft.countryCode,
        'cuisine_preferences': draft.cuisinePreferences,
        'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
      },
      activeGoalPatch: {
        'goal_type': draft.goalType,
        'calories_kcal': draft.caloriesKcal,
        'protein_g': draft.proteinG,
        'carbs_g': draft.carbsG,
        'fat_g': draft.fatG,
        'starts_on': DateTime.now().toIso8601String().substring(0, 10),
      },
      bodyMeasurement: measurement == null
          ? null
          : {
              'measured_at': measurement.measuredAt.toUtc().toIso8601String(),
              'weight_kg': measurement.weightKg,
              'body_fat_pct': measurement.bodyFatPct,
              'source': measurement.source,
            },
    );
  }

  Map<String, dynamic>? _nullableMap(Object? value) {
    if (value == null) return null;
    return Map<String, dynamic>.from(value as Map);
  }

  Future<void> _deleteLocalActiveGoalPlaceholder(String userId) {
    return (_db.delete(_db.nutritionGoalsLocal)
          ..where((tbl) => tbl.userId.equals(userId) & tbl.id.equals('local-active-goal')))
        .go();
  }

  bool _isRetryable(Object error) {
    final message = error.toString().toLowerCase();
    return !(message.contains('invalid_input') ||
        message.contains('auth_required') ||
        message.contains('idempotency_conflict') ||
        message.contains('400') ||
        message.contains('401') ||
        message.contains('409'));
  }

  UserProfile _profileFromRow(ProfilesLocalData row) => UserProfile(
        id: row.id,
        displayName: row.displayName,
        locale: row.locale,
        timezone: row.timezone,
        unitSystem: row.unitSystem,
        countryCode: row.countryCode,
        cuisinePreferences: decodeStringList(row.cuisinePreferencesJson),
        cloudMediaStorage: row.cloudMediaStorage,
        saveOriginalPhotos: row.saveOriginalPhotos,
        aiImprovementConsent: row.aiImprovementConsent,
        onboardingCompletedAt: row.onboardingCompletedAt,
      );

  NutritionGoal _goalFromRow(NutritionGoalsLocalData row) => NutritionGoal(
        id: row.id,
        userId: row.userId,
        goalType: row.goalType,
        caloriesKcal: row.caloriesKcal,
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
        fiberG: row.fiberG,
        startsOn: row.startsOn,
        endsOn: row.endsOn,
        isActive: row.isActive,
      );
}
