import 'dart:convert';

class WeeklyInsight {
  const WeeklyInsight({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.insightType,
    required this.title,
    required this.summary,
    required this.payload,
    required this.status,
  });

  final String id;
  final String userId;
  final DateTime weekStart;
  final String insightType;
  final String title;
  final String summary;
  final Map<String, Object?> payload;
  final String status;

  bool get hasEnoughData => status == 'ready';
}

class UserFoodDefault {
  const UserFoodDefault({
    required this.id,
    required this.userId,
    required this.foodRefKind,
    required this.foodRefId,
    required this.foodName,
    required this.preferredQuantity,
    required this.preferredUnit,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.useCount,
    this.preferredGrams,
  });

  final String id;
  final String userId;
  final String foodRefKind;
  final String foodRefId;
  final String foodName;
  final double preferredQuantity;
  final String preferredUnit;
  final double? preferredGrams;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int useCount;
}

Map<String, Object?> decodePayload(String value) {
  return Map<String, Object?>.from(jsonDecode(value) as Map);
}
