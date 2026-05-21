import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';

void main() {
  test('default onboarding draft is valid', () {
    const draft = OnboardingDraft();
    expect(() => draft.validate(), returnsNormally);
  });

  test('invalid calories are rejected', () {
    const draft = OnboardingDraft(caloriesKcal: 200);
    expect(draft.validate, throwsArgumentError);
  });

  test('weight creates onboarding body measurement', () {
    const draft = OnboardingDraft(weightKg: 82);
    expect(draft.bodyMeasurement?.weightKg, 82);
    expect(draft.bodyMeasurement?.source, 'onboarding');
  });

  test('invalid target weight is rejected', () {
    const draft = OnboardingDraft(targetWeightKg: 10);
    expect(draft.validate, throwsArgumentError);
  });
}
