import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// Device locale / timezone as detected at the start of onboarding.
class DetectedRegion {
  const DetectedRegion({
    required this.locale,
    required this.countryCode,
    this.timezone,
  });

  /// BCP-47 tag, e.g. `en-GB`.
  final String locale;
  final String? countryCode;

  /// IANA zone, e.g. `Europe/London`; null when the platform couldn't say.
  final String? timezone;

  /// Countries that default to imperial body measurements.
  static const imperialCountries = {'US', 'LR', 'MM'};

  bool get prefersImperial => imperialCountries.contains(countryCode);
}

/// Reads the device locale and timezone. Overridable in tests.
class RegionDetector {
  const RegionDetector();

  Future<DetectedRegion> detect() async {
    final device = PlatformDispatcher.instance.locale;
    final hasLanguage =
        device.languageCode.isNotEmpty && device.languageCode != 'und';
    final country = device.countryCode;
    final locale = !hasLanguage
        ? null
        : (country == null || country.isEmpty)
            ? device.languageCode
            : '${device.languageCode}-$country';
    String? timezone;
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final id = info.identifier.trim();
      if (id.isNotEmpty) timezone = id;
    } catch (_) {
      // Unsupported platform or tests: keep the fallback timezone.
    }
    return DetectedRegion(
      locale: locale ?? '',
      countryCode: (country == null || country.isEmpty) ? null : country,
      timezone: timezone,
    );
  }
}

final regionDetectorProvider =
    Provider<RegionDetector>((ref) => const RegionDetector());
