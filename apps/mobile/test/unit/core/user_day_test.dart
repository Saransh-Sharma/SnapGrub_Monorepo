import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/core/time/user_day.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('user day window follows profile timezone', () {
    final instant = DateTime.utc(2026, 5, 20, 20, 30);
    final day = userDayFor(instant, 'Asia/Kolkata');

    expect(day.day, DateTime(2026, 5, 21));
    expect(day.startUtc, DateTime.utc(2026, 5, 20, 18, 30));
    expect(day.endUtc, DateTime.utc(2026, 5, 21, 18, 30));
  });
}
