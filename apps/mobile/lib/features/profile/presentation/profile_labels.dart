import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/profile/domain/profile.dart';

/// Human copy for profile values ("en-IN" → "English (India)").
class ProfileLabels {
  const ProfileLabels._();

  static const _languages = {
    'en': 'English',
    'hi': 'Hindi',
    'bn': 'Bengali',
    'ta': 'Tamil',
    'te': 'Telugu',
    'mr': 'Marathi',
    'gu': 'Gujarati',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'pa': 'Punjabi',
    'ur': 'Urdu',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'nl': 'Dutch',
    'sv': 'Swedish',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ar': 'Arabic',
    'ru': 'Russian',
    'tr': 'Turkish',
    'id': 'Indonesian',
  };

  static const _regions = {
    'IN': 'India',
    'US': 'United States',
    'GB': 'United Kingdom',
    'CA': 'Canada',
    'AU': 'Australia',
    'NZ': 'New Zealand',
    'IE': 'Ireland',
    'SG': 'Singapore',
    'AE': 'UAE',
    'ZA': 'South Africa',
    'DE': 'Germany',
    'FR': 'France',
    'ES': 'Spain',
    'MX': 'Mexico',
    'BR': 'Brazil',
    'PT': 'Portugal',
    'IT': 'Italy',
    'NL': 'Netherlands',
    'JP': 'Japan',
    'KR': 'South Korea',
    'CN': 'China',
    'PK': 'Pakistan',
    'BD': 'Bangladesh',
    'LK': 'Sri Lanka',
    'NP': 'Nepal',
  };

  /// "en-IN" / "en_IN" → "English (India)"; unknown parts pass through.
  static String locale(String raw) {
    final parts = raw.replaceAll('_', '-').split('-');
    if (parts.isEmpty || parts.first.isEmpty) return raw;
    final lang = _languages[parts.first.toLowerCase()] ??
        parts.first.toUpperCase();
    if (parts.length < 2) return lang;
    final code = parts[1].toUpperCase();
    final region = _regions[code] ?? code;
    return '$lang ($region)';
  }

  static String units(String unitSystem) =>
      unitSystem == 'imperial' ? 'Imperial' : 'Metric';

  static String goalType(String goalType) => switch (goalType) {
        'lose' => 'Lose weight',
        'maintain' => 'Maintain weight',
        'gain' => 'Gain weight',
        _ => 'Custom targets',
      };

  /// "English (India) · Metric · Kolkata".
  static String summary(UserProfile profile) => [
        locale(profile.locale),
        units(profile.unitSystem),
        if (profile.timezone.isNotEmpty) Labels.timezone(profile.timezone),
      ].join(' · ');
}
