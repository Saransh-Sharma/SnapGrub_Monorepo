class UserProfile {
  const UserProfile({
    required this.id,
    required this.locale,
    required this.timezone,
    required this.unitSystem,
    required this.cuisinePreferences,
    required this.cloudMediaStorage,
    required this.saveOriginalPhotos,
    required this.aiImprovementConsent,
    this.displayName,
    this.countryCode,
    this.onboardingCompletedAt,
  });

  final String id;
  final String? displayName;
  final String locale;
  final String timezone;
  final String unitSystem;
  final String? countryCode;
  final List<String> cuisinePreferences;
  final bool cloudMediaStorage;
  final bool saveOriginalPhotos;
  final bool aiImprovementConsent;
  final DateTime? onboardingCompletedAt;

  bool get hasCompletedOnboarding => onboardingCompletedAt != null;
}
