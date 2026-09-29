import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';

import 'onboarding_test_utils.dart';

OnboardingDraft _draft(ProviderContainer c) =>
    c.read(onboardingControllerProvider);

Future<void> _toGoal(WidgetTester tester, {String name = 'Asha'}) async {
  await tapOnboarding(tester, 'onboarding.next');
  await tester.enterText(find.byType(TextField), name);
  await tester.pump();
  await tapOnboarding(tester, 'onboarding.next');
}

void main() {
  testWidgets('continue explains what is missing instead of advancing',
      (tester) async {
    await pumpOnboardingFlow(tester);
    await tapOnboarding(tester, 'onboarding.next');
    expect(byId('onboarding.step.name'), findsOneWidget);

    await tapOnboarding(tester, 'onboarding.next');
    expect(byId('onboarding.error'), findsOneWidget);
    expect(find.textContaining('Add a name'), findsOneWidget);
    expect(byId('onboarding.step.name'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Asha');
    await tester.pump();
    expect(byId('onboarding.error'), findsNothing);
  });

  testWidgets('values survive going back, including the system back',
      (tester) async {
    final container = await pumpOnboardingFlow(tester);
    await _toGoal(tester);
    await tapOnboarding(tester, 'onboarding.goal.gain');
    await tapOnboarding(tester, 'onboarding.next');
    expect(byId('onboarding.step.sex'), findsOneWidget);

    // System back (Android back / iOS swipe) steps back through the flow.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(byId('onboarding.step.goal'), findsOneWidget);
    expect(_draft(container).goalType, 'gain');

    await tapOnboarding(tester, 'onboarding.back');
    expect(byId('onboarding.step.name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Asha'), findsOneWidget);
  });

  testWidgets('maintain skips target weight and pace', (tester) async {
    final container = await pumpOnboardingFlow(tester);
    await _toGoal(tester);
    await tapOnboarding(tester, 'onboarding.goal.maintain');
    await tapOnboarding(tester, 'onboarding.next');
    await tapOnboarding(tester, 'onboarding.sex.unspecified');
    await tapOnboarding(tester, 'onboarding.next');
    for (final step in ['birth_year', 'height', 'weight']) {
      expect(byId('onboarding.step.$step'), findsOneWidget, reason: step);
      await tapOnboarding(tester, 'onboarding.next');
    }
    expect(byId('onboarding.step.activity'), findsOneWidget);
    await tapOnboarding(tester, 'onboarding.activity.high');
    await tapOnboarding(tester, 'onboarding.next');
    expect(byId('onboarding.step.cuisines'), findsOneWidget);
    expect(_draft(container).activityLevel, 'high');
    expect(_draft(container).targetWeightKg, isNull);
  });

  testWidgets('unit toggle re-renders the picker without changing the value',
      (tester) async {
    final container = await pumpOnboardingFlow(tester);
    await _toGoal(tester);
    await tapOnboarding(tester, 'onboarding.next');
    await tapOnboarding(tester, 'onboarding.sex.female');
    await tapOnboarding(tester, 'onboarding.next');
    await tapOnboarding(tester, 'onboarding.next');
    expect(byId('onboarding.step.height'), findsOneWidget);
    expect(find.text('170 cm'), findsOneWidget);

    await tapOnboarding(tester, 'onboarding.unit.imperial');
    expect(find.text('5′ 7″'), findsOneWidget);
    expect(_draft(container).unitSystem, 'imperial');
    expect(_draft(container).heightCm, isNull);

    await tapOnboarding(tester, 'onboarding.next');
    expect(_draft(container).heightCm, 170);
    expect(find.text('lb'), findsWidgets);
  });

  testWidgets('pace shows a live goal date and eases unsafe paces',
      (tester) async {
    final container = await pumpOnboardingFlow(tester);
    final notifier = container.read(onboardingControllerProvider.notifier);
    notifier
      ..updateName('Asha')
      ..updateGoal('lose')
      ..updateWeightKg(90)
      ..updateHeightCm(180)
      ..updateTargetWeightKg(80)
      ..updatePace(1);
    await tester.pump();
    await _toGoal(tester);
    await tapOnboarding(tester, 'onboarding.next');
    await tapOnboarding(tester, 'onboarding.sex.female');
    for (var i = 0; i < 6; i++) {
      await tapOnboarding(tester, 'onboarding.next');
    }
    expect(byId('onboarding.step.pace'), findsOneWidget);
    expect(find.textContaining('Reach 80.0 kg by'), findsOneWidget);
    expect(find.textContaining('the safe maximum for now'), findsOneWidget);
  });

  testWidgets('adjust targets saves hand-edited values', (tester) async {
    final container = await pumpOnboardingFlow(tester, reduceMotion: true);
    await _toGoal(tester);
    await tapOnboarding(tester, 'onboarding.goal.maintain');
    await tapOnboarding(tester, 'onboarding.next');
    await tapOnboarding(tester, 'onboarding.sex.male');
    for (var i = 0; i < 7; i++) {
      await tapOnboarding(tester, 'onboarding.next');
    }
    // With Reduce Motion the "building" beat is short enough to finish
    // inside the settle, so we land straight on the reveal.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(byId('onboarding.plan_card'), findsOneWidget);
    final planned = _draft(container).caloriesKcal;
    expect(planned, _draft(container).plan()!.caloriesKcal);

    await tapOnboarding(tester, 'onboarding.adjust_targets');
    final calories = find.descendant(
        of: byId('onboarding.calories'), matching: find.byType(TextField));
    await tester.enterText(calories, '2100');
    await tester.pump();
    await tapOnboarding(tester, 'onboarding.adjust.save');
    expect(_draft(container).caloriesKcal, 2100);
    expect(_draft(container).targetsAdjusted, isTrue);
    expect(find.text('Adjusted'), findsOneWidget);

    // Back from the reveal skips the "building" interstitial.
    await tapOnboarding(tester, 'onboarding.back');
    expect(byId('onboarding.step.reminders'), findsOneWidget);
  });

  testWidgets('adjust targets rejects out-of-range values', (tester) async {
    final container = await pumpOnboardingFlow(tester, reduceMotion: true);
    await _toGoal(tester);
    await tapOnboarding(tester, 'onboarding.goal.custom');
    await tapOnboarding(tester, 'onboarding.next');
    await tapOnboarding(tester, 'onboarding.sex.female');
    for (var i = 0; i < 7; i++) {
      await tapOnboarding(tester, 'onboarding.next');
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tapOnboarding(tester, 'onboarding.adjust_targets');
    final calories = find.descendant(
        of: byId('onboarding.calories'), matching: find.byType(TextField));
    await tester.enterText(calories, '200');
    await tester.pump();
    await tapOnboarding(tester, 'onboarding.adjust.save');
    expect(find.textContaining('must be 500–6,000'), findsOneWidget);
    expect(_draft(container).targetsAdjusted, isFalse);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('every step lays out at ${scale}x text on a small phone',
        (tester) async {
      await pumpOnboardingFlow(
        tester,
        textScale: scale,
        size: const Size(360, 690),
      );
      await _toGoal(tester);
      await tapOnboarding(tester, 'onboarding.goal.lose');
      await tapOnboarding(tester, 'onboarding.next');
      await tapOnboarding(tester, 'onboarding.sex.female');
      for (final step in [
        'birth_year',
        'height',
        'weight',
        'target_weight',
        'activity',
        'pace',
        'cuisines',
        'reminders'
      ]) {
        await tapOnboarding(tester, 'onboarding.next');
        expect(byId('onboarding.step.$step'), findsOneWidget, reason: step);
      }
      await tapOnboarding(tester, 'onboarding.next');
      expect(byId('onboarding.plan_card'), findsOneWidget);
      expect(find.text('Start logging'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pickers expose adjustable semantics', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await pumpOnboardingFlow(tester);
    await _toGoal(tester);
    await tapOnboarding(tester, 'onboarding.next');
    await tapOnboarding(tester, 'onboarding.sex.female');
    for (var i = 0; i < 3; i++) {
      await tapOnboarding(tester, 'onboarding.next');
    }
    expect(byId('onboarding.step.weight'), findsOneWidget);
    final ruler = find.bySemanticsLabel('Current weight');
    expect(ruler, findsOneWidget);
    final node = tester.getSemantics(ruler);
    expect(node.value, '70.0 kg');
    expect(node.increasedValue, '70.5 kg');
    tester.semantics.performAction(
        find.semantics.byLabel('Current weight'), SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(_draft(container).weightKg, 70.5);
    handle.dispose();
  });
}
