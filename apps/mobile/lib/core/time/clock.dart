import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wall clock used by time-of-day UI (greetings, day-close card).
/// Overridable so tests and marketing captures can pin the time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
