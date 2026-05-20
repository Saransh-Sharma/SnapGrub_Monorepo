class NutritionGoal {
  const NutritionGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.startsOn,
    required this.isActive,
    this.fiberG,
    this.endsOn,
  });

  final String id;
  final String userId;
  final String goalType;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final DateTime startsOn;
  final DateTime? endsOn;
  final bool isActive;
}
