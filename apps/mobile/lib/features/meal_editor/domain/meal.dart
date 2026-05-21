import 'package:uuid/uuid.dart';

enum MealType { breakfast, lunch, dinner, snack, unknown }

enum MealSource { photo, barcode, text, voice, manual, duplicate }

enum MealSyncStatus { synced, pending, failed }

class MealItem {
  const MealItem({
    required this.id,
    required this.mealId,
    required this.userId,
    required this.clientId,
    required this.position,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.foodRefKind = 'manual',
    this.canonicalFoodId,
    this.brandedProductId,
    this.customFoodId,
    this.gramsEstimated,
    this.confidence,
    this.sourceType,
    this.sourceId,
    this.notes,
  });

  final String id;
  final String mealId;
  final String userId;
  final String clientId;
  final int position;
  final String name;
  final String foodRefKind;
  final String? canonicalFoodId;
  final String? brandedProductId;
  final String? customFoodId;
  final double quantity;
  final String unit;
  final double? gramsEstimated;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? confidence;
  final String? sourceType;
  final String? sourceId;
  final String? notes;
}

class Meal {
  const Meal({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.title,
    required this.mealType,
    required this.source,
    required this.loggedAt,
    required this.timezone,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.revision,
    required this.items,
    required this.syncStatus,
    this.analysisJobId,
    this.confidenceOverall,
    this.provenanceType,
    this.photoAssetId,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String clientId;
  final String? analysisJobId;
  final String title;
  final MealType mealType;
  final MealSource source;
  final DateTime loggedAt;
  final String timezone;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? confidenceOverall;
  final String? provenanceType;
  final String? photoAssetId;
  final int revision;
  final List<MealItem> items;
  final MealSyncStatus syncStatus;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
}

class DailyRollup {
  const DailyRollup({
    required this.userId,
    required this.day,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealCount,
    required this.hasPhotoMeal,
  });

  const DailyRollup.empty({required String userId, required DateTime day})
      : this(
          userId: userId,
          day: day,
          caloriesKcal: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
          mealCount: 0,
          hasPhotoMeal: false,
        );

  final String userId;
  final DateTime day;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int mealCount;
  final bool hasPhotoMeal;
}

class MealDraftItem {
  MealDraftItem({
    String? id,
    String? clientId,
    this.name = '',
    this.foodRefKind = 'manual',
    this.canonicalFoodId,
    this.brandedProductId,
    this.customFoodId,
    this.quantity = 1,
    this.unit = 'serving',
    this.gramsEstimated,
    this.caloriesKcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.confidence,
    this.sourceType,
    this.sourceId,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        clientId = clientId ?? const Uuid().v4();

  final String id;
  final String clientId;
  String name;
  String foodRefKind;
  String? canonicalFoodId;
  String? brandedProductId;
  String? customFoodId;
  double quantity;
  String unit;
  double? gramsEstimated;
  double caloriesKcal;
  double proteinG;
  double carbsG;
  double fatG;
  double? confidence;
  String? sourceType;
  String? sourceId;
  String? notes;

  MealDraftItem copy() => MealDraftItem(
        id: id,
        clientId: clientId,
        name: name,
        foodRefKind: foodRefKind,
        canonicalFoodId: canonicalFoodId,
        brandedProductId: brandedProductId,
        customFoodId: customFoodId,
        quantity: quantity,
        unit: unit,
        gramsEstimated: gramsEstimated,
        caloriesKcal: caloriesKcal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        confidence: confidence,
        sourceType: sourceType,
        sourceId: sourceId,
        notes: notes,
      );
}

class MealDraft {
  MealDraft({
    required this.userId,
    required this.timezone,
    String? id,
    String? clientId,
    this.title = '',
    this.mealType = MealType.unknown,
    this.source = MealSource.manual,
    DateTime? loggedAt,
    List<MealDraftItem>? items,
    this.expectedRevision,
    this.confidenceOverall,
    this.provenanceType,
    this.analysisJobId,
    this.photoAssetId,
    List<String>? analysisWarnings,
  })  : id = id ?? const Uuid().v4(),
        clientId = clientId ?? const Uuid().v4(),
        loggedAt = loggedAt ?? DateTime.now(),
        items = items ?? [MealDraftItem()],
        analysisWarnings = analysisWarnings ?? const [];

  final String id;
  final String userId;
  final String clientId;
  String title;
  MealType mealType;
  MealSource source;
  DateTime loggedAt;
  String timezone;
  List<MealDraftItem> items;
  int? expectedRevision;
  double? confidenceOverall;
  String? provenanceType;
  String? analysisJobId;
  String? photoAssetId;
  final List<String> analysisWarnings;

  double get caloriesKcal => items.fold(0, (sum, item) => sum + item.caloriesKcal);
  double get proteinG => items.fold(0, (sum, item) => sum + item.proteinG);
  double get carbsG => items.fold(0, (sum, item) => sum + item.carbsG);
  double get fatG => items.fold(0, (sum, item) => sum + item.fatG);

  void validate() {
    if (title.trim().isEmpty) throw ArgumentError('Meal title is required.');
    if (items.isEmpty) throw ArgumentError('Add at least one item.');
    for (final item in items) {
      if (item.name.trim().isEmpty) throw ArgumentError('Item name is required.');
      if (item.quantity <= 0) throw ArgumentError('Quantity must be greater than zero.');
      if (item.caloriesKcal < 0 || item.proteinG < 0 || item.carbsG < 0 || item.fatG < 0) {
        throw ArgumentError('Nutrition values cannot be negative.');
      }
    }
  }
}
