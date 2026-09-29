import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/core/design_system/effects/effects_scope.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/preferences/ui_preferences.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

void main() {
  group('friendlyError', () {
    test('offline errors are reassuring and retryable', () {
      final e = friendlyError(const SocketException('Failed host lookup'));
      expect(e.offline, isTrue);
      expect(e.retryable, isTrue);
      expect(e.message, isNot(contains('SocketException')));
    });

    test('validation messages pass through', () {
      final e = friendlyError(ArgumentError('Add at least one item.'));
      expect(e.message, 'Add at least one item.');
      expect(e.retryable, isFalse);
    });

    test('unknown errors never leak class names', () {
      final e = friendlyError(Exception('NullThrownError in foo.dart:12'));
      expect(e.message, isNot(contains('foo.dart')));
    });

    test('auth copy distinguishes common cases', () {
      expect(authErrorMessage(Exception('invalid_credentials')),
          contains('Wrong email or password'));
      expect(authErrorMessage(Exception('otp_expired')), contains('expired'));
      expect(authErrorMessage(Exception('429 too many requests')),
          contains('Too many tries'));
    });
  });

  group('Labels', () {
    test('human meal types and sync states', () {
      expect(Labels.mealType(MealType.unknown), 'Other');
      expect(Labels.mealSync(MealSyncStatus.synced), isNull);
      expect(Labels.mealSync(MealSyncStatus.pending)!.label, 'Saved on phone');
    });

    test('provenance and confidence', () {
      expect(Labels.provenance('ai_photo'), 'Photo estimate');
      expect(Labels.provenance('label_ocr'), 'Nutrition label');
      expect(Labels.provenance('barcode_manual'), 'From the package');
      expect(Labels.confidence(.9), 'High confidence');
      expect(Labels.confidence(.5), 'Low confidence');
    });

    test('relative day labels', () {
      final now = DateTime(2026, 9, 24, 12);
      expect(Labels.day(DateTime(2026, 9, 24, 8), now: now), 'Today');
      expect(Labels.day(DateTime(2026, 9, 23, 8), now: now), 'Yesterday');
      expect(Labels.relative(now.add(const Duration(hours: 3)), now: now),
          'in 3 hours');
      expect(Labels.relative(now.subtract(const Duration(days: 1)), now: now),
          '1 day ago');
      expect(Labels.timezone('America/New_York'), 'New York');
    });

    test('count pluralizes and groups', () {
      expect(Labels.count(1, 'meal'), '1 meal');
      expect(Labels.count(0, 'meal'), '0 meals');
      expect(Labels.count(3, 'change'), '3 changes');
      expect(Labels.count(1240, 'meal'), '1,240 meals');
      expect(Labels.count(2, 'person', 'people'), '2 people');
    });
  });

  group('EffectsQuality resolution', () {
    test('user preference maps directly', () {
      expect(
          SgEffectsScope.resolve(
              preference: VisualEffectsLevel.off,
              lowPower: false,
              watchdogSteps: 0),
          EffectsQuality.off);
    });

    test('low power and jank step full down to reduced', () {
      expect(
          SgEffectsScope.resolve(
              preference: VisualEffectsLevel.full,
              lowPower: true,
              watchdogSteps: 0),
          EffectsQuality.reduced);
      expect(
          SgEffectsScope.resolve(
              preference: VisualEffectsLevel.full,
              lowPower: false,
              watchdogSteps: 1),
          EffectsQuality.reduced);
    });

    test('never escalates past the user preference', () {
      expect(
          SgEffectsScope.resolve(
              preference: VisualEffectsLevel.reduced,
              lowPower: false,
              watchdogSteps: 0),
          EffectsQuality.reduced);
    });
  });
}
