import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:uuid/uuid.dart';

final outboxRepositoryProvider = Provider<OutboxRepository>((ref) {
  return OutboxRepository(ref.watch(appDatabaseProvider));
});

class OutboxRepository {
  OutboxRepository(this._db);

  static const maxRetryCount = 8;

  final AppDatabase _db;

  Future<void> enqueue({
    required String userId,
    required String commandType,
    required Map<String, Object?> payload,
    required String clientRequestId,
    String? dependencyCommandId,
  }) async {
    final payloadJson = jsonEncode(payload);
    await _db.into(_db.outboxCommands).insert(
          OutboxCommandsCompanion.insert(
            id: const Uuid().v4(),
            userId: userId,
            commandType: commandType,
            payloadJson: payloadJson,
            payloadHash: Value<String?>(
                sha256.convert(utf8.encode(payloadJson)).toString()),
            clientRequestId: clientRequestId,
            dependencyCommandId: Value<String?>(dependencyCommandId),
            status: const Value('pending'),
          ),
        );
  }

  Future<List<OutboxCommand>> pendingSettingsPatchCommands(String userId) {
    return (_db.select(_db.outboxCommands)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.commandType.equals('settings.patch') &
              tbl.status.equals('pending') &
              (tbl.nextRetryAt.isNull() |
                  tbl.nextRetryAt
                      .isSmallerOrEqualValue(DateTime.now().toUtc())))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Future<List<OutboxCommand>> pendingMealCommands(String userId) {
    const mealCommands = ['meal.create', 'meal.update', 'meal.delete'];
    return pendingCommands(userId: userId, commandTypes: mealCommands);
  }

  Future<List<OutboxCommand>> pendingCustomFoodCommands(String userId) {
    const customFoodCommands = ['custom_food.upsert', 'custom_food.delete'];
    return pendingCommands(userId: userId, commandTypes: customFoodCommands);
  }

  Future<List<OutboxCommand>> pendingTemplateCommands(String userId) {
    const templateCommands = ['template.upsert', 'template.delete'];
    return pendingCommands(userId: userId, commandTypes: templateCommands);
  }

  Future<List<OutboxCommand>> pendingBodyMeasurementCommands(String userId) {
    return pendingCommands(
        userId: userId, commandTypes: const ['body_measurement.create']);
  }

  Future<List<OutboxCommand>> pendingAssetUploadCommands(String userId) {
    return pendingCommands(
        userId: userId, commandTypes: const ['asset.upload']);
  }

  Future<List<OutboxCommand>> pendingAnalyticsCommands(String userId) {
    return pendingCommands(
        userId: userId, commandTypes: const ['analytics.batch']);
  }

  Future<List<OutboxCommand>> pendingExportCommands(String userId) {
    return pendingCommands(
        userId: userId, commandTypes: const ['export.create']);
  }

  Future<List<OutboxCommand>> pendingCommands({
    required String userId,
    required List<String> commandTypes,
  }) {
    return (_db.select(_db.outboxCommands)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.commandType.isIn(commandTypes) &
              tbl.status.equals('pending') &
              (tbl.nextRetryAt.isNull() |
                  tbl.nextRetryAt
                      .isSmallerOrEqualValue(DateTime.now().toUtc())) &
              (tbl.dependencyCommandId.isNull() |
                  tbl.dependencyCommandId
                      .isNotInQuery(_blockedDependencyIds(userId))))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Future<int> pendingCount(String userId) async {
    final count = _db.outboxCommands.id.count();
    final row = await (_db.selectOnly(_db.outboxCommands)
          ..addColumns([count])
          ..where(
            _db.outboxCommands.userId.equals(userId) &
                _db.outboxCommands.status
                    .isIn(const ['pending', 'conflict', 'failed', 'blocked']),
          ))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<bool> hasConflict(String userId) async {
    final count = _db.outboxCommands.id.count();
    final row = await (_db.selectOnly(_db.outboxCommands)
          ..addColumns([count])
          ..where(_db.outboxCommands.userId.equals(userId) &
              _db.outboxCommands.status.equals('conflict')))
        .getSingle();
    return (row.read(count) ?? 0) > 0;
  }

  Future<List<OutboxCommand>> conflictCommands(String userId) {
    return (_db.select(_db.outboxCommands)
          ..where((tbl) =>
              tbl.userId.equals(userId) & tbl.status.equals('conflict'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Future<void> retryCommand(String id) async {
    await (_db.update(_db.outboxCommands)..where((tbl) => tbl.id.equals(id)))
        .write(
      OutboxCommandsCompanion(
        status: const Value('pending'),
        nextRetryAt: const Value<DateTime?>(null),
        lastError: const Value<String?>(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> discardCommand(String id) async {
    await (_db.update(_db.outboxCommands)..where((tbl) => tbl.id.equals(id)))
        .write(
      OutboxCommandsCompanion(
        status: const Value('synced'),
        lastError: const Value<String?>(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> markAssetUploadSynced(String assetId) async {
    final commands = await pendingAssetUploadCommandsForAllStatuses(assetId);
    for (final command in commands) {
      await markSynced(command.id);
    }
  }

  Future<List<OutboxCommand>> pendingAssetUploadCommandsForAllStatuses(
      String assetId) async {
    final rows = await (_db.select(_db.outboxCommands)
          ..where((tbl) =>
              tbl.commandType.equals('asset.upload') &
              tbl.status.isIn(const ['pending', 'failed', 'blocked'])))
        .get();
    return rows.where((command) {
      try {
        final payload = jsonDecode(command.payloadJson) as Map;
        return payload['asset_id'] == assetId;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> markSynced(String id) async {
    await (_db.update(_db.outboxCommands)..where((tbl) => tbl.id.equals(id)))
        .write(
      OutboxCommandsCompanion(
        status: const Value('synced'),
        lastError: const Value<String?>(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> markAllUserCommandsSynced(String userId) async {
    await (_db.update(_db.outboxCommands)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.status
                  .isIn(const ['pending', 'failed', 'conflict', 'blocked'])))
        .write(
      OutboxCommandsCompanion(
        status: const Value('synced'),
        lastError: const Value<String?>(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> markFailed(String id,
      {bool retryable = true, Object? error}) async {
    final current = await (_db.select(_db.outboxCommands)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    final retryCount = (current?.retryCount ?? 0) + 1;
    final shouldRetry = retryable && retryCount < maxRetryCount;
    final nextRetry = shouldRetry
        ? DateTime.now().toUtc().add(_backoffDelay(retryCount))
        : null;
    await (_db.update(_db.outboxCommands)..where((tbl) => tbl.id.equals(id)))
        .write(
      OutboxCommandsCompanion(
        status: Value(shouldRetry ? 'pending' : 'failed'),
        retryCount: Value(retryCount),
        nextRetryAt: Value<DateTime?>(nextRetry),
        lastError: Value(error?.toString()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> markConflict(String id, Object error) async {
    await (_db.update(_db.outboxCommands)..where((tbl) => tbl.id.equals(id)))
        .write(
      OutboxCommandsCompanion(
        status: const Value('conflict'),
        lastError: Value(error.toString()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> markBlocked(String id, Object error) async {
    await (_db.update(_db.outboxCommands)..where((tbl) => tbl.id.equals(id)))
        .write(
      OutboxCommandsCompanion(
        status: const Value('blocked'),
        lastError: Value(error.toString()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  dynamic _blockedDependencyIds(String userId) {
    return _db.selectOnly(_db.outboxCommands)
      ..addColumns([_db.outboxCommands.id])
      ..where(
        _db.outboxCommands.userId.equals(userId) &
            _db.outboxCommands.status
                .isIn(const ['pending', 'failed', 'conflict', 'blocked']),
      );
  }

  Duration _backoffDelay(int retryCount) {
    final cappedExponent = min(retryCount, 6);
    final baseSeconds =
        min(30 * pow(2, cappedExponent - 1).toInt(), 30 * 60).toInt();
    final jitterSeconds = Random().nextInt(max(1, baseSeconds ~/ 4));
    return Duration(seconds: baseSeconds + jitterSeconds);
  }
}
