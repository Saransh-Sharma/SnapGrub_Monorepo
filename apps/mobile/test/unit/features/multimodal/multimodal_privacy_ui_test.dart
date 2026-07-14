import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/data/repositories/profile_repository.dart';
import 'package:snapgrub/data/services/device_identity_service.dart';
import 'package:snapgrub/data/services/profile_remote_service.dart';
import 'package:snapgrub/data/services/supabase_function_client.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';

import '../../../helpers/mobile_test_harness.dart';

void main() {
  testWidgets('text entry validates empty input and opens editable draft',
      (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    await harness.pumpRouter(tester);

    harness.container.read(appRouterProvider).go('/text-entry');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pump();
    expect(find.text('Enter a meal first.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Meal'),
      '2 rotis and dal',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Meal Editor'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '2 rotis and dal'), findsWidgets);
    expect(find.text('Estimate ready for review.'), findsOneWidget);
    expect(find.textContaining('text_parser'), findsOneWidget);
  });

  testWidgets('barcode miss offers manual fallback into Meal Editor',
      (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    await harness.pumpRouter(tester);

    harness.container.read(appRouterProvider).go('/barcode');
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(OutlinedButton, 'E2E unknown barcode'));
    await tester.pumpAndSettle();

    expect(find.text('E2E barcode was not found.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Product name'),
      'Unknown bar',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '180');
    await tester.enterText(find.widgetWithText(TextField, 'Protein'), '6');
    await tester.enterText(find.widgetWithText(TextField, 'Carbs'), '24');
    await tester.enterText(find.widgetWithText(TextField, 'Fat'), '8');
    await tester
        .tap(find.widgetWithText(FilledButton, 'Review custom product'));
    await tester.pumpAndSettle();

    expect(find.text('Meal Editor'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Unknown bar'), findsWidgets);
  });

  testWidgets('voice permission denial keeps text fallback available',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugin.csdcorp.com/speech_to_text'),
      (call) async => switch (call.method) {
        'initialize' => false,
        'has_permission' => false,
        _ => null,
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugin.csdcorp.com/speech_to_text'),
        null,
      );
    });
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    await harness.pumpRouter(tester);

    harness.container.read(appRouterProvider).go('/voice-entry');
    await tester.pumpAndSettle();

    expect(find.text('Microphone permission is unavailable. Use text instead.'),
        findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Use text instead'));
    await tester.pumpAndSettle();
    expect(find.text('Text meal'), findsOneWidget);
  });

  testWidgets('privacy export, delete, and clear-local flows are guarded',
      (tester) async {
    final harness = await MobileTestHarness.create(
      overrides: [
        profileRepositoryProvider.overrideWith(
          (ref) => TestProfileRepository(ref.watch(appDatabaseProvider)),
        ),
      ],
    );
    addTearDown(harness.dispose);
    await harness.pumpRouter(tester);

    harness.container.read(appRouterProvider).go('/settings/privacy');
    await tester.pumpAndSettle();
    expect(find.text('AI consent'), findsOneWidget);
    expect(find.text('Export data'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);

    await tester.tap(find.text('AI consent'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    final profileRow =
        await harness.db.select(harness.db.profilesLocal).getSingle();
    expect(profileRow.aiImprovementConsent, isTrue);

    harness.container.read(appRouterProvider).go('/settings/privacy/export');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create export'));
    await tester.pumpAndSettle();
    expect(find.text('Status: completed'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);

    harness.container
        .read(appRouterProvider)
        .go('/settings/privacy/delete-account');
    await tester.pumpAndSettle();
    var deleteButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete account'),
    );
    expect(deleteButton.onPressed, isNull);
    await tester.enterText(
      find.widgetWithText(TextField, 'Type DELETE to confirm'),
      'DELETE',
    );
    await tester.pump();
    deleteButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete account'),
    );
    expect(deleteButton.onPressed, isNotNull);

    harness.container
        .read(appRouterProvider)
        .go('/settings/privacy/clear-local-data');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear local data'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen.auth')), findsOneWidget);
  });
}

class TestProfileRepository extends ProfileRepository {
  TestProfileRepository(this.db)
      : super(
          db: db,
          remote: const ProfileRemoteService(SnapGrubFunctionClient(null)),
          outbox: OutboxRepository(db),
          deviceIdentity: const DeviceIdentityService(),
        );

  final AppDatabase db;

  @override
  Future<void> savePrivacySettings({
    required String userId,
    required bool cloudMediaStorage,
    required bool saveOriginalPhotos,
    required bool aiImprovementConsent,
  }) async {
    await (db.update(db.profilesLocal)..where((tbl) => tbl.id.equals(userId)))
        .write(
      ProfilesLocalCompanion(
        cloudMediaStorage: Value(cloudMediaStorage),
        saveOriginalPhotos: Value(saveOriginalPhotos),
        aiImprovementConsent: Value(aiImprovementConsent),
        syncStatus: const Value('pending'),
      ),
    );
  }
}
