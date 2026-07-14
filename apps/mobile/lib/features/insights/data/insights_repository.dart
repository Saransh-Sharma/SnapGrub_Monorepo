import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/time/user_day.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/insights/application/smart_food_suggestions.dart';
import 'package:snapgrub/features/insights/domain/smart_food_suggestion.dart';
import 'package:snapgrub/features/insights/domain/weekly_insight.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(ref.watch(appDatabaseProvider));
});

final latestWeeklyInsightsProvider =
    StreamProvider.family<List<WeeklyInsight>, String>((ref, userId) {
  return ref
      .watch(insightsRepositoryProvider)
      .watchLatestWeeklyInsights(userId);
});

final frequentFoodDefaultsProvider =
    StreamProvider.family<List<UserFoodDefault>, String>((ref, userId) {
  return ref.watch(insightsRepositoryProvider).watchFrequentDefaults(userId);
});

final smartFoodSuggestionsProvider = StreamProvider.family<
    List<SmartFoodSuggestion>, SmartFoodSuggestionsRequest>((ref, request) {
  return ref.watch(insightsRepositoryProvider).watchSmartFoodSuggestions(
        userId: request.userId,
        currentMealType: request.currentMealType,
        timezone: request.timezone,
        now: DateTime.now(),
      );
});

class SmartFoodSuggestionsRequest {
  const SmartFoodSuggestionsRequest({
    required this.userId,
    required this.currentMealType,
    required this.timezone,
  });

  final String userId;
  final MealType currentMealType;
  final String timezone;

  @override
  bool operator ==(Object other) {
    return other is SmartFoodSuggestionsRequest &&
        other.userId == userId &&
        other.currentMealType == currentMealType &&
        other.timezone == timezone;
  }

  @override
  int get hashCode => Object.hash(userId, currentMealType, timezone);
}

class InsightsRepository {
  const InsightsRepository(this._db);

  final AppDatabase _db;

