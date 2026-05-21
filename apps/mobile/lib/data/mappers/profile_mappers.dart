import 'dart:convert';

import 'package:snapgrub/features/profile/domain/nutrition_goal.dart';
import 'package:snapgrub/features/profile/domain/profile.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';

UserProfile profileFromDto(ProfileDto dto) {
  return UserProfile(
    id: dto.id,
    displayName: dto.displayName,
    locale: dto.locale,
    timezone: dto.timezone,
    unitSystem: dto.unitSystem.name,
    countryCode: dto.countryCode,
    cuisinePreferences: dto.cuisinePreferences,
    cloudMediaStorage: dto.cloudMediaStorage,
    saveOriginalPhotos: dto.saveOriginalPhotos,
    aiImprovementConsent: dto.aiImprovementConsent,
    onboardingCompletedAt: dto.onboardingCompletedAt,
  );
}

NutritionGoal goalFromDto(NutritionGoalDto dto) {
  return NutritionGoal(
    id: dto.id,
    userId: dto.userId,
    goalType: dto.goalType.name,
    caloriesKcal: dto.caloriesKcal,
    proteinG: dto.proteinG,
    carbsG: dto.carbsG,
    fatG: dto.fatG,
    fiberG: dto.fiberG,
    startsOn: dto.startsOn,
    endsOn: dto.endsOn,
    isActive: dto.isActive,
  );
}

List<String> decodeStringList(String json) {
  return List<String>.from(jsonDecode(json) as List? ?? const []);
}

String encodeStringList(List<String> values) => jsonEncode(values);
