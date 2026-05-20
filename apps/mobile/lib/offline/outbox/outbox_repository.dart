import 'dart:convert';

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

  final AppDatabase _db;

  Future<void> enqueue({
    required String userId,
    required String commandType,
    required Map<String, Object?> payload,
    required String clientRequestId,
  }) async {
    await _db.into(_db.outboxCommands).insert(
          OutboxCommandsCompanion.insert(
            id: const Uuid().v4(),
            userId: userId,
            commandType: commandType,
            payloadJson: jsonEncode(payload),
            clientRequestId: clientRequestId,
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
              (tbl.nextRetryAt.isNull() | tbl.nextRetryAt.isSmallerOrEqualValue(DateTime.now())))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Future<List<OutboxCommand>> pendingMealCommands(String userId) {
    const mealCommands = ['meal.create', 'meal.update', 'meal.delete'];
    return (_db.select(_db.outboxCommands)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.commandType.isIn(mealCommands) &
              tbl.status.equals('pending') &
              (tbl.nextRetryAt.isNull() | tbl.nextRetryAt.isSmallerOrEqualValue(DateTime.now())))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Future<void> markSynced(String id) async {
    await (_db.update(_db.outboxCommands)..where((tbl) => tbl.id.equals(id))).write(
      OutboxCommandsCompanion(
        status: const Value('synced'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markFailed(String id, {bool retryable = true}) async {
    final current = await (_db.select(_db.outboxCommands)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    final nextRetry = retryable ? DateTime.now().add(const Duration(minutes: 2)) : null;
    await (_db.update(_db.outboxCommands)..where((tbl) => tbl.id.equals(id))).write(
      OutboxCommandsCompanion(
        status: Value(retryable ? 'pending' : 'failed'),
        retryCount: Value((current?.retryCount ?? 0) + 1),
        nextRetryAt: Value(nextRetry),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
