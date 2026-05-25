import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/core/time/user_day.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('user day window follows profile timezone', () {
    final instant = DateTime.utc(2026, 5, 20, 20, 30);
    final day = userDayFor(instant, 'Asia/Kolkata');

    expect(day.day.year, 2026);
    expect(day.day.month, 5);
    expect(day.day.day, 21);
    expect(day.startUtc, DateTime.utc(2026, 5, 20, 18, 30));
    expect(day.endUtc, DateTime.utc(2026, 5, 21, 18, 30));
  });

  test('user day window handles DST spring-forward day', () {
    final day = userDayFor(
      DateTime.utc(2026, 3, 8, 12),
      'America/New_York',
    );

    expect(day.day.year, 2026);
    expect(day.day.month, 3);
    expect(day.day.day, 8);
    expect(day.startUtc, DateTime.utc(2026, 3, 8, 5));
    expect(day.endUtc, DateTime.utc(2026, 3, 9, 4));
  });

  test('user day window handles DST fall-back day', () {
    final day = userDayFor(
      DateTime.utc(2026, 11, 1, 12),
      'America/New_York',
    );

    expect(day.day.year, 2026);
    expect(day.day.month, 11);
    expect(day.day.day, 1);
    expect(day.startUtc, DateTime.utc(2026, 11, 1, 4));
    expect(day.endUtc, DateTime.utc(2026, 11, 2, 5));
  });
}
