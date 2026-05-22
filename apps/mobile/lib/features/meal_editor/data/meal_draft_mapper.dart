import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';

MealDraft mealDraftFromEditableDto({
  required EditableMealDraftDto result,
  required String userId,
  required MealSource source,
  String? analysisJobId,
  String? photoAssetId,
  String? provenanceType,
}) {
  return MealDraft(
    userId: userId,
    timezone: result.timezone,
    title: result.title,
    mealType: _parseMealType(result.mealType),
    source: source,
    loggedAt: result.loggedAt,
    confidenceOverall: result.confidence.overall,
    provenanceType: provenanceType ?? _provenanceTypeFor(source),
    analysisJobId: source == MealSource.photo ? analysisJobId : null,
    photoAssetId: source == MealSource.photo ? photoAssetId : null,
    analysisWarnings:
        result.confidence.warnings.map((warning) => warning.message).toList(),
    items: [
      for (final item in result.components)
        MealDraftItem(
          clientId: item.clientId,
          name: item.name,
          foodRefKind: item.foodRefKind,
          canonicalFoodId: item.canonicalFoodId,
          brandedProductId: item.brandedProductId,
          customFoodId: item.customFoodId,
          quantity: item.quantity,
          unit: item.unit,
          gramsEstimated: item.gramsEstimated,
          caloriesKcal: item.caloriesKcal,
          proteinG: item.proteinG,
          carbsG: item.carbsG,
          fatG: item.fatG,
          confidence: item.confidence,
          sourceType: item.sourceType,
          sourceId: item.sourceId,
          notes: item.notes,
        ),
    ],
  );
}

MealType _parseMealType(String value) => MealType.values
    .firstWhere((type) => type.name == value, orElse: () => MealType.unknown);

String _provenanceTypeFor(MealSource source) {
  return switch (source) {
    MealSource.barcode => 'barcode',
    MealSource.text => 'text_parser',
    MealSource.voice => 'voice_parser',
    MealSource.photo => 'ai_photo',
    MealSource.manual => 'manual',
    MealSource.duplicate => 'duplicate',
  };
}
