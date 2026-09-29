import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/milestones/domain/streak.dart';

void main() {
  final today = DateTime(2026, 9, 24); // Thursday

  Set<DateTime> days(List<int> offsets) =>
      {for (final o in offsets) today.subtract(Duration(days: o))};

  test('counts consecutive logged days including today', () {
    final s = computeStreak(days([0, 1, 2, 3]), today);
    expect(s.current, 4);
    expect(s.loggedToday, isTrue);
  });

  test('today not logged yet does not break the streak', () {
    final s = computeStreak(days([1, 2, 3]), today);
    expect(s.current, 3);
    expect(s.loggedToday, isFalse);
  });

  test('one missed day per week is bridged by a freeze', () {
    // Logged Thu, Wed, (Tue missed), Mon.
    final s = computeStreak(days([0, 1, 3]), today);
    expect(s.current, 3);
    expect(s.frozenDays, {today.subtract(const Duration(days: 2))});
  });

  test('two missed days in a row break the streak', () {
    final s = computeStreak(days([0, 3, 4]), today);
    expect(s.current, 1);
  });

  test('tiers follow day thresholds', () {
    expect(StreakTier.forDays(0), StreakTier.none);
    expect(StreakTier.forDays(3), StreakTier.silver);
    expect(StreakTier.forDays(7), StreakTier.copper);
    expect(StreakTier.forDays(30), StreakTier.gold);
    expect(StreakTier.forDays(120), StreakTier.holo);
  });

  test('best streak remembers longer past runs', () {
    final s = computeStreak(days([0, 10, 11, 12, 13, 14]), today);
    expect(s.current, 1);
    expect(s.best, 5);
  });
}
