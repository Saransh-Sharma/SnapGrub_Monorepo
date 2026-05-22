import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/data/services/events_remote_service.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:snapgrub/offline/sync/sync_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final syncCommandRepositoryProvider = Provider<SyncCommandRepository>((ref) {
  return SyncCommandRepository(
    db: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxRepositoryProvider),
    events: ref.watch(eventsRemoteServiceProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

class SyncCommandRepository {
  const SyncCommandRepository({
    required AppDatabase db,
    required OutboxRepository outbox,
    required EventsRemoteService events,
    required dynamic supabaseClient,
  })  : _db = db,
        _outbox = outbox,
        _events = events,
        _client = supabaseClient;

  final AppDatabase _db;
  final OutboxRepository _outbox;
  final EventsRemoteService _events;
  final dynamic _client;

  bool get isConfigured => _client != null;

  Future<void> drainPhase6Commands(String userId) async {
    await drainEarlyCommands(userId);
    await drainDeferredCommands(userId);
  }

  Future<void> drainEarlyCommands(String userId) async {
    if (!isConfigured) return;
    await _drain(userId, _outbox.pendingAssetUploadCommands, _uploadAsset);
    await _drain(
        userId, _outbox.pendingBodyMeasurementCommands, _createBodyMeasurement);
  }

  Future<void> drainDeferredCommands(String userId) async {
    if (!isConfigured) return;
    await _drain(userId, _outbox.pendingExportCommands, _createExport);
    await _drain(userId, _outbox.pendingAnalyticsCommands, _ingestAnalytics);
  }

  Future<void> pullAuthoritativeState(String userId) async {
    if (!isConfigured) return;
    await _pullFeatureFlags();
    await _pullBodyMeasurements(userId);
    await _pullCustomFoods(userId);
    await _pullTemplates(userId);
    await _pullMealsAndRollups(userId);
    await _pullPhase7(userId);
    await _updateCursor(
        'authoritative:$userId', DateTime.now().toUtc().toIso8601String());
  }

  Future<void> _drain(
    String userId,
    Future<List<OutboxCommand>> Function(String userId) loader,
    Future<void> Function(OutboxCommand command, Map<String, dynamic> payload)
        handler,
  ) async {
    final commands = await loader(userId);
    for (final command in commands) {
      try {
        final payload =
            Map<String, dynamic>.from(jsonDecode(command.payloadJson) as Map);
        await handler(command, payload);
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

  Future<void> _uploadAsset(
      OutboxCommand command, Map<String, dynamic> payload) async {
    final localPath = payload['local_path'] as String;
    final file = File(localPath);
    if (!await file.exists()) {
      throw NonRetryableSyncException('not_found: local asset file is missing');
    }
    final storageBucket =
        payload['storage_bucket'] as String? ?? 'meal-originals-private';
    final storagePath = payload['storage_path'] as String;
    final mimeType = payload['mime_type'] as String? ?? 'image/jpeg';
    await _client.storage.from(storageBucket).uploadBinary(
          storagePath,
          await file.readAsBytes(),
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    final thumbLocalPath = payload['thumb_local_path'] as String?;
    final thumbStoragePath = payload['thumb_storage_path'] as String?;
    if (thumbLocalPath != null && thumbStoragePath != null) {
      await _client.storage.from('meal-thumbnails-private').uploadBinary(
            thumbStoragePath,
            await File(thumbLocalPath).readAsBytes(),
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
    }

    final assetId = payload['asset_id'] as String?;
    if (assetId != null) {
      await (_db.update(_db.mealAssetsLocal)
            ..where((tbl) => tbl.id.equals(assetId)))
          .write(
        MealAssetsLocalCompanion(
          uploadStatus: const Value('uploaded'),
          uploadedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
  }

  Future<void> _createBodyMeasurement(
      OutboxCommand command, Map<String, dynamic> payload) async {
    final response = await _client.functions.invoke(
      'body-measurements',
      method: HttpMethod.post,
      headers: {'Idempotency-Key': command.clientRequestId},
      body: {
        ...payload,
        'client_request_id': command.clientRequestId,
      },
    );
    final measurement = Map<String, dynamic>.from(
        (response.data as Map)['body_measurement'] as Map);
    final localId = payload['id'] as String?;
    if (localId != null) {
      await (_db.update(_db.bodyMeasurementsLocal)
            ..where((tbl) => tbl.id.equals(localId)))
          .write(
        BodyMeasurementsLocalCompanion(
          syncStatus: const Value('synced'),
          updatedAt: Value(DateTime.parse(
              measurement['updated_at'] as String? ??
                  DateTime.now().toUtc().toIso8601String())),
        ),
      );
    }
  }

  Future<void> _ingestAnalytics(
      OutboxCommand command, Map<String, dynamic> payload) async {
    final events = (payload['events'] as List? ?? const [])
        .map((event) => Map<String, Object?>.from(event as Map))
        .toList(growable: false);
    await _events.ingest(events, clientRequestId: command.clientRequestId);
  }

  Future<void> _createExport(
      OutboxCommand command, Map<String, dynamic> payload) async {
    await _client.functions.invoke(
      'exports-create',
      method: HttpMethod.post,
      headers: {'Idempotency-Key': command.clientRequestId},
      body: {
        ...payload,
        'client_request_id': command.clientRequestId,
      },
    );
  }

  Future<void> _pullFeatureFlags() async {
    final response = await _client.from('feature_flags').select('key, enabled');
    for (final row in List<Map<String, dynamic>>.from(response as List)) {
      await _db.into(_db.featureFlagsLocal).insertOnConflictUpdate(
            FeatureFlagsLocalCompanion.insert(
              key: row['key'] as String,
              valueJson: jsonEncode(row['enabled'] == true),
            ),
          );
    }
  }

  Future<void> _pullBodyMeasurements(String userId) async {
    final response = await _client
        .from('body_measurements')
        .select('*')
        .eq('user_id', userId);
    for (final row in List<Map<String, dynamic>>.from(response as List)) {
      await _db.into(_db.bodyMeasurementsLocal).insertOnConflictUpdate(
            BodyMeasurementsLocalCompanion.insert(
              id: row['id'] as String,
              userId: row['user_id'] as String,
              measuredAt: DateTime.parse(row['measured_at'] as String),
              weightKg: Value((row['weight_kg'] as num?)?.toDouble()),
              bodyFatPct: Value((row['body_fat_pct'] as num?)?.toDouble()),
              source: Value(row['source'] as String? ?? 'manual'),
              syncStatus: const Value('synced'),
              updatedAt: Value(_parseDate(row['updated_at'])),
            ),
          );
    }
  }

  Future<void> _pullCustomFoods(String userId) async {
    final response =
        await _client.from('custom_foods').select('*').eq('user_id', userId);
    for (final row in List<Map<String, dynamic>>.from(response as List)) {
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
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              updatedAt: Value(_parseDate(row['updated_at'])),
            ),
          );
    }
  }

  Future<void> _pullTemplates(String userId) async {
    final response =
        await _client.from('meal_templates').select('*').eq('user_id', userId);
    for (final row in List<Map<String, dynamic>>.from(response as List)) {
      await _db.into(_db.mealTemplatesLocal).insertOnConflictUpdate(
            MealTemplatesLocalCompanion.insert(
              id: row['id'] as String,
              userId: row['user_id'] as String,
              clientId: row['client_id'] as String,
              title: row['title'] as String,
              snapshotJson: jsonEncode(row['snapshot'] as Object? ?? const {}),
              sourceMealId: Value(row['source_meal_id'] as String?),
              syncStatus: const Value('synced'),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              updatedAt: Value(_parseDate(row['updated_at'])),
            ),
          );
    }
  }

  Future<void> _pullMealsAndRollups(String userId) async {
    final meals = await _client
        .from('meals')
        .select('*, meal_items(*)')
        .eq('user_id', userId)
        .order('logged_at', ascending: false)
        .limit(100);
    for (final raw in List<Map<String, dynamic>>.from(meals as List)) {
      await _cacheMealRow(raw);
    }

    final rollups =
        await _client.from('daily_rollups').select('*').eq('user_id', userId);
    for (final row in List<Map<String, dynamic>>.from(rollups as List)) {
      await _db.into(_db.dailyRollupsLocal).insertOnConflictUpdate(
            DailyRollupsLocalCompanion.insert(
              userId: row['user_id'] as String,
              day: DateTime.parse(row['day'] as String),
              caloriesKcal:
                  Value((row['calories_kcal'] as num?)?.toDouble() ?? 0),
              proteinG: Value((row['protein_g'] as num?)?.toDouble() ?? 0),
              carbsG: Value((row['carbs_g'] as num?)?.toDouble() ?? 0),
              fatG: Value((row['fat_g'] as num?)?.toDouble() ?? 0),
              mealCount: Value((row['meal_count'] as num?)?.toInt() ?? 0),
              hasPhotoMeal: Value(row['has_photo_meal'] == true),
              updatedAt: Value(_parseDate(row['updated_at'])),
            ),
          );
    }
  }

  Future<void> _pullPhase7(String userId) async {
    final insights = await _client
        .from('weekly_insights')
        .select('*')
        .eq('user_id', userId)
        .order('week_start', ascending: false)
        .limit(12);
    for (final row in List<Map<String, dynamic>>.from(insights as List)) {
      await _db.into(_db.weeklyInsightsLocal).insertOnConflictUpdate(
            WeeklyInsightsLocalCompanion.insert(
              id: row['id'] as String,
              userId: row['user_id'] as String,
              weekStart: DateTime.parse(row['week_start'] as String),
              insightType: row['insight_type'] as String,
              title: row['title'] as String,
              summary: row['summary'] as String,
              payloadJson:
                  Value(jsonEncode(row['payload'] as Object? ?? const {})),
              status: Value(row['status'] as String? ?? 'ready'),
              generatedAt: Value(_parseNullableDate(row['generated_at'])),
              updatedAt: Value(_parseDate(row['updated_at'])),
            ),
          );
    }

    final defaults = await _client
        .from('user_food_defaults')
        .select('*')
        .eq('user_id', userId);
    for (final row in List<Map<String, dynamic>>.from(defaults as List)) {
      await _db.into(_db.userFoodDefaultsLocal).insertOnConflictUpdate(
            UserFoodDefaultsLocalCompanion.insert(
              id: row['id'] as String,
              userId: row['user_id'] as String,
              foodRefKind: row['food_ref_kind'] as String,
              foodRefId: row['food_ref_id'] as String,
              foodName: row['food_name'] as String,
              preferredQuantity:
                  Value((row['preferred_quantity'] as num?)?.toDouble() ?? 1),
              preferredUnit: row['preferred_unit'] as String,
              preferredGrams:
                  Value((row['preferred_grams'] as num?)?.toDouble()),
              caloriesKcal:
                  Value((row['calories_kcal'] as num?)?.toDouble() ?? 0),
              proteinG: Value((row['protein_g'] as num?)?.toDouble() ?? 0),
              carbsG: Value((row['carbs_g'] as num?)?.toDouble() ?? 0),
              fatG: Value((row['fat_g'] as num?)?.toDouble() ?? 0),
              useCount: Value((row['use_count'] as num?)?.toInt() ?? 1),
              lastUsedAt: Value(_parseNullableDate(row['last_used_at'])),
              updatedAt: Value(_parseDate(row['updated_at'])),
            ),
          );
    }
  }

  Future<void> _cacheMealRow(Map<String, dynamic> meal) async {
    await _db.into(_db.mealsLocal).insertOnConflictUpdate(
          MealsLocalCompanion.insert(
            id: meal['id'] as String,
            userId: meal['user_id'] as String,
            clientId: meal['client_id'] as String,
            analysisJobId: Value(meal['analysis_job_id'] as String?),
            title: meal['title'] as String,
            mealType: meal['meal_type'] as String,
            source: meal['source'] as String,
            loggedAt: DateTime.parse(meal['logged_at'] as String),
            timezone: meal['timezone'] as String,
            caloriesKcal:
                Value((meal['calories_kcal'] as num?)?.toDouble() ?? 0),
            proteinG: Value((meal['protein_g'] as num?)?.toDouble() ?? 0),
            carbsG: Value((meal['carbs_g'] as num?)?.toDouble() ?? 0),
            fatG: Value((meal['fat_g'] as num?)?.toDouble() ?? 0),
            confidenceOverall:
                Value((meal['confidence_overall'] as num?)?.toDouble()),
            provenanceType: Value(meal['provenance_type'] as String?),
            photoAssetId: Value(meal['photo_asset_id'] as String?),
            revision: Value((meal['revision'] as num?)?.toInt() ?? 1),
            syncStatus: const Value('synced'),
            deletedAt: Value(_parseNullableDate(meal['deleted_at'])),
            updatedAt: Value(_parseDate(meal['updated_at'])),
          ),
        );
    await (_db.delete(_db.mealItemsLocal)
          ..where((tbl) => tbl.mealId.equals(meal['id'] as String)))
        .go();
    for (final raw in List<Map<String, dynamic>>.from(
        (meal['meal_items'] as List?) ?? const [])) {
      await _db.into(_db.mealItemsLocal).insert(
            MealItemsLocalCompanion.insert(
              id: raw['id'] as String,
              mealId: raw['meal_id'] as String,
              userId: raw['user_id'] as String,
              clientId: raw['client_id'] as String,
              position: (raw['position'] as num?)?.toInt() ?? 0,
              name: raw['name'] as String,
              foodRefKind: Value(raw['food_ref_kind'] as String? ?? 'manual'),
              canonicalFoodId: Value(raw['canonical_food_id'] as String?),
              brandedProductId: Value(raw['branded_product_id'] as String?),
              customFoodId: Value(raw['custom_food_id'] as String?),
              quantity: (raw['quantity'] as num?)?.toDouble() ?? 1,
              unit: raw['unit'] as String,
              gramsEstimated:
                  Value((raw['grams_estimated'] as num?)?.toDouble()),
              caloriesKcal:
                  Value((raw['calories_kcal'] as num?)?.toDouble() ?? 0),
              proteinG: Value((raw['protein_g'] as num?)?.toDouble() ?? 0),
              carbsG: Value((raw['carbs_g'] as num?)?.toDouble() ?? 0),
              fatG: Value((raw['fat_g'] as num?)?.toDouble() ?? 0),
              confidence: Value((raw['confidence'] as num?)?.toDouble()),
              sourceType: Value(raw['source_type'] as String?),
              sourceId: Value(raw['source_id'] as String?),
              notes: Value(raw['notes'] as String?),
            ),
          );
    }
  }

  Future<void> _updateCursor(String key, String cursor) async {
    await _db.into(_db.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(
            key: key,
            cursor: Value(cursor),
            lastSyncedAt: Value(DateTime.now().toUtc()),
            lastError: const Value<String?>(null),
          ),
        );
  }

  DateTime _parseDate(Object? value) {
    return _parseNullableDate(value) ?? DateTime.now().toUtc();
  }

  DateTime? _parseNullableDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }
}
