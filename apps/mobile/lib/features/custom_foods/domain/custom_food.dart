class CustomFood {
  const CustomFood({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.name,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.syncStatus,
    this.brand,
    this.servingQuantity,
    this.servingUnit,
    this.servingGrams,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String clientId;
  final String name;
  final String? brand;
  final double? servingQuantity;
  final String? servingUnit;
  final double? servingGrams;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String syncStatus;
  final DateTime? deletedAt;
}

class CustomFoodDraft {
  CustomFoodDraft({
    this.id,
    this.clientId,
    this.name = '',
    this.brand,
    this.servingQuantity = 1,
    this.servingUnit = 'serving',
    this.servingGrams,
    this.caloriesKcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  String? id;
  String? clientId;
  String name;
  String? brand;
  double? servingQuantity;
  String? servingUnit;
  double? servingGrams;
  double caloriesKcal;
  double proteinG;
  double carbsG;
  double fatG;

  void validate() {
    if (name.trim().isEmpty) throw ArgumentError('Food name is required.');
    if ((servingQuantity ?? 0) <= 0) throw ArgumentError('Serving quantity must be greater than zero.');
    if (caloriesKcal < 0 || proteinG < 0 || carbsG < 0 || fatG < 0) {
      throw ArgumentError('Nutrition values cannot be negative.');
    }
  }
}
