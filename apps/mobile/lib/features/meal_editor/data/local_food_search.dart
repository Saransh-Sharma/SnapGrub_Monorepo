import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';

final localFoodSearchProvider = Provider<LocalFoodSearch>((ref) {
  return LocalFoodSearch(ref.watch(appDatabaseProvider));
});

/// Searches the foods already on this phone: "My foods", learned defaults
/// and past meal items. Stands in for the catalog when it cannot be reached.
class LocalFoodSearch {
  const LocalFoodSearch(this._db);

  final AppDatabase _db;

  Future<List<FoodSearchResultDto>> search({
    required String userId,
    required String query,
    int limit = 15,
  }) async {
    final needle = query.trim().toLowerCase().replaceAll(RegExp('[%_]'), '');
    if (needle.isEmpty) return const [];
    final pattern = '%$needle%';

    final custom = await (_db.select(_db.customFoodsLocal)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.deletedAt.isNull() &
              (tbl.name.lower().like(pattern) |
                  tbl.brand.lower().like(pattern)))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)])
          ..limit(limit))
        .get();
    final defaults = await (_db.select(_db.userFoodDefaultsLocal)
          ..where((tbl) =>
              tbl.userId.equals(userId) & tbl.foodName.lower().like(pattern))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.useCount)])
          ..limit(limit))
        .get();
    final recent = await (_db.select(_db.mealItemsLocal)
          ..where((tbl) =>
              tbl.userId.equals(userId) & tbl.name.lower().like(pattern))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(limit * 4))
        .get();

    // One row per food name: a learned default beats a single past entry.
    final seen = <String>{};
    final results = <FoodSearchResultDto>[
      for (final food in custom)
        FoodSearchResultDto(
          id: food.id,
          resultType: 'custom',
          name: food.name,
          brand: food.brand,
          servingQuantity: food.servingQuantity,
          servingUnit: food.servingUnit,
          servingGrams: food.servingGrams,
          caloriesKcal: food.caloriesKcal,
          proteinG: food.proteinG,
          carbsG: food.carbsG,
          fatG: food.fatG,
          confidence: 1,
          provenance: CatalogProvenanceDto(
            sourceType: 'custom_food',
            sourceId: food.id,
          ),
        ),
      for (final food in defaults)
        if (seen.add(food.foodName.trim().toLowerCase()))
          FoodSearchResultDto(
            id: 'default:${food.foodRefKind}:${food.foodRefId}',
            resultType: 'recent',
            name: food.foodName,
            servingQuantity: food.preferredQuantity,
            servingUnit: food.preferredUnit,
            servingGrams: food.preferredGrams,
            caloriesKcal: food.caloriesKcal,
            proteinG: food.proteinG,
            carbsG: food.carbsG,
            fatG: food.fatG,
            confidence: .86,
            provenance: CatalogProvenanceDto(
              sourceType: 'user_food_default',
              sourceId: food.id,
            ),
          ),
      for (final item in recent)
        if (seen.add(item.name.trim().toLowerCase()))
          FoodSearchResultDto(
            id: 'recent:${item.name}',
            resultType: 'recent',
            name: item.name,
            servingQuantity: item.quantity,
            servingUnit: item.unit,
            servingGrams: item.gramsEstimated,
            caloriesKcal: item.caloriesKcal,
            proteinG: item.proteinG,
            carbsG: item.carbsG,
            fatG: item.fatG,
            confidence: .7,
            provenance: CatalogProvenanceDto(
              sourceType: item.sourceType ?? 'recent_meal_item',
              sourceId: item.sourceId,
            ),
          ),
    ];
    return results.take(limit).toList();
  }
}
