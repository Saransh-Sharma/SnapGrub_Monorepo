import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/custom_foods/data/custom_food_remote_service.dart';
import 'package:snapgrub/features/custom_foods/domain/custom_food.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:snapgrub/offline/sync/sync_error.dart';
import 'package:uuid/uuid.dart';

final customFoodRepositoryProvider = Provider<CustomFoodRepository>((ref) {
  return CustomFoodRepository(
    db: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxRepositoryProvider),
    remote: ref.watch(customFoodRemoteServiceProvider),
  );
});

final customFoodsProvider =
    StreamProvider.family<List<CustomFood>, String>((ref, userId) {
  return ref.watch(customFoodRepositoryProvider).watchFoods(userId);
});

class CustomFoodRepository {
  CustomFoodRepository({
    required AppDatabase db,
    required OutboxRepository outbox,
    required CustomFoodRemoteService remote,
  })  : _db = db,
        _outbox = outbox,
        _remote = remote;

  final AppDatabase _db;
  final OutboxRepository _outbox;
  final CustomFoodRemoteService _remote;

  Stream<List<CustomFood>> watchFoods(String userId) {
    final query = _db.select(_db.customFoodsLocal)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<CustomFood> save(String userId, CustomFoodDraft draft) async {
    draft.validate();
    final id = draft.id ?? const Uuid().v4();
    final clientId = draft.clientId ?? const Uuid().v4();
    final now = DateTime.now().toUtc();
    final payload = _payload(
        userId: userId,
        id: id,
        clientId: clientId,
        draft: draft,
        deletedAt: null);

    await _db.into(_db.customFoodsLocal).insertOnConflictUpdate(
          CustomFoodsLocalCompanion.insert(
            id: id,
            userId: userId,
            clientId: clientId,
            name: draft.name.trim(),
            brand: Value(_blankToNull(draft.brand)),
            servingQuantity: Value(draft.servingQuantity),
            servingUnit: Value(_blankToNull(draft.servingUnit)),
            servingGrams: Value(draft.servingGrams),
            caloriesKcal: Value(draft.caloriesKcal),
            proteinG: Value(draft.proteinG),
            carbsG: Value(draft.carbsG),
            fatG: Value(draft.fatG),
            syncStatus: const Value('pending'),
            updatedAt: Value(now),
          ),
        );
    await _outbox.enqueue(
      userId: userId,
      commandType: 'custom_food.upsert',
      payload: payload,
      clientRequestId: const Uuid().v4(),
    );
    return _fromRow((await (_db.select(_db.customFoodsLocal)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle()));
  }

  Future<void> delete(CustomFood food) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.customFoodsLocal)
          ..where((tbl) => tbl.id.equals(food.id)))
        .write(
      CustomFoodsLocalCompanion(
        syncStatus: const Value('pending'),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await _outbox.enqueue(
      userId: food.userId,
      commandType: 'custom_food.delete',
      payload: {
        'user_id': food.userId,
        'client_id': food.clientId,
        'deleted_at': now.toIso8601String(),
      },
      clientRequestId: const Uuid().v4(),
    );
  }

  MealDraftItem toMealItem(CustomFood food) {
    return MealDraftItem(
      name: food.name,
      foodRefKind: 'custom',
      customFoodId: food.id,
      quantity: food.servingQuantity ?? 1,
      unit: food.servingUnit ?? 'serving',
      gramsEstimated: food.servingGrams,
      caloriesKcal: food.caloriesKcal,
      proteinG: food.proteinG,
      carbsG: food.carbsG,
      fatG: food.fatG,
      sourceType: 'custom_food',
      sourceId: food.id,
    );
  }

  Future<void> drainOutbox(String userId) async {
    if (!_remote.isConfigured) return;
    final commands = await _outbox.pendingCustomFoodCommands(userId);
    for (final command in commands) {
      try {
        final payload =
            Map<String, dynamic>.from(jsonDecode(command.payloadJson) as Map);
        final row = command.commandType == 'custom_food.delete'
            ? await _remote.softDelete(
                userId: payload['user_id'] as String,
                clientId: payload['client_id'] as String,
                deletedAt: DateTime.parse(payload['deleted_at'] as String),
                clientRequestId: command.clientRequestId,
              )
            : await _remote.upsert({
                ...payload,
                'client_request_id': command.clientRequestId,
              });
        await _cacheRemoteRow(row);
        await _outbox.markSynced(command.id);
      } catch (error) {
        if (isConflictSyncError(error)) {
          await _outbox.markConflict(command.id, error);
        } else {
          await _outbox.markFailed(command.id,
              retryable: isRetryableSyncError(error), error: error);
        }
      }
    }
  }

  Future<void> _cacheRemoteRow(Map<String, dynamic> row) async {
    await _db.into(_db.customFoodsLocal).insertOnConflictUpdate(
          CustomFoodsLocalCompanion.insert(
            id: row['id'] as String,
            userId: row['user_id'] as String,
            clientId: row['client_id'] as String,
            name: row['name'] as String,
            brand: Value(row['brand'] as String?),
            servingQuantity:
                Value((row['serving_quantity'] as num?)?.toDouble()),
            servingUnit: Value(row['serving_unit'] as String?),
            servingGrams: Value((row['serving_grams'] as num?)?.toDouble()),
            caloriesKcal:
                Value((row['calories_kcal'] as num?)?.toDouble() ?? 0),
            proteinG: Value((row['protein_g'] as num?)?.toDouble() ?? 0),
            carbsG: Value((row['carbs_g'] as num?)?.toDouble() ?? 0),
            fatG: Value((row['fat_g'] as num?)?.toDouble() ?? 0),
            syncStatus: const Value('synced'),
            deletedAt: Value(row['deleted_at'] == null
                ? null
                : DateTime.parse(row['deleted_at'] as String)),
          ),
        );
  }

  Map<String, Object?> _payload({
    required String userId,
    required String id,
    required String clientId,
    required CustomFoodDraft draft,
    required DateTime? deletedAt,
  }) {
    return {
      'id': id,
      'user_id': userId,
      'client_id': clientId,
      'name': draft.name.trim(),
      'brand': _blankToNull(draft.brand),
      'serving_quantity': draft.servingQuantity,
      'serving_unit': _blankToNull(draft.servingUnit),
      'serving_grams': draft.servingGrams,
      'calories_kcal': draft.caloriesKcal,
      'protein_g': draft.proteinG,
      'carbs_g': draft.carbsG,
      'fat_g': draft.fatG,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  CustomFood _fromRow(dynamic row) {
    return CustomFood(
      id: row.id as String,
      userId: row.userId as String,
      clientId: row.clientId as String,
      name: row.name as String,
      brand: row.brand as String?,
      servingQuantity: row.servingQuantity as double?,
      servingUnit: row.servingUnit as String?,
      servingGrams: row.servingGrams as double?,
      caloriesKcal: row.caloriesKcal as double,
      proteinG: row.proteinG as double,
      carbsG: row.carbsG as double,
      fatG: row.fatG as double,
      syncStatus: row.syncStatus as String,
      deletedAt: row.deletedAt as DateTime?,
    );
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
