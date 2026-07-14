import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/app/e2e/e2e_data.dart';
import 'package:snapgrub/app/env/app_config.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/app/theme/app_theme.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/capture/application/capture_controller.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/features/capture/domain/capture_state.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/profile/domain/nutrition_goal.dart';
import 'package:snapgrub/features/profile/domain/profile.dart';
import 'package:snapgrub/features/profile/domain/profile_state.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

const testUserId = 'test-user-1';
const testTimezone = 'Asia/Kolkata';

const testE2eConfig = AppConfig(
  environment: 'dev',
  supabaseUrl: '',
  supabaseAnonKey: '',
  e2eEnabled: true,
  e2eBackend: 'mock',
  e2eAuth: 'password',
);

const testMissingConfig = AppConfig(
  environment: 'dev',
  supabaseUrl: '',
  supabaseAnonKey: '',
  e2eEnabled: false,
  e2eBackend: '',
  e2eAuth: '',
);

class MobileTestHarness {
  MobileTestHarness._({
    required this.db,
    required this.container,
  });

  final AppDatabase db;
  final ProviderContainer container;

  static Future<MobileTestHarness> create({
    bool signedIn = true,
    bool profileComplete = true,
    AppConfig config = testE2eConfig,
    Map<String, Object?>? featureFlags,
    List<Override> overrides = const [],
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({
      if (signedIn) 'snapgrub.e2e.user_id': testUserId,
    });
    final db = AppDatabase(NativeDatabase.memory());
    if (profileComplete) {
      await seedProfile(db, featureFlags: featureFlags);
    }
    if (config.isE2eMock) {
      await E2eData.ensureFeatureFlags(db);
    }
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appDatabaseProvider.overrideWithValue(db),
        captureControllerProvider.overrideWith(StaticCaptureController.new),
        syncControllerProvider.overrideWith(StaticSyncController.new),
        userDayTickProvider
            .overrideWith((ref, timezone) => DateTime(2026, 5, 30)),
        ...overrides,
      ],
    );
    return MobileTestHarness._(db: db, container: container);
  }

  Future<void> pumpRouter(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp.router(
              title: 'SnapGrub',
              theme: buildSnapGrubTheme(),
              routerConfig: ref.watch(appRouterProvider),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildSnapGrubTheme(),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> dispose() async {
    container.dispose();
  }
}

Future<void> seedProfile(
  AppDatabase db, {
  String userId = testUserId,
  Map<String, Object?>? featureFlags,
  bool onboardingComplete = true,
  bool weeklyInsightsEnabled = true,
}) async {
  final now = DateTime.now().toUtc();
  await db.into(db.profilesLocal).insertOnConflictUpdate(
        ProfilesLocalCompanion.insert(
          id: userId,
          displayName: const Value('Test User'),
          locale: const Value('en-IN'),
          timezone: testTimezone,
          unitSystem: const Value('metric'),
          countryCode: const Value('IN'),
          cuisinePreferencesJson: const Value('["indian"]'),
          onboardingCompletedAt: Value(onboardingComplete ? now : null),
          syncStatus: const Value('synced'),
        ),
      );
  await db.into(db.nutritionGoalsLocal).insertOnConflictUpdate(
        NutritionGoalsLocalCompanion.insert(
          id: 'goal-$userId',
          userId: userId,
          goalType: 'lose',
          caloriesKcal: 2000,
          proteinG: 120,
          carbsG: 220,
          fatG: 65,
          startsOn: DateTime(now.year, now.month, now.day),
          syncStatus: const Value('synced'),
        ),
      );

  final flags = featureFlags ??
      {
        ...E2eData.enabledFlags,
        'weekly_insights.enabled': weeklyInsightsEnabled,
      };
  for (final entry in flags.entries) {
    await db.into(db.featureFlagsLocal).insertOnConflictUpdate(
          FeatureFlagsLocalCompanion.insert(
            key: entry.key,
            valueJson: jsonEncode(entry.value),
          ),
        );
  }
}

MealDraft testMealDraft({
  String userId = testUserId,
  String title = 'Dal bowl',
  MealSource source = MealSource.manual,
  double? confidence,
}) {
  return MealDraft(
    userId: userId,
    timezone: testTimezone,
    title: title,
    source: source,
    mealType: MealType.lunch,
    confidenceOverall: confidence,
    provenanceType: source == MealSource.manual ? null : '${source.name}_test',
    analysisWarnings: confidence != null && confidence < 0.7
        ? const ['Low confidence']
        : const [],
    items: [
      MealDraftItem(
        name: 'Dal',
        quantity: 1,
        unit: 'bowl',
        gramsEstimated: 250,
        caloriesKcal: 420,
        proteinG: 24,
        carbsG: 48,
        fatG: 14,
        confidence: confidence,
        sourceType: source.name,
      ),
    ],
  );
}

UserProfile testProfile({
  String userId = testUserId,
  bool aiConsent = false,
  bool cloudMediaStorage = true,
  bool saveOriginalPhotos = false,
}) {
  return UserProfile(
    id: userId,
    displayName: 'Test User',
    locale: 'en-IN',
    timezone: testTimezone,
    unitSystem: 'metric',
    countryCode: 'IN',
    cuisinePreferences: const ['indian'],
    cloudMediaStorage: cloudMediaStorage,
    saveOriginalPhotos: saveOriginalPhotos,
    aiImprovementConsent: aiConsent,
    onboardingCompletedAt: DateTime.now().toUtc(),
  );
}

NutritionGoal testGoal({String userId = testUserId}) {
  return NutritionGoal(
    id: 'goal-$userId',
    userId: userId,
    goalType: 'lose',
    caloriesKcal: 2000,
    proteinG: 120,
    carbsG: 220,
    fatG: 65,
    startsOn: DateTime.now(),
    isActive: true,
  );
}

class StaticAuthController extends AuthController {
  static AuthState initialState = const AuthState.signedIn(testUserId);

  @override
  Future<AuthState> build() async => initialState;

  @override
  Future<void> signOut() async {
    state = const AsyncData(AuthState.signedOut());
  }
}

class StaticProfileController extends ProfileController {
  static AsyncValue<ProfileState> initialState = AsyncData(
    ProfileState(
      profile: testProfile(),
      activeGoal: testGoal(),
      featureFlags: E2eData.enabledFlags,
      syncStatus: ProfileSyncStatus.synced,
    ),
  );

  @override
  Future<ProfileState> build() async {
    final value = initialState;
    if (value.hasValue) return value.requireValue;
    if (value.hasError) {
      Error.throwWithStackTrace(value.error!, value.stackTrace!);
    }
    return Future<ProfileState>.delayed(const Duration(days: 1));
  }
}

class StaticSyncController extends SyncController {
  static SyncStatus initialStatus = SyncStatus.synced;
  int syncCalls = 0;

  @override
  Future<SyncStatus> build() async => initialStatus;

  @override
  Future<void> syncNow({SyncTrigger trigger = SyncTrigger.manual}) async {
    syncCalls += 1;
    state = AsyncData(initialStatus);
  }
}

class StaticCaptureController extends CaptureController {
  static CaptureState initialState =
      const CaptureState(status: CaptureStatus.permissionNeeded);
  final trackedActions = <String>[];

  @override
  CaptureState build() => initialState;

  @override
  Future<void> initializeIfPermitted() async {}

  @override
  Future<void> requestPermission() async {
    state = const CaptureState(status: CaptureStatus.permissionNeeded);
  }

  @override
  Future<void> initializePreview() async {
    state = const CaptureState(status: CaptureStatus.cameraReady);
  }

  @override
  Future<void> pausePreview() async {
    state = const CaptureState(status: CaptureStatus.cameraPaused);
  }

  @override
  Future<void> resumePreview() async {
    state = const CaptureState(status: CaptureStatus.cameraReady);
  }

  @override
  Future<CaptureAsset?> capture({required String userId}) async => null;

  @override
  Future<void> trackAction(String eventName) async {
    trackedActions.add(eventName);
  }
}
