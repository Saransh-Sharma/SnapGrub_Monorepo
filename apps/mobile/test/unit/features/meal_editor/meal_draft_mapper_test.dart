import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/meal_editor/data/meal_draft_mapper.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';

void main() {
  test('photo analysis draft preserves confidence, provenance, and asset ids',
      () {
    final dto = _editableDraft();

    final draft = mealDraftFromEditableDto(
      result: dto,
      userId: 'user-a',
      source: MealSource.photo,
      provenanceType: 'ai_photo',
      analysisJobId: 'analysis-a',
      photoAssetId: 'asset-a',
    );

    expect(draft.source, MealSource.photo);
    expect(draft.analysisJobId, 'analysis-a');
    expect(draft.photoAssetId, 'asset-a');
    expect(draft.confidenceOverall, 0.62);
    expect(draft.analysisWarnings, contains('Review oil amount.'));
    expect(draft.items.single.sourceType, 'ai_photo');
  });

  test('multimodal draft maps to non-photo source without asset ids', () {
    final draft = mealDraftFromEditableDto(
      result: _editableDraft(),
      userId: 'user-a',
      source: MealSource.voice,
      provenanceType: 'voice_parser',
    );

    expect(draft.source, MealSource.voice);
    expect(draft.analysisJobId, isNull);
    expect(draft.photoAssetId, isNull);
    expect(draft.provenanceType, 'voice_parser');
    expect(draft.items.single.name, 'Roti');
  });

  test('a picked catalog food keeps its reference and serving', () {
    final item = mealItemFromFoodResult(_food('canonical'));

    expect(item.foodRefKind, 'canonical');
    expect(item.canonicalFoodId, 'food-1');
    expect(item.customFoodId, isNull);
    expect(item.quantity, 1);
    expect(item.unit, 'katori');
    expect(item.gramsEstimated, 180);
    expect(item.caloriesKcal, 212);
    expect(item.sourceType, 'curated');
    // A food the user chose carries no model confidence.
    expect(item.confidence, isNull);
  });

  test('a past entry from search becomes a plain item', () {
    final item = mealItemFromFoodResult(_food('recent'));

    expect(item.foodRefKind, 'manual');
    expect(item.canonicalFoodId, isNull);
    expect(item.brandedProductId, isNull);
    expect(item.customFoodId, isNull);
  });

  test('a correction sends named items with their references', () {
    final draft = MealDraft(
      userId: 'user-a',
      timezone: 'UTC',
      title: ' Lunch ',
      items: [
        MealDraftItem(
          name: 'Roti',
          foodRefKind: 'canonical',
          canonicalFoodId: 'food-roti',
          quantity: 2,
          unit: 'roti',
          caloriesKcal: 238,
        ),
        MealDraftItem(),
      ],
    );

    final json = correctionBaseDraft(draft).toJson();
    final items = json['items'] as List;

    expect(json['title'], 'Lunch');
    // The untouched placeholder row is not part of the meal.
    expect(items, hasLength(1));
    final roti = items.single as Map;
    expect(roti['position'], 0);
    expect(roti['food_ref_kind'], 'canonical');
    expect(roti['canonical_food_id'], 'food-roti');
    expect(roti['quantity'], 2);
  });
}

EditableMealDraftDto _editableDraft() {
  return EditableMealDraftDto(
    title: 'Roti and dal',
    mealType: 'lunch',
    loggedAt: DateTime.utc(2026, 5, 21, 7, 30),
    timezone: 'Asia/Kolkata',
    total: const {
      'calories_kcal': 360,
      'protein_g': 14,
      'carbs_g': 58,
      'fat_g': 8,
    },
    confidence: const AnalysisConfidenceDto(
      overall: 0.62,
      itemIdentification: 0.8,
      portionEstimation: 0.5,
      nutritionSourceQuality: 0.7,
      warnings: [
        AnalysisWarningDto(
          code: 'oil_uncertain',
          message: 'Review oil amount.',
          severity: 'medium',
        ),
      ],
    ),
    components: const [
      MealItemWriteDto(
        clientId: 'item-a',
        position: 0,
        name: 'Roti',
        quantity: 2,
        unit: 'roti',
        caloriesKcal: 240,
        proteinG: 7,
        carbsG: 44,
        fatG: 5,
        confidence: 0.68,
        sourceType: 'ai_photo',
      ),
    ],
    provenance: const {'source': 'test'},
  );
}

FoodSearchResultDto _food(String resultType) => FoodSearchResultDto(
      id: 'food-1',
      resultType: resultType,
      name: 'Dal tadka',
      servingQuantity: 1,
      servingUnit: 'katori',
      servingGrams: 180,
      caloriesKcal: 212,
      proteinG: 10.8,
      carbsG: 28.8,
      fatG: 6.1,
      confidence: .82,
      provenance: const CatalogProvenanceDto(
        sourceType: 'curated',
        sourceId: 'curated:dal_tadka',
      ),
    );
