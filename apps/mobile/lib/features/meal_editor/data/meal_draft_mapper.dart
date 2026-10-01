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

/// A meal item for a food the user picked from search. Catalog, packaged and
/// "My foods" results keep their reference; a past entry is a plain item.
MealDraftItem mealItemFromFoodResult(FoodSearchResultDto food) {
  final kind = switch (food.resultType) {
    'canonical' || 'branded' || 'custom' => food.resultType,
    _ => 'manual',
  };
  return MealDraftItem(
    name: food.name,
    foodRefKind: kind,
    canonicalFoodId: kind == 'canonical' ? food.id : null,
    brandedProductId: kind == 'branded' ? food.id : null,
    customFoodId: kind == 'custom' ? food.id : null,
    quantity: food.servingQuantity ?? 1,
    unit: food.servingUnit ?? 'serving',
    gramsEstimated: food.servingGrams,
    caloriesKcal: food.caloriesKcal,
    proteinG: food.proteinG,
    carbsG: food.carbsG,
    fatG: food.fatG,
    sourceType: food.provenance.sourceType,
    sourceId: food.provenance.sourceId,
    notes: food.brand,
  );
}

/// The draft's named items as sent with a correction, so the server can
/// return untouched items exactly as they are.
CorrectionBaseDraftDto correctionBaseDraft(MealDraft draft) {
  final items = draft.items.where((item) => item.name.trim().isNotEmpty);
  final title = draft.title.trim();
  return CorrectionBaseDraftDto(
    title: title.isEmpty ? null : title,
    items: [
      for (final (position, item) in items.indexed)
        MealItemWriteDto(
          clientId: item.clientId,
          position: position,
          name: item.name.trim(),
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
