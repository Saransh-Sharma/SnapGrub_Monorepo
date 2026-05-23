import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/time/user_day.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/meal_editor/data/meal_remote_service.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart' as domain;
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:snapgrub/offline/sync/sync_error.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';
import 'package:uuid/uuid.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(
    db: ref.watch(appDatabaseProvider),
    remote: ref.watch(mealRemoteServiceProvider),
    outbox: ref.watch(outboxRepositoryProvider),
  );
});

class MealRepository {
  MealRepository({
    required AppDatabase db,
    required MealRemoteService remote,
    required OutboxRepository outbox,
  })  : _db = db,
        _remote = remote,
        _outbox = outbox;

  final AppDatabase _db;
  final MealRemoteService _remote;
  final OutboxRepository _outbox;

  domain.MealDraft newManualDraft({
    required String userId,
    required String timezone,
  }) {
    return domain.MealDraft(
      userId: userId,
      timezone: timezone,
      title: '',
      mealType: _mealTypeForNow(DateTime.now()),
      source: domain.MealSource.manual,
    );
  }

  Stream<List<domain.Meal>> watchMealsForDay(
    String userId,
    DateTime day, {
    required String timezone,
  }) {
    final window = userDayWindow(day, timezone);
    final query = _db.select(_db.mealsLocal)
      ..where((tbl) =>
          tbl.userId.equals(userId) &
          tbl.deletedAt.isNull() &
          tbl.loggedAt.isBiggerOrEqualValue(window.startUtc) &
          tbl.loggedAt.isSmallerThanValue(window.endUtc))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.loggedAt)]);
    return query.watch().asyncMap((rows) async {
      final meals = <domain.Meal>[];
      for (final row in rows) {
        meals.add(await _mealFromRow(row));
      }
      return meals;
    });
  }

  Stream<domain.DailyRollup> watchRollup(String userId, DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final query = _db.select(_db.dailyRollupsLocal)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.day.equals(normalized));
    return query.watchSingleOrNull().map((row) {
      if (row == null) {
        return domain.DailyRollup.empty(userId: userId, day: normalized);
      }
      return _rollupFromRow(row);
    });
  }

  Future<domain.Meal?> getMeal(String id) async {
    final row = await (_db.select(_db.mealsLocal)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mealFromRow(row);
  }

  Future<domain.Meal> saveDraft(domain.MealDraft draft) async {
    draft.validate();
    final now = DateTime.now().toUtc();
    final requestId = const Uuid().v4();
    final existing = await (_db.select(_db.mealsLocal)
          ..where((tbl) => tbl.id.equals(draft.id)))
        .getSingleOrNull();
    final commandType = existing == null ? 'meal.create' : 'meal.update';

    await _db.transaction(() async {
      await _upsertDraftLocal(draft,
          status: domain.MealSyncStatus.pending, updatedAt: now);
      await _replaceItemsLocal(draft, updatedAt: now);
      await _insertCorrectionEvent(
        id: const Uuid().v4(),
        userId: draft.userId,
        mealId: draft.id,
        eventType: existing == null ? 'meal_created' : 'meal_updated',
        afterValue: _draftPayload(draft),
      );
      await _refreshLocalRollup(draft.userId, draft.loggedAt, draft.timezone);
    });

    await _outbox.enqueue(
      userId: draft.userId,
      commandType: commandType,
      payload: _requestFromDraft(requestId, draft).toJson()
        ..['meal_id'] = draft.id,
      clientRequestId: requestId,
    );
    return (await getMeal(draft.id))!;
  }

  Future<domain.Meal> duplicateMeal(domain.Meal meal) async {
    final draft = domain.MealDraft(
      userId: meal.userId,
      timezone: meal.timezone,
      title: '${meal.title} copy',
      mealType: meal.mealType,
      source: domain.MealSource.duplicate,
      loggedAt: DateTime.now(),
      items: meal.items
          .map(
            (item) => domain.MealDraftItem(
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
          )
          .toList(),
    );
    return saveDraft(draft);
  }

  Future<void> deleteMeal(domain.Meal meal) async {
    final requestId = const Uuid().v4();
    final now = DateTime.now().toUtc();
    await (_db.update(_db.mealsLocal)..where((tbl) => tbl.id.equals(meal.id)))
        .write(
      MealsLocalCompanion(
        deletedAt: Value(now),
        syncStatus: const Value('pending'),
        updatedAt: Value(now),
      ),
    );
    await _insertCorrectionEvent(
      id: const Uuid().v4(),
      userId: meal.userId,
      mealId: meal.id,
      eventType: 'meal_deleted',
      beforeValue: {'id': meal.id, 'title': meal.title},
    );
    await _refreshLocalRollup(meal.userId, meal.loggedAt, meal.timezone);
    await _outbox.enqueue(
      userId: meal.userId,
      commandType: 'meal.delete',
      payload: {
        'meal_id': meal.id,
        'client_request_id': requestId,
        'expected_revision': meal.revision,
      },
      clientRequestId: requestId,
    );
  }

  Future<void> drainMealOutbox(String userId) async {
    if (!_remote.isConfigured) return;
    final pending = await _outbox.pendingMealCommands(userId);
    for (final command in pending) {
      try {
        final payload =
            Map<String, dynamic>.from(jsonDecode(command.payloadJson) as Map);
        if (command.commandType == 'meal.delete') {
          final response = await _remote.deleteMeal(
            mealId: payload['meal_id'] as String,
            clientRequestId: command.clientRequestId,
            expectedRevision: payload['expected_revision'] as int?,
          );
          await cacheMealResponse(response);
        } else {
          final request = _requestFromPayload(payload, command.clientRequestId);
          final mealId = payload['meal_id'] as String?;
          final response = command.commandType == 'meal.create'
              ? await _remote.createMeal(
                  clientRequestId: command.clientRequestId, request: request)
              : await _remote.updateMeal(
                  mealId: mealId!,
                  clientRequestId: command.clientRequestId,
                  request: request,
                );
          await cacheMealResponse(response);
        }
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

  Future<void> cacheMealResponse(MealWriteResponseDto response) async {
    await _db.transaction(() async {
      await _cacheMealDto(response.meal,
          syncStatus: domain.MealSyncStatus.synced);
      await _cacheRollupDto(response.dailyRollup);
      for (final event in response.correctionEvents) {
        await _cacheCorrectionEventDto(event);
      }
    });
  }

  Future<void> _cacheMealDto(MealDto meal,
      {required domain.MealSyncStatus syncStatus}) async {
    await _db.into(_db.mealsLocal).insertOnConflictUpdate(
          MealsLocalCompanion.insert(
            id: meal.id,
            userId: meal.userId,
            clientId: meal.clientId,
            analysisJobId: Value(meal.analysisJobId),
            title: meal.title,
            mealType: meal.mealType,
            source: meal.source,
            loggedAt: meal.loggedAt,
            timezone: meal.timezone,
            caloriesKcal: Value(meal.caloriesKcal),
            proteinG: Value(meal.proteinG),
            carbsG: Value(meal.carbsG),
            fatG: Value(meal.fatG),
            confidenceOverall: Value(meal.confidenceOverall),
            provenanceType: Value(meal.provenanceType),
            photoAssetId: Value(meal.photoAssetId),
            revision: Value(meal.revision),
            syncStatus: Value(syncStatus.name),
            deletedAt: Value(meal.deletedAt),
          ),
        );
    await (_db.delete(_db.mealItemsLocal)
          ..where((tbl) => tbl.mealId.equals(meal.id)))
        .go();
    for (final item in meal.items) {
      await _db.into(_db.mealItemsLocal).insert(
            MealItemsLocalCompanion.insert(
              id: item.id,
              mealId: item.mealId,
              userId: item.userId,
              clientId: item.clientId,
              position: item.position,
              name: item.name,
              foodRefKind: Value(item.foodRefKind),
              canonicalFoodId: Value(item.canonicalFoodId),
              brandedProductId: Value(item.brandedProductId),
              customFoodId: Value(item.customFoodId),
              quantity: item.quantity,
              unit: item.unit,
              gramsEstimated: Value(item.gramsEstimated),
              caloriesKcal: Value(item.caloriesKcal),
              proteinG: Value(item.proteinG),
              carbsG: Value(item.carbsG),
              fatG: Value(item.fatG),
              confidence: Value(item.confidence),
              sourceType: Value(item.sourceType),
              sourceId: Value(item.sourceId),
              notes: Value(item.notes),
            ),
          );
    }
  }

  Future<void> _cacheRollupDto(DailyRollupDto rollup) async {
    await _db.into(_db.dailyRollupsLocal).insertOnConflictUpdate(
          DailyRollupsLocalCompanion.insert(
            userId: rollup.userId,
            day: _dateOnly(rollup.day),
            caloriesKcal: Value(rollup.caloriesKcal),
            proteinG: Value(rollup.proteinG),
            carbsG: Value(rollup.carbsG),
            fatG: Value(rollup.fatG),
            mealCount: Value(rollup.mealCount),
            hasPhotoMeal: Value(rollup.hasPhotoMeal),
            updatedAt: Value(rollup.updatedAt),
          ),
        );
  }

  Future<void> _upsertDraftLocal(
    domain.MealDraft draft, {
    required domain.MealSyncStatus status,
    required DateTime updatedAt,
  }) async {
    await _db.into(_db.mealsLocal).insertOnConflictUpdate(
          MealsLocalCompanion.insert(
            id: draft.id,
            userId: draft.userId,
            clientId: draft.clientId,
            analysisJobId: Value(draft.analysisJobId),
            title: draft.title.trim(),
            mealType: draft.mealType.name,
            source: draft.source.name,
            loggedAt: draft.loggedAt,
            timezone: draft.timezone,
            caloriesKcal: Value(draft.caloriesKcal),
            proteinG: Value(draft.proteinG),
            carbsG: Value(draft.carbsG),
            fatG: Value(draft.fatG),
            confidenceOverall: Value(draft.confidenceOverall),
            provenanceType: Value(draft.provenanceType),
            photoAssetId: Value(draft.photoAssetId),
            revision: Value(draft.expectedRevision ?? 1),
            syncStatus: Value(status.name),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<void> _replaceItemsLocal(domain.MealDraft draft,
      {required DateTime updatedAt}) async {
    await (_db.delete(_db.mealItemsLocal)
          ..where((tbl) => tbl.mealId.equals(draft.id)))
        .go();
    for (var i = 0; i < draft.items.length; i++) {
      final item = draft.items[i];
      await _db.into(_db.mealItemsLocal).insert(
            MealItemsLocalCompanion.insert(
              id: item.id,
              mealId: draft.id,
              userId: draft.userId,
              clientId: item.clientId,
              position: i,
              name: item.name.trim(),
              foodRefKind: Value(item.foodRefKind),
              canonicalFoodId: Value(item.canonicalFoodId),
              brandedProductId: Value(item.brandedProductId),
              customFoodId: Value(item.customFoodId),
              quantity: item.quantity,
              unit: item.unit.trim(),
              gramsEstimated: Value(item.gramsEstimated),
              caloriesKcal: Value(item.caloriesKcal),
              proteinG: Value(item.proteinG),
              carbsG: Value(item.carbsG),
              fatG: Value(item.fatG),
              confidence: Value(item.confidence),
              sourceType: Value(item.sourceType),
              sourceId: Value(item.sourceId),
              notes: Value(item.notes),
              updatedAt: Value(updatedAt),
            ),
          );
    }
  }

  Future<void> _refreshLocalRollup(
      String userId, DateTime loggedAt, String timezone) async {
    final window = userDayFor(loggedAt, timezone);
    final rows = await (_db.select(_db.mealsLocal)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.deletedAt.isNull() &
              tbl.loggedAt.isBiggerOrEqualValue(window.startUtc) &
              tbl.loggedAt.isSmallerThanValue(window.endUtc)))
        .get();
    final calories = rows.fold<double>(0, (sum, row) => sum + row.caloriesKcal);
    final protein = rows.fold<double>(0, (sum, row) => sum + row.proteinG);
    final carbs = rows.fold<double>(0, (sum, row) => sum + row.carbsG);
    final fat = rows.fold<double>(0, (sum, row) => sum + row.fatG);
    await _db.into(_db.dailyRollupsLocal).insertOnConflictUpdate(
          DailyRollupsLocalCompanion.insert(
            userId: userId,
            day: window.day,
            caloriesKcal: Value(calories),
            proteinG: Value(protein),
            carbsG: Value(carbs),
            fatG: Value(fat),
            mealCount: Value(rows.length),
            hasPhotoMeal: Value(
                rows.any((row) => row.source == domain.MealSource.photo.name)),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<domain.Meal> _mealFromRow(dynamic row) async {
    final itemRows = await (_db.select(_db.mealItemsLocal)
          ..where((tbl) => tbl.mealId.equals(row.id as String))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();
    return domain.Meal(
      id: row.id as String,
      userId: row.userId as String,
      clientId: row.clientId as String,
      analysisJobId: row.analysisJobId as String?,
      title: row.title as String,
      mealType: _parseMealType(row.mealType as String),
      source: _parseMealSource(row.source as String),
      loggedAt: row.loggedAt as DateTime,
      timezone: row.timezone as String,
      caloriesKcal: row.caloriesKcal as double,
      proteinG: row.proteinG as double,
      carbsG: row.carbsG as double,
      fatG: row.fatG as double,
      confidenceOverall: row.confidenceOverall as double?,
      provenanceType: row.provenanceType as String?,
      photoAssetId: row.photoAssetId as String?,
      revision: row.revision as int,
      syncStatus: _parseSyncStatus(row.syncStatus as String),
      deletedAt: row.deletedAt as DateTime?,
      items: itemRows.map((item) {
        return domain.MealItem(
          id: item.id,
          mealId: item.mealId,
          userId: item.userId,
          clientId: item.clientId,
          position: item.position,
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
        );
      }).toList(),
    );
  }

  domain.DailyRollup _rollupFromRow(dynamic row) {
    return domain.DailyRollup(
      userId: row.userId as String,
      day: row.day as DateTime,
      caloriesKcal: row.caloriesKcal as double,
      proteinG: row.proteinG as double,
      carbsG: row.carbsG as double,
      fatG: row.fatG as double,
      mealCount: row.mealCount as int,
      hasPhotoMeal: row.hasPhotoMeal as bool,
    );
  }

  MealWriteRequestDto _requestFromDraft(
      String requestId, domain.MealDraft draft) {
    return MealWriteRequestDto(
      clientRequestId: requestId,
      id: draft.id,
      clientId: draft.clientId,
      expectedRevision: draft.expectedRevision,
      title: draft.title.trim(),
      mealType: draft.mealType.name,
      source: draft.source.name,
      loggedAt: draft.loggedAt,
      timezone: draft.timezone,
      confidenceOverall: draft.confidenceOverall,
      provenanceType: draft.provenanceType,
      analysisJobId: draft.analysisJobId,
      photoAssetId: draft.photoAssetId,
      items: [
        for (var i = 0; i < draft.items.length; i++)
          MealItemWriteDto(
            clientId: draft.items[i].clientId,
            position: i,
            name: draft.items[i].name.trim(),
            foodRefKind: draft.items[i].foodRefKind,
            canonicalFoodId: draft.items[i].canonicalFoodId,
            brandedProductId: draft.items[i].brandedProductId,
            customFoodId: draft.items[i].customFoodId,
            quantity: draft.items[i].quantity,
            unit: draft.items[i].unit.trim(),
            gramsEstimated: draft.items[i].gramsEstimated,
            caloriesKcal: draft.items[i].caloriesKcal,
            proteinG: draft.items[i].proteinG,
            carbsG: draft.items[i].carbsG,
            fatG: draft.items[i].fatG,
            confidence: draft.items[i].confidence,
            sourceType: draft.items[i].sourceType,
            sourceId: draft.items[i].sourceId,
            notes: draft.items[i].notes,
          ),
      ],
    );
  }

  MealWriteRequestDto _requestFromPayload(
      Map<String, dynamic> payload, String fallbackRequestId) {
    return MealWriteRequestDto(
      clientRequestId:
          payload['client_request_id'] as String? ?? fallbackRequestId,
      id: payload['id'] as String?,
      clientId: payload['client_id'] as String,
      expectedRevision: payload['expected_revision'] as int?,
      title: payload['title'] as String,
      mealType: payload['meal_type'] as String,
      source: payload['source'] as String,
      loggedAt: DateTime.parse(payload['logged_at'] as String),
      timezone: payload['timezone'] as String,
      confidenceOverall: (payload['confidence_overall'] as num?)?.toDouble(),
      provenanceType: payload['provenance_type'] as String?,
      analysisJobId: payload['analysis_job_id'] as String?,
      photoAssetId: payload['photo_asset_id'] as String?,
      items: (payload['items'] as List).map((raw) {
        final item = Map<String, dynamic>.from(raw as Map);
        return MealItemWriteDto(
          clientId: item['client_id'] as String,
          position: item['position'] as int,
          name: item['name'] as String,
          foodRefKind: item['food_ref_kind'] as String? ?? 'manual',
          canonicalFoodId: item['canonical_food_id'] as String?,
          brandedProductId: item['branded_product_id'] as String?,
          customFoodId: item['custom_food_id'] as String?,
          quantity: (item['quantity'] as num).toDouble(),
          unit: item['unit'] as String,
          gramsEstimated: (item['grams_estimated'] as num?)?.toDouble(),
          caloriesKcal: (item['calories_kcal'] as num).toDouble(),
          proteinG: (item['protein_g'] as num).toDouble(),
          carbsG: (item['carbs_g'] as num).toDouble(),
          fatG: (item['fat_g'] as num).toDouble(),
          confidence: (item['confidence'] as num?)?.toDouble(),
          sourceType: item['source_type'] as String?,
          sourceId: item['source_id'] as String?,
          notes: item['notes'] as String?,
        );
      }).toList(),
    );
  }

  Map<String, Object?> _draftPayload(domain.MealDraft draft) {
    return _requestFromDraft(const Uuid().v4(), draft).toJson();
  }

  Future<void> _insertCorrectionEvent({
    required String id,
    required String userId,
    required String mealId,
    required String eventType,
    Map<String, Object?>? beforeValue,
    Map<String, Object?>? afterValue,
  }) async {
    await _db.into(_db.correctionEventsLocal).insert(
          CorrectionEventsLocalCompanion.insert(
            id: id,
            userId: userId,
            mealId: Value(mealId),
            eventType: eventType,
            beforeValueJson:
                Value(beforeValue == null ? null : jsonEncode(beforeValue)),
            afterValueJson:
                Value(afterValue == null ? null : jsonEncode(afterValue)),
          ),
        );
  }

  Future<void> _cacheCorrectionEventDto(CorrectionEventDto event) async {
    await _db.into(_db.correctionEventsLocal).insertOnConflictUpdate(
          CorrectionEventsLocalCompanion.insert(
            id: event.id,
            userId: event.userId,
            mealId: Value(event.mealId),
            analysisJobId: Value(event.analysisJobId),
            eventType: event.eventType,
            fieldName: Value(event.fieldName),
            beforeValueJson: Value(event.beforeValue == null
                ? null
                : jsonEncode(event.beforeValue)),
            afterValueJson: Value(
                event.afterValue == null ? null : jsonEncode(event.afterValue)),
            reason: Value(event.reason),
            createdAt: Value(event.createdAt),
          ),
        );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  domain.MealType _mealTypeForNow(DateTime now) {
    if (now.hour < 11) return domain.MealType.breakfast;
    if (now.hour < 16) return domain.MealType.lunch;
    if (now.hour < 21) return domain.MealType.dinner;
    return domain.MealType.snack;
  }

  domain.MealType _parseMealType(String value) =>
      domain.MealType.values.firstWhere((type) => type.name == value,
          orElse: () => domain.MealType.unknown);

  domain.MealSource _parseMealSource(String value) =>
      domain.MealSource.values.firstWhere((source) => source.name == value,
          orElse: () => domain.MealSource.manual);

  domain.MealSyncStatus _parseSyncStatus(String value) =>
      domain.MealSyncStatus.values.firstWhere((status) => status.name == value,
          orElse: () => domain.MealSyncStatus.synced);
}