  Stream<List<WeeklyInsight>> watchLatestWeeklyInsights(String userId) {
    final query = _db.select(_db.weeklyInsightsLocal)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.weekStart),
        (tbl) => OrderingTerm.asc(tbl.insightType),
      ])
      ..limit(6);
    return query.watch().map((rows) => rows.map(_insightFromRow).toList());
  }

  Stream<List<UserFoodDefault>> watchFrequentDefaults(String userId) {
    final query = _db.select(_db.userFoodDefaultsLocal)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.useCount),
        (tbl) => OrderingTerm.desc(tbl.lastUsedAt),
      ])
      ..limit(6);
    return query.watch().map((rows) => rows.map(_defaultFromRow).toList());
  }

  Stream<List<SmartFoodSuggestion>> watchSmartFoodSuggestions({
    required String userId,
    required MealType currentMealType,
    required String timezone,
    required DateTime now,
  }) {
    return _db
        .customSelect(
          'select 1',
          readsFrom: {
            _db.userFoodDefaultsLocal,
            _db.mealsLocal,
            _db.mealItemsLocal,
            _db.mealTemplatesLocal,
          },
        )
        .watch()
        .asyncMap((_) => _readSmartFoodSuggestions(
              userId: userId,
              currentMealType: currentMealType,
              timezone: timezone,
              now: now,
            ));
  }

  Future<List<SmartFoodSuggestion>> _readSmartFoodSuggestions({
    required String userId,
    required MealType currentMealType,
    required String timezone,
    required DateTime now,
  }) async {
    final defaults = await (_db.select(_db.userFoodDefaultsLocal)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.useCount),
            (tbl) => OrderingTerm.desc(tbl.lastUsedAt),
          ])
          ..limit(16))
        .get();

    final today = userDayFor(now, timezone);
    final recentCutoff = today.startUtc.subtract(const Duration(days: 90));
    final recentRows = await (_db.select(_db.mealsLocal)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.deletedAt.isNull() &
              tbl.loggedAt.isBiggerOrEqualValue(recentCutoff) &
              tbl.loggedAt.isSmallerThanValue(today.startUtc))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.loggedAt)])
          ..limit(20))
        .get();

    final templates = await (_db.select(_db.mealTemplatesLocal)
          ..where((tbl) => tbl.userId.equals(userId) & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)])
          ..limit(16))
        .get();

    final candidates = <SmartFoodSuggestion>[
      for (final row in defaults) _suggestionFromDefault(row),
      for (final row in recentRows) await _suggestionFromRecentMeal(row),
      for (final row in templates) _suggestionFromTemplate(row),
    ];

    return const SmartFoodSuggestionRanker().rank(
      suggestions: candidates.where((item) => item.items.isNotEmpty),
      currentMealType: currentMealType,
      now: now,
    );
  }

  WeeklyInsight _insightFromRow(dynamic row) {
    return WeeklyInsight(
      id: row.id as String,
      userId: row.userId as String,
      weekStart: row.weekStart as DateTime,
      insightType: row.insightType as String,
      title: row.title as String,
      summary: row.summary as String,
      payload: decodePayload(row.payloadJson as String),
      status: row.status as String,
    );
  }

  UserFoodDefault _defaultFromRow(dynamic row) {
    return UserFoodDefault(
      id: row.id as String,
      userId: row.userId as String,
      foodRefKind: row.foodRefKind as String,
      foodRefId: row.foodRefId as String,
      foodName: row.foodName as String,
      preferredQuantity: row.preferredQuantity as double,
      preferredUnit: row.preferredUnit as String,
      preferredGrams: row.preferredGrams as double?,
      caloriesKcal: row.caloriesKcal as double,
      proteinG: row.proteinG as double,
      carbsG: row.carbsG as double,
      fatG: row.fatG as double,
      useCount: row.useCount as int,
    );
  }

  SmartFoodSuggestion _suggestionFromDefault(dynamic row) {
    final item = SmartFoodSuggestionItem(
      name: row.foodName as String,
      foodRefKind: row.foodRefKind as String,
      canonicalFoodId:
          row.foodRefKind == 'canonical' ? row.foodRefId as String : null,
      brandedProductId:
          row.foodRefKind == 'branded' ? row.foodRefId as String : null,
      customFoodId:
          row.foodRefKind == 'custom' ? row.foodRefId as String : null,
      quantity: row.preferredQuantity as double,
      unit: row.preferredUnit as String,
      gramsEstimated: row.preferredGrams as double?,
      caloriesKcal: row.caloriesKcal as double,
      proteinG: row.proteinG as double,
      carbsG: row.carbsG as double,
      fatG: row.fatG as double,
    );
    final useCount = row.useCount as int;
    return SmartFoodSuggestion(
      id: 'default:${row.id}',
      title: row.foodName as String,
      subtitle: '${_formatQuantity(row.preferredQuantity as double)} '
          '${row.preferredUnit as String}',
      caloriesKcal: row.caloriesKcal as double,
      proteinG: row.proteinG as double,
      carbsG: row.carbsG as double,
      fatG: row.fatG as double,
      origin: SmartFoodSuggestionOrigin.frequentDefault,
      score: useCount.toDouble(),
      reasonLabel: 'Used $useCount times',
      lastUsedAt: row.lastUsedAt as DateTime?,
      useCount: useCount,
      items: [item],
    );
  }

  Future<SmartFoodSuggestion> _suggestionFromRecentMeal(dynamic row) async {
    final itemRows = await (_db.select(_db.mealItemsLocal)
          ..where((tbl) => tbl.mealId.equals(row.id as String))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();
    final items = [
      for (final item in itemRows)
        SmartFoodSuggestionItem(
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
          notes: item.notes,
        ),
    ];
    return SmartFoodSuggestion(
      id: 'meal:${row.id}',
      title: row.title as String,
      subtitle: '${items.length} item${items.length == 1 ? '' : 's'}',
      caloriesKcal: row.caloriesKcal as double,
      proteinG: row.proteinG as double,
      carbsG: row.carbsG as double,
      fatG: row.fatG as double,
      mealTypeHint: _parseMealType(row.mealType as String),
      origin: SmartFoodSuggestionOrigin.recentMeal,
      score: 0,
      reasonLabel: 'Logged recently',
      lastUsedAt: row.loggedAt as DateTime,
      items: items,
    );
  }

  SmartFoodSuggestion _suggestionFromTemplate(dynamic row) {
    final snapshot = Map<String, Object?>.from(
        jsonDecode(row.snapshotJson as String) as Map);
    final itemMaps = (snapshot['items'] as List? ?? const [])
        .map((raw) => Map<String, Object?>.from(raw as Map))
        .toList(growable: false);
    final items = [
      for (final item in itemMaps)
        SmartFoodSuggestionItem(
          name: item['name'] as String? ?? '',
          foodRefKind: item['food_ref_kind'] as String? ?? 'manual',
          canonicalFoodId: item['canonical_food_id'] as String?,
          brandedProductId: item['branded_product_id'] as String?,
          customFoodId: item['custom_food_id'] as String?,
          quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
          unit: item['unit'] as String? ?? 'serving',
          gramsEstimated: (item['grams_estimated'] as num?)?.toDouble(),
          caloriesKcal: (item['calories_kcal'] as num?)?.toDouble() ?? 0,
          proteinG: (item['protein_g'] as num?)?.toDouble() ?? 0,
          carbsG: (item['carbs_g'] as num?)?.toDouble() ?? 0,
          fatG: (item['fat_g'] as num?)?.toDouble() ?? 0,
          notes: item['notes'] as String?,
        ),
    ];
    final calories =
        items.fold<double>(0, (sum, item) => sum + item.caloriesKcal);
    final protein = items.fold<double>(0, (sum, item) => sum + item.proteinG);
    final carbs = items.fold<double>(0, (sum, item) => sum + item.carbsG);
    final fat = items.fold<double>(0, (sum, item) => sum + item.fatG);
    return SmartFoodSuggestion(
      id: 'template:${row.id}',
      title: row.title as String,
      subtitle: '${items.length} item${items.length == 1 ? '' : 's'}',
      caloriesKcal: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      mealTypeHint: _parseMealType(snapshot['meal_type'] as String? ?? ''),
      origin: SmartFoodSuggestionOrigin.template,
      score: 0,
      reasonLabel: 'From template',
      lastUsedAt: row.updatedAt as DateTime?,
      items: items,
    );
  }

  MealType _parseMealType(String value) {
    return MealType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MealType.unknown,
    );
  }
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}
