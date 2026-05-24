import 'package:timezone/timezone.dart' as tz;

class UserDay {
  const UserDay({
    required this.day,
    required this.startUtc,
    required this.endUtc,
  });

  final DateTime day;
  final DateTime startUtc;
  final DateTime endUtc;
}

UserDay userDayFor(DateTime instant, String timezone) {
  final location = _locationOrUtc(timezone);
  final local = tz.TZDateTime.from(instant.toUtc(), location);
  return userDayWindow(
    DateTime(local.year, local.month, local.day),
    timezone,
  );
}

UserDay userDayWindow(DateTime day, String timezone) {
  final location = _locationOrUtc(timezone);
  final start = tz.TZDateTime(location, day.year, day.month, day.day);
  final end = tz.TZDateTime(location, day.year, day.month, day.day + 1);
  return UserDay(
    day: DateTime(day.year, day.month, day.day),
    startUtc: start.toUtc(),
    endUtc: end.toUtc(),
  );
}

DateTime nowInUserDay(String timezone) {
  return userDayFor(DateTime.now().toUtc(), timezone).day;
}

tz.Location _locationOrUtc(String timezone) {
  try {
    return tz.getLocation(timezone);
  } catch (_) {
    return tz.UTC;
  }
}
