import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/home/presentation/home_screen.dart';
import 'package:snapgrub/features/progress/presentation/progress_screen.dart';

import '../../../helpers/mobile_test_harness.dart';

void main() {
  testWidgets('Smart repeats stay hidden when feature flag is disabled',
      (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    await _setFlag(harness.db, 'smart_foods_v2.enabled', false);
    harness.container.invalidate(profileControllerProvider);
    await _seedDefault(harness.db);

    await harness.pumpScreen(tester, const ProgressScreen());

    expect(find.text('Smart repeats'), findsNothing);
  });

  testWidgets('Smart repeats show suggestions and Review opens Meal Editor',
      (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    await _seedDefault(harness.db);
    final beforeMeals = await harness.db.select(harness.db.mealsLocal).get();

    await harness.pumpRouter(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Smart repeats'), findsOneWidget);
    expect(find.text('Paneer bowl'), findsOneWidget);

    await tester.tap(find.text('Review').first);
    await tester.pumpAndSettle();

    expect(find.text('Meal Editor'), findsOneWidget);
    expect(find.text('Paneer bowl'), findsWidgets);
    final afterMeals = await harness.db.select(harness.db.mealsLocal).get();
    expect(afterMeals.length, beforeMeals.length);
  });
}

Future<void> _setFlag(AppDatabase db, String key, bool enabled) async {
  await db.into(db.featureFlagsLocal).insertOnConflictUpdate(
        FeatureFlagsLocalCompanion.insert(
          key: key,
          valueJson: jsonEncode(enabled),
        ),
      );
}

Future<void> _seedDefault(AppDatabase db) async {
  await db.into(db.userFoodDefaultsLocal).insertOnConflictUpdate(
        UserFoodDefaultsLocalCompanion.insert(
          id: 'default-paneer',
          userId: testUserId,
          foodRefKind: 'custom',
          foodRefId: 'custom-paneer',
          foodName: 'Paneer bowl',
          preferredQuantity: const Value(1),
          preferredUnit: 'serving',
          preferredGrams: const Value(250),
          caloriesKcal: const Value(420),
          proteinG: const Value(28),
          carbsG: const Value(24),
          fatG: const Value(22),
          useCount: const Value(5),
          lastUsedAt: Value(DateTime(2026, 5, 29, 12)),
        ),
      );
}
