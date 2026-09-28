import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_visuals/domain/meal_visual.dart';
import 'package:snapgrub/features/meal_visuals/data/meal_visual_remote_service.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:uuid/uuid.dart';

final mealVisualRepositoryProvider = Provider<MealVisualRepository>((ref) {
  return MealVisualRepository(
    db: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxRepositoryProvider),
    remote: ref.watch(mealVisualRemoteServiceProvider),
  );
});

final mealVisualProvider =
    StreamProvider.family<MealVisual?, Meal>((ref, meal) async* {
  yield* ref.watch(mealVisualRepositoryProvider).watchForMeal(meal.id);
});

final mealAssetPathProvider =
    FutureProvider.family<String?, String?>((ref, assetId) async {
  if (assetId == null) return null;
  final db = ref.watch(appDatabaseProvider);
  final row = await (db.select(db.mealAssetsLocal)
        ..where((item) => item.id.equals(assetId)))
      .getSingleOrNull();
  return row?.thumbLocalPath ?? row?.localPath;
});

class MealVisualRepository {
  MealVisualRepository(
      {required AppDatabase db,
      required OutboxRepository outbox,
      required MealVisualRemoteService remote})
      : _db = db,
        _outbox = outbox,
        _remote = remote;

  final AppDatabase _db;
  final OutboxRepository _outbox;
  final MealVisualRemoteService _remote;

  Stream<MealVisual?> watchForMeal(String mealId) {
    final query = _db.select(_db.mealVisualsLocal)
      ..where((row) => row.mealId.equals(mealId))
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(1);
    return query.watchSingleOrNull().map((row) => row == null
        ? null
        : MealVisual(
            id: row.id,
            mealId: row.mealId,
            userId: row.userId,
            promptSignature: row.promptSignature,
            styleVersion: row.styleVersion,
            status: MealVisualStatus.values.byName(row.status),
            localPath: row.localPath,
            remotePath: row.remotePath,
            thumbRemotePath: row.thumbRemotePath,
            dominantColor: row.dominantColor,
          ));
  }

  Future<void> request(Meal meal) async {
    final signature = _signature(meal);
    final existing = await (_db.select(_db.mealVisualsLocal)
          ..where((row) =>
              row.mealId.equals(meal.id) &
              row.promptSignature.equals(signature)))
        .getSingleOrNull();
    if (existing != null) return;
    final id = const Uuid().v4();
    await _db.into(_db.mealVisualsLocal).insert(
          MealVisualsLocalCompanion.insert(
            id: id,
            mealId: meal.id,
            userId: meal.userId,
            promptSignature: signature,
          ),
        );
    await _outbox.enqueue(
      userId: meal.userId,
      commandType: 'meal.visual.create',
      payload: {
        'visual_id': id,
        'meal_id': meal.id,
        'prompt_signature': signature,
        'style_version': 'studio-v1',
      },
      clientRequestId: const Uuid().v4(),
    );
  }

  Future<void> drainOutbox(String userId) async {
    if (!_remote.isConfigured) return;
    final commands = await _outbox.pendingCommands(
      userId: userId,
      commandTypes: const ['meal.visual.create'],
    );
    for (final command in commands) {
      try {
        final payload =
            Map<String, Object?>.from(jsonDecode(command.payloadJson) as Map);
        final row = await _remote.create(
          payload: payload,
          clientRequestId: command.clientRequestId,
        );
        final localPath = await _cacheSignedAsset(
          visualId: row['id'] as String,
          signedUrl: row['signed_url'] as String?,
        );
        await _cacheRemoteRow(row, localPath: localPath);
        await _outbox.markSynced(command.id);
      } catch (error) {
        await _outbox.markFailed(command.id, error: error);
      }
    }
  }

  Future<String?> _cacheSignedAsset({
    required String visualId,
    required String? signedUrl,
  }) async {
    if (signedUrl == null || signedUrl.isEmpty) return null;
    final response = await http.get(Uri.parse(signedUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/meal_visuals');
    await directory.create(recursive: true);
    final file = File('${directory.path}/$visualId.jpg');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  Future<void> _cacheRemoteRow(
    Map<String, dynamic> row, {
    required String? localPath,
  }) async {
    await _db.into(_db.mealVisualsLocal).insertOnConflictUpdate(
          MealVisualsLocalCompanion.insert(
            id: row['id'] as String,
            mealId: row['meal_id'] as String,
            userId: row['user_id'] as String,
            promptSignature: row['prompt_signature'] as String,
            styleVersion: Value(row['style_version'] as String? ?? 'studio-v1'),
            status: Value(row['status'] as String? ?? 'queued'),
            localPath: Value(localPath),
            remotePath: Value(row['storage_path'] as String?),
            thumbRemotePath: Value(row['thumb_storage_path'] as String?),
            dominantColor: Value(row['dominant_color'] as String?),
            provider: Value(row['provider'] as String?),
            modelName: Value(row['model_name'] as String?),
            errorCode: Value(row['error_code'] as String?),
          ),
        );
  }

  String _signature(Meal meal) {
    final input = jsonEncode({
      'style': 'studio-v1',
      'meal_type': meal.mealType.name,
      'items':
          meal.items.map((item) => item.name.trim().toLowerCase()).toList(),
    });
    return sha256.convert(utf8.encode(input)).toString();
  }
}
