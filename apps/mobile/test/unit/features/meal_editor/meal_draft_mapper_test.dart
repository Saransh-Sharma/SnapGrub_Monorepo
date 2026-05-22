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
