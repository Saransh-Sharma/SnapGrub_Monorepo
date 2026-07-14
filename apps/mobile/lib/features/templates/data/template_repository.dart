import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/templates/data/template_remote_service.dart';
import 'package:snapgrub/features/templates/domain/meal_template.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:snapgrub/offline/sync/sync_error.dart';
import 'package:uuid/uuid.dart';

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository(
    db: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxRepositoryProvider),
    remote: ref.watch(templateRemoteServiceProvider),
  );
});

final mealTemplatesProvider =
    StreamProvider.family<List<MealTemplate>, String>((ref, userId) {
  return ref.watch(templateRepositoryProvider).watchTemplates(userId);
});

class TemplateRepository {
  TemplateRepository({
    required AppDatabase db,
    required OutboxRepository outbox,
    required TemplateRemoteService remote,
  })  : _db = db,
        _outbox = outbox,
        _remote = remote;

  final AppDatabase _db;
  final OutboxRepository _outbox;
  final TemplateRemoteService _remote;

  Stream<List<MealTemplate>> watchTemplates(String userId) {
    final query = _db.select(_db.mealTemplatesLocal)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<MealTemplate> saveFromMeal(Meal meal) async {
    return saveDraft(
      userId: meal.userId,
      title: meal.title,
      sourceMealId: meal.id,
      snapshot: _snapshotFromMeal(meal),
    );
  }

  Future<MealTemplate> saveFromDraft(MealDraft draft) async {
    return saveDraft(
      userId: draft.userId,
      title: draft.title.trim(),
      sourceMealId: null,
      snapshot: _snapshotFromDraft(draft),
    );
  }

  Future<MealTemplate> saveDraft({
    required String userId,
    required String title,
    required Map<String, Object?> snapshot,
    String? sourceMealId,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Template title is required.');
    }
    final id = const Uuid().v4();
    final clientId = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final payload = {
      'id': id,
      'user_id': userId,
      'client_id': clientId,
      'title': title.trim(),
      'snapshot': snapshot,
      'source_meal_id': sourceMealId,
      'deleted_at': null,
    };

    await _db.into(_db.mealTemplatesLocal).insert(
          MealTemplatesLocalCompanion.insert(
            id: id,
            userId: userId,
            clientId: clientId,
            title: title.trim(),
            snapshotJson: jsonEncode(snapshot),
            sourceMealId: Value(sourceMealId),
            syncStatus: const Value('pending'),
            updatedAt: Value(now),
          ),
        );
    await _outbox.enqueue(
      userId: userId,
      commandType: 'template.upsert',
      payload: payload,
      clientRequestId: const Uuid().v4(),
    );
    return _fromRow((await (_db.select(_db.mealTemplatesLocal)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle()));
  }

  Future<void> delete(MealTemplate template) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.mealTemplatesLocal)
          ..where((tbl) => tbl.id.equals(template.id)))
        .write(
      MealTemplatesLocalCompanion(
        syncStatus: const Value('pending'),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await _outbox.enqueue(
      userId: template.userId,
      commandType: 'template.delete',
      payload: {
        'user_id': template.userId,
        'client_id': template.clientId,
        'deleted_at': now.toIso8601String(),
      },
      clientRequestId: const Uuid().v4(),
    );
  }

  Future<void> drainOutbox(String userId) async {
    if (!_remote.isConfigured) return;
    final commands = await _outbox.pendingTemplateCommands(userId);
    for (final command in commands) {
      try {
        final payload =
            Map<String, dynamic>.from(jsonDecode(command.payloadJson) as Map);
        final row = command.commandType == 'template.delete'
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
    await _db.into(_db.mealTemplatesLocal).insertOnConflictUpdate(
          MealTemplatesLocalCompanion.insert(
            id: row['id'] as String,
            userId: row['user_id'] as String,
            clientId: row['client_id'] as String,
            title: row['title'] as String,
            snapshotJson: jsonEncode(row['snapshot'] as Object? ?? const {}),
            sourceMealId: Value(row['source_meal_id'] as String?),
            syncStatus: const Value('synced'),
            deletedAt: Value(row['deleted_at'] == null
                ? null
                : DateTime.parse(row['deleted_at'] as String)),
          ),
        );
  }

  MealTemplate _fromRow(dynamic row) {
    return MealTemplate(
      id: row.id as String,
      userId: row.userId as String,
      clientId: row.clientId as String,
      title: row.title as String,
      snapshot: Map<String, Object?>.from(
          jsonDecode(row.snapshotJson as String) as Map),
      sourceMealId: row.sourceMealId as String?,
      syncStatus: row.syncStatus as String,
      deletedAt: row.deletedAt as DateTime?,
    );
  }

  Map<String, Object?> _snapshotFromMeal(Meal meal) {
    return {
      'title': meal.title,
      'meal_type': meal.mealType.name,
      'items': [
        for (final item in meal.items)
          {
            'name': item.name,
            'food_ref_kind': item.foodRefKind,
            'canonical_food_id': item.canonicalFoodId,
            'branded_product_id': item.brandedProductId,
            'custom_food_id': item.customFoodId,
            'quantity': item.quantity,
            'unit': item.unit,
            'grams_estimated': item.gramsEstimated,
            'calories_kcal': item.caloriesKcal,
            'protein_g': item.proteinG,
            'carbs_g': item.carbsG,
            'fat_g': item.fatG,
            'source_type': item.sourceType,
            'source_id': item.sourceId,
            'notes': item.notes,
          },
      ],
    };
  }

  Map<String, Object?> _snapshotFromDraft(MealDraft draft) {
    return {
      'title': draft.title,
      'meal_type': draft.mealType.name,
      'items': [
        for (final item in draft.items)
          {
            'name': item.name,
            'food_ref_kind': item.foodRefKind,
            'canonical_food_id': item.canonicalFoodId,
            'branded_product_id': item.brandedProductId,
            'custom_food_id': item.customFoodId,
            'quantity': item.quantity,
            'unit': item.unit,
            'grams_estimated': item.gramsEstimated,
            'calories_kcal': item.caloriesKcal,
            'protein_g': item.proteinG,
            'carbs_g': item.carbsG,
            'fat_g': item.fatG,
            'source_type': item.sourceType,
            'source_id': item.sourceId,
            'notes': item.notes,
          },
      ],
    };
  }
}
