import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/insights/domain/weekly_insight.dart';

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
}
