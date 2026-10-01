import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/theme/app_theme.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/custom_foods/data/custom_food_repository.dart';
import 'package:snapgrub/features/custom_foods/domain/custom_food.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_editor/presentation/meal_editor_screen.dart';

import '../../../helpers/mobile_test_harness.dart';

Finder _field(String id) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.byType(TextField),
    );

final _stepperPlus = find.descendant(
  of: find.byType(SgStepper),
  matching: find.byIcon(Icons.add_rounded),
);

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Advances fake time in small steps without waiting for snackbars to close.
Future<void> _steps(WidgetTester tester, {int count = 10}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<GoRouter> _pumpRouter(
  WidgetTester tester,
  MobileTestHarness harness,
) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Home screen'))),
      ),
      GoRoute(
        path: '/meal-editor',
        builder: (context, state) => MealEditorScreen(
          mealId: state.uri.queryParameters['id'],
          initialDraft:
              state.extra is MealDraft ? state.extra! as MealDraft : null,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp.router(
        theme: buildSnapGrubTheme(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('totals update live while a portion or raw value changes',
      (tester) async {
    _tallView(tester);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final draft = testMealDraft(title: 'Dal bowl');

    await harness.pumpScreen(tester, MealEditorScreen(initialDraft: draft));
    expect(find.text('420 kcal'), findsOneWidget);

    // Expand the row and step the portion up by a quarter.
    await tester.tap(find.text('Dal'));
    await tester.pumpAndSettle();
    await tester.tap(_stepperPlus);
    await tester.pumpAndSettle();

    final item = draft.items.single;
    expect(item.quantity, 1.25);
    expect(item.caloriesKcal, 525);
    expect(item.proteinG, 30);
    expect(item.carbsG, 60);
    expect(item.gramsEstimated, 312.5);
    expect(find.text('525 kcal'), findsOneWidget);
    expect(find.text('P 30 g · C 60 g · F 18 g'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Total calories 525')), findsOneWidget);

    // Raw nutrition edits also refresh the totals immediately.
    await tester.tap(find.text('Edit nutrition'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('meal.item.0.kcal'), '600');
    await tester.pumpAndSettle();
    expect(find.text('600 kcal'), findsOneWidget);

    // …and the stepper then scales from the edited values (600 / 1.25).
    await tester.tap(_stepperPlus);
    await tester.pumpAndSettle();
    expect(item.caloriesKcal, 720);
    expect(find.text('720 kcal'), findsOneWidget);
  });

  testWidgets('swiping an item removes it and Undo brings it back',
      (tester) async {
    _tallView(tester);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final draft = testMealDraft(title: 'Thali')
      ..items.add(MealDraftItem(
        name: 'Roti',
        quantity: 2,
        unit: 'piece',
        caloriesKcal: 240,
        proteinG: 8,
        carbsG: 40,
        fatG: 6,
      ));

    await harness.pumpScreen(tester, MealEditorScreen(initialDraft: draft));
    expect(find.text('660 kcal'), findsOneWidget);

    await tester.drag(find.text('Roti'), const Offset(-600, 0));
    await _steps(tester, count: 8);
    expect(find.text('Roti'), findsNothing);
    expect(draft.items, hasLength(1));
    expect(find.text('420 kcal'), findsOneWidget);
    expect(find.text('“Roti” removed'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await _steps(tester, count: 8);
    expect(find.text('Roti'), findsOneWidget);
    expect(draft.items, hasLength(2));
    expect(find.text('660 kcal'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('low confidence reads as a calm check, not an error',
      (tester) async {
    _tallView(tester);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);

    await harness.pumpScreen(
      tester,
      MealEditorScreen(
        initialDraft: testMealDraft(
          title: 'AI paneer bowl',
          source: MealSource.photo,
          confidence: 0.62,
        ),
      ),
    );

    expect(find.text('Review meal'), findsOneWidget);
    expect(find.text('Log meal'), findsOneWidget);
    expect(find.text('Estimate · Medium confidence'), findsOneWidget);
    expect(find.text('Check portion'), findsOneWidget);
    expect(find.textContaining('photo_test'), findsNothing);
    expect(
      find.bySemanticsLabel('Dal, 1 bowl, 420 calories, check portion'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('How estimates work'));
    await tester.pumpAndSettle();
    expect(find.text('How estimates work'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
  });

  testWidgets('logging a new meal pops back and offers Logged · Undo',
      (tester) async {
    _tallView(tester);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final router = await _pumpRouter(tester, harness);
    final draft = testMealDraft(title: 'Dal bowl');

    router.push('/meal-editor', extra: draft);
    await tester.pumpAndSettle();
    expect(find.byType(MealEditorScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal.save')));
    await _steps(tester);

    expect(find.byType(MealEditorScreen), findsNothing);
    expect(find.text('Home screen'), findsOneWidget);
    expect(find.text('Logged “Dal bowl” · 420 kcal'), findsOneWidget);
    expect(
      await harness.container.read(mealRepositoryProvider).getMeal(draft.id),
      isNotNull,
    );

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('leaving with unsaved work asks first', (tester) async {
    _tallView(tester);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final router = await _pumpRouter(tester, harness);

    router.push('/meal-editor', extra: testMealDraft(title: 'Dal bowl'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav.home')));
    await tester.pumpAndSettle();
    expect(find.text('Discard this meal?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(MealEditorScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav.home')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(MealEditorScreen), findsNothing);
    expect(find.text('Home screen'), findsOneWidget);
  });

  testWidgets('saving an existing meal says Saved', (tester) async {
    _tallView(tester);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final meal = await harness.container
        .read(mealRepositoryProvider)
        .saveDraft(testMealDraft(title: 'Dal bowl'));
    final router = await _pumpRouter(tester, harness);

    router.push('/meal-editor?id=${meal.id}');
    await tester.pumpAndSettle();
    expect(find.text('Edit meal'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);

    // Untouched: Back leaves without asking.
    await tester.tap(find.byKey(const ValueKey('nav.home')));
    await tester.pumpAndSettle();
    expect(find.byType(MealEditorScreen), findsNothing);

    router.push('/meal-editor?id=${meal.id}');
    await tester.pumpAndSettle();
    await tester.enterText(_field('meal.title'), 'Dal and rice');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('meal.save')));
    await _steps(tester);

    expect(find.byType(MealEditorScreen), findsNothing);
    expect(find.text('Saved'), findsOneWidget);
    final saved =
        await harness.container.read(mealRepositoryProvider).getMeal(meal.id);
    expect(saved!.title, 'Dal and rice');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('works at 2.0 text scale on a phone without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final draft = testMealDraft(
      title: 'A rather long lunch title that wraps',
      source: MealSource.photo,
      confidence: .55,
    );

    await harness.pumpScreen(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: MealEditorScreen(initialDraft: draft),
        ),
      ),
    );

    final listScrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(find.text('Dal'), 200,
        scrollable: listScrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dal'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Edit nutrition'), 200,
        scrollable: listScrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit nutrition'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('meal.item.0.fat')), 200,
        scrollable: listScrollable);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('meal.save')), findsOneWidget);
  });

  testWidgets('a missing meal shows a friendly empty state', (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);

    await harness.pumpScreen(
        tester, const MealEditorScreen(mealId: 'does-not-exist'));

    expect(find.text('Meal not found'), findsOneWidget);
  });

  testWidgets('manual meals open with fields ready to fill', (tester) async {
    _tallView(tester);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);

    await harness.pumpScreen(tester, const MealEditorScreen());

    for (final id in const [
      'meal.title',
      'meal.item.0.food',
      'meal.item.0.kcal',
      'meal.item.0.protein',
      'meal.item.0.carbs',
      'meal.item.0.fat',
      'meal.add_item',
      'meal.add_custom_food',
      'meal.save',
      'meal.save_template',
      'scaffold.meal_editor',
    ]) {
      expect(find.byKey(ValueKey(id)), findsOneWidget, reason: id);
    }
  });

  testWidgets('custom food picker filters by search', (tester) async {
    _tallView(tester);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final foods = harness.container.read(customFoodRepositoryProvider);
    for (final (name, kcal) in const [('Paneer', 265.0), ('Poha', 180.0)]) {
      await foods.save(
        testUserId,
        CustomFoodDraft(
          name: name,
          servingQuantity: 1,
          servingUnit: 'serving',
          servingGrams: 100,
          caloriesKcal: kcal,
          proteinG: 10,
          carbsG: 20,
          fatG: 5,
        ),
      );
    }

    await harness.pumpScreen(tester, const MealEditorScreen());
    await tester.tap(find.byKey(const ValueKey('meal.add_custom_food')));
    await tester.pumpAndSettle();
    expect(find.text('My foods'), findsOneWidget);
    expect(find.text('Paneer'), findsOneWidget);
    expect(find.text('Poha'), findsOneWidget);

    await tester.enterText(_field('meal.custom_food.search'), 'pan');
    await tester.pumpAndSettle();
    expect(find.text('Poha'), findsNothing);

    await tester.enterText(_field('meal.custom_food.search'), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);

    await tester.enterText(_field('meal.custom_food.search'), 'pan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paneer'));
    await _steps(tester);

    // The untouched placeholder item is replaced by the picked food.
    expect(find.text('My foods'), findsNothing);
    expect(find.text('Paneer'), findsOneWidget);
    expect(find.text('New item'), findsNothing);
    expect(find.text('265 kcal'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('fix with a sentence replaces items through the parser',
      (tester) async {
    _tallView(tester);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final draft = testMealDraft(title: 'Dal bowl');

    await harness.pumpScreen(tester, MealEditorScreen(initialDraft: draft));
    final originalId = draft.items.single.id;

    await tester.enterText(_field('meal.fix_sentence'), 'it was two bowls');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await _steps(tester);

    expect(draft.items.single.id, isNot(originalId));
    expect(find.textContaining('Updated 1 item'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
