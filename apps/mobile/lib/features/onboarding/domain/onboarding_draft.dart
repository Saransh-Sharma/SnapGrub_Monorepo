import 'package:snapgrub/features/onboarding/domain/plan_calculator.dart';
import 'package:snapgrub/features/profile/domain/body_measurement.dart';

/// Everything collected during onboarding.
///
/// Canonical units only: weights in kg, height in cm. [unitSystem] is purely
/// a display preference, so switching it never changes an entered value.
///
/// [sex] and [birthYear] are used client-side for the plan calculation only.
/// The profile schema and API contracts have no fields for them, so they are
/// never persisted; only the resulting targets are saved.
class OnboardingDraft {
  const OnboardingDraft({
    this.displayName = '',
    this.goalType = 'lose',
    this.unitSystem = 'metric',
    // Fallbacks only: the controller replaces these with the device locale
    // and timezone as soon as onboarding starts.
    this.locale = 'en-IN',
    this.timezone = 'Asia/Kolkata',
    this.countryCode = 'IN',
    this.cuisinePreferences = const [],
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
    this.sex,
    this.birthYear,
    this.paceKgPerWeek = .5,
    this.mealReminders = const [],
    this.targetsAdjusted = false,
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

  /// Client-side only (see class docs).
  final BiologicalSex? sex;

  /// Client-side only (see class docs).
  final int? birthYear;

  /// Absolute weekly rate of change the user asked for (kg / week).
  final double paceKgPerWeek;

  /// Meal slots the user wants a nudge for (`breakfast`, `lunch`, ...).
  final List<String> mealReminders;

  /// True once the user hand-edited the targets on the plan reveal. Cleared
  /// whenever an input to the plan changes, so the plan is recalculated.
  final bool targetsAdjusted;

  static const goalTypes = ['lose', 'maintain', 'gain', 'custom'];

  bool get isMetric => unitSystem != 'imperial';

  /// Lose and gain have a target weight and a pace; maintain / custom don't.
  bool get needsTargetWeight => goalType == 'lose' || goalType == 'gain';

  /// Goal used by the calculator. "custom" starts from maintenance.
  GoalType get planGoal => switch (goalType) {
        'lose' => GoalType.lose,
        'gain' => GoalType.gain,
        _ => GoalType.maintain,
      };

  String get firstName {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  int? ageYears({DateTime? now}) {
    final year = birthYear;
    if (year == null) return null;
    return (now ?? DateTime.now()).year - year;
  }

  /// Calculator input, or null until weight and height are known.
  PlanInput? planInput({DateTime? now}) {
    final weight = weightKg;
    final height = heightCm;
    if (weight == null || height == null) return null;
    return PlanInput(
      weightKg: weight,
      heightCm: height,
      goal: planGoal,
      targetWeightKg: needsTargetWeight ? targetWeightKg : null,
      ageYears: ageYears(now: now),
      sex: sex ?? BiologicalSex.unspecified,
      activity: ActivityLevel.fromStorage(activityLevel),
      paceKgPerWeek: paceKgPerWeek,
    );
  }

  NutritionPlan? plan({DateTime? today}) {
    final input = planInput(now: today);
    if (input == null) return null;
    return PlanCalculator.calculate(input, today: today);
  }

  /// Copies the calculated targets into the draft, unless the user adjusted
  /// them by hand.
  OnboardingDraft withPlanTargets({DateTime? today}) {
    if (targetsAdjusted) return this;
    final computed = plan(today: today);
    if (computed == null) return this;
    return copyWith(
      caloriesKcal: computed.caloriesKcal,
      proteinG: computed.proteinG,
      carbsG: computed.carbsG,
      fatG: computed.fatG,
    );
  }

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
    bool clearTargetWeight = false,
    double? heightCm,
    String? activityLevel,
    bool? notificationPreference,
    double? caloriesKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    bool? cameraPrimerSeen,
    BiologicalSex? sex,
    int? birthYear,
    double? paceKgPerWeek,
    List<String>? mealReminders,
    bool? targetsAdjusted,
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
      targetWeightKg:
          clearTargetWeight ? null : (targetWeightKg ?? this.targetWeightKg),
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      notificationPreference:
          notificationPreference ?? this.notificationPreference,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      cameraPrimerSeen: cameraPrimerSeen ?? this.cameraPrimerSeen,
      sex: sex ?? this.sex,
      birthYear: birthYear ?? this.birthYear,
      paceKgPerWeek: paceKgPerWeek ?? this.paceKgPerWeek,
      mealReminders: mealReminders ?? this.mealReminders,
      targetsAdjusted: targetsAdjusted ?? this.targetsAdjusted,
    );
  }

  void validate() {
    if (!goalTypes.contains(goalType)) {
      throw ArgumentError('Choose a goal.');
    }
    if (!['metric', 'imperial'].contains(unitSystem)) {
      throw ArgumentError('Choose metric or imperial.');
    }
    _range(caloriesKcal, 500, 6000, 'Calories');
    _range(proteinG, 0, 500, 'Protein');
    _range(carbsG, 0, 800, 'Carbs');
    _range(fatG, 0, 400, 'Fat');
    if (weightKg != null) {
      _range(weightKg!, 20, 400, 'Weight');
    }
    if (targetWeightKg != null) {
      _range(targetWeightKg!, 20, 400, 'Goal weight');
    }
    if (heightCm != null) {
      _range(heightCm!, 80, 260, 'Height');
    }
  }

  static void _range(double value, double min, double max, String label) {
    if (value < min || value > max) {
      throw ArgumentError('$label is out of range.');
    }
  }
}
