import 'package:snapgrub/features/profile/domain/body_measurement.dart';

class OnboardingDraft {
  const OnboardingDraft({
    this.displayName = '',
    this.goalType = 'lose',
    this.unitSystem = 'metric',
    this.locale = 'en-IN',
    this.timezone = 'Asia/Kolkata',
    this.countryCode = 'IN',
    this.cuisinePreferences = const ['Indian'],
    this.weightKg,
    this.targetWeightKg,
    this.heightCm,
    this.activityLevel = 'moderate',
    this.notificationPreference = false,
    this.caloriesKcal = 1900,
    this.proteinG = 130,
    this.carbsG = 190,
    this.fatG = 60,
    this.cameraPrimerSeen = false,
  });

  final String displayName;
  final String goalType;
  final String unitSystem;
  final String locale;
  final String timezone;
  final String countryCode;
  final List<String> cuisinePreferences;
  final double? weightKg;
  final double? targetWeightKg;
  final double? heightCm;
  final String activityLevel;
  final bool notificationPreference;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final bool cameraPrimerSeen;

  BodyMeasurement? get bodyMeasurement {
    if (weightKg == null) return null;
    return BodyMeasurement(
      measuredAt: DateTime.now(),
      weightKg: weightKg,
      source: 'onboarding',
    );
  }

  OnboardingDraft copyWith({
    String? displayName,
    String? goalType,
    String? unitSystem,
    String? locale,
    String? timezone,
    String? countryCode,
    List<String>? cuisinePreferences,
    double? weightKg,
    double? targetWeightKg,
    double? heightCm,
    String? activityLevel,
    bool? notificationPreference,
    double? caloriesKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    bool? cameraPrimerSeen,
  }) {
    return OnboardingDraft(
      displayName: displayName ?? this.displayName,
      goalType: goalType ?? this.goalType,
      unitSystem: unitSystem ?? this.unitSystem,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      countryCode: countryCode ?? this.countryCode,
      cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      notificationPreference:
          notificationPreference ?? this.notificationPreference,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      cameraPrimerSeen: cameraPrimerSeen ?? this.cameraPrimerSeen,
    );
  }

  void validate() {
    if (!['lose', 'maintain', 'gain', 'custom'].contains(goalType)) {
      throw ArgumentError('Choose a valid goal.');
    }
    if (!['metric', 'imperial'].contains(unitSystem)) {
      throw ArgumentError('Choose metric or imperial units.');
    }
    _range(caloriesKcal, 500, 6000, 'Calories');
    _range(proteinG, 0, 500, 'Protein');
    _range(carbsG, 0, 800, 'Carbs');
    _range(fatG, 0, 400, 'Fat');
    if (weightKg != null) {
      _range(weightKg!, 20, 400, 'Weight');
    }
    if (targetWeightKg != null) {
      _range(targetWeightKg!, 20, 400, 'Target weight');
    }
    if (heightCm != null) {
      _range(heightCm!, 80, 260, 'Height');
    }
  }

  static void _range(double value, double min, double max, String label) {
    if (value < min || value > max) {
      throw ArgumentError('$label is outside the supported range.');
    }
  }
}
