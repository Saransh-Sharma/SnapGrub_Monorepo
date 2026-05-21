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
    if (!isConfigured) return;
    await _drain(userId, _outbox.pendingAssetUploadCommands, _uploadAsset);
    await _drain(userId, _outbox.pendingBodyMeasurementCommands, _createBodyMeasurement);
    await _drain(userId, _outbox.pendingAnalyticsCommands, _ingestAnalytics);
    await _drain(userId, _outbox.pendingExportCommands, _createExport);
  }

  Future<void> _drain(
    String userId,
    Future<List<OutboxCommand>> Function(String userId) loader,
    Future<void> Function(OutboxCommand command, Map<String, dynamic> payload) handler,
  ) async {
    final commands = await loader(userId);
    for (final command in commands) {
      try {
        final payload = Map<String, dynamic>.from(jsonDecode(command.payloadJson) as Map);
        await handler(command, payload);
        await _outbox.markSynced(command.id);
      } catch (error) {
        if (isConflictSyncError(error)) {
          await _outbox.markConflict(command.id, error);
        } else {
          await _outbox.markFailed(command.id, retryable: isRetryableSyncError(error), error: error);
        }
      }
    }
  }

  Future<void> _uploadAsset(OutboxCommand command, Map<String, dynamic> payload) async {
    final localPath = payload['local_path'] as String;
    final storageBucket = payload['storage_bucket'] as String? ?? 'meal-originals-private';
    final storagePath = payload['storage_path'] as String;
    final mimeType = payload['mime_type'] as String? ?? 'image/jpeg';
    await _client.storage.from(storageBucket).uploadBinary(
          storagePath,
          await File(localPath).readAsBytes(),
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    final thumbLocalPath = payload['thumb_local_path'] as String?;
    final thumbStoragePath = payload['thumb_storage_path'] as String?;
    if (thumbLocalPath != null && thumbStoragePath != null) {
      await _client.storage.from('meal-thumbnails-private').uploadBinary(
            thumbStoragePath,
            await File(thumbLocalPath).readAsBytes(),
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
    }

    final assetId = payload['asset_id'] as String?;
    if (assetId != null) {
      await (_db.update(_db.mealAssetsLocal)..where((tbl) => tbl.id.equals(assetId))).write(
        MealAssetsLocalCompanion(
          uploadStatus: const Value('uploaded'),
          uploadedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
  }

  Future<void> _createBodyMeasurement(OutboxCommand command, Map<String, dynamic> payload) async {
    final response = await _client.functions.invoke(
      'body-measurements',
      method: HttpMethod.post,
      headers: {'Idempotency-Key': command.clientRequestId},
      body: {
        ...payload,
        'client_request_id': command.clientRequestId,
      },
    );
    final measurement = Map<String, dynamic>.from((response.data as Map)['body_measurement'] as Map);
    final localId = payload['id'] as String?;
    if (localId != null) {
      await (_db.update(_db.bodyMeasurementsLocal)..where((tbl) => tbl.id.equals(localId))).write(
        BodyMeasurementsLocalCompanion(
          syncStatus: const Value('synced'),
          updatedAt: Value(DateTime.parse(measurement['updated_at'] as String? ?? DateTime.now().toUtc().toIso8601String())),
        ),
      );
    }
  }

  Future<void> _ingestAnalytics(OutboxCommand command, Map<String, dynamic> payload) async {
    final events = (payload['events'] as List? ?? const [])
        .map((event) => Map<String, Object?>.from(event as Map))
        .toList(growable: false);
    await _events.ingest(events, clientRequestId: command.clientRequestId);
  }

  Future<void> _createExport(OutboxCommand command, Map<String, dynamic> payload) async {
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
}

