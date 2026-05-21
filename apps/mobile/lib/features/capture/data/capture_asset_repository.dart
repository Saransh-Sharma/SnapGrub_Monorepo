import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:uuid/uuid.dart';

final captureAssetRepositoryProvider = Provider<CaptureAssetRepository>((ref) {
  return CaptureAssetRepository(
    db: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxRepositoryProvider),
  );
});

class CaptureAssetRepository {
  const CaptureAssetRepository({
    required AppDatabase db,
    required OutboxRepository outbox,
  })  : _db = db,
        _outbox = outbox;

  final AppDatabase _db;
  final OutboxRepository _outbox;

  Future<CaptureAsset> createFromCapture({
    required String userId,
    required XFile file,
  }) async {
    final id = const Uuid().v4();
    final originalBytes = await file.readAsBytes();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) throw StateError('Captured image could not be decoded.');

    final normalized = img.bakeOrientation(decoded);
    final resized = normalized.width > 1280
        ? img.copyResize(normalized, width: 1280, interpolation: img.Interpolation.average)
        : normalized;
    final compressed = _encodeUnderTarget(resized, 700 * 1024);
    final thumb = img.copyResize(normalized, width: 320, interpolation: img.Interpolation.average);
    final thumbBytes = Uint8List.fromList(img.encodeJpg(thumb, quality: 72));
    final digest = sha256.convert(compressed).toString();
    final directory = await getApplicationDocumentsDirectory();
    final captureDir = Directory(p.join(directory.path, 'captures', userId));
    await captureDir.create(recursive: true);
    final localPath = p.join(captureDir.path, '$id.jpg');
    final thumbLocalPath = p.join(captureDir.path, '$id-thumb.jpg');
    await File(localPath).writeAsBytes(compressed, flush: true);
    await File(thumbLocalPath).writeAsBytes(thumbBytes, flush: true);

    final storagePath = '$userId/$id.jpg';
    final thumbStoragePath = '$userId/$id-thumb.jpg';
    final asset = CaptureAsset(
      id: id,
      userId: userId,
      createdAt: DateTime.now().toUtc(),
      localPath: localPath,
      storageBucket: 'meal-originals-private',
      storagePath: storagePath,
      thumbLocalPath: thumbLocalPath,
      thumbStoragePath: thumbStoragePath,
      sha256: digest,
      mimeType: 'image/jpeg',
      width: resized.width,
      height: resized.height,
      sizeBytes: compressed.length,
    );
    await _db.into(_db.mealAssetsLocal).insert(
          MealAssetsLocalCompanion.insert(
            id: asset.id,
            userId: userId,
            localPath: asset.localPath,
            storagePath: asset.storagePath,
            thumbLocalPath: Value(asset.thumbLocalPath),
            thumbStoragePath: Value(asset.thumbStoragePath),
            sha256: asset.sha256,
            width: Value(asset.width),
            height: Value(asset.height),
            sizeBytes: Value(asset.sizeBytes),
          ),
	        );
    await _outbox.enqueue(
      userId: userId,
      commandType: 'asset.upload',
      clientRequestId: const Uuid().v4(),
      payload: {
        'asset_id': asset.id,
        'local_path': asset.localPath,
        'storage_bucket': asset.storageBucket,
        'storage_path': asset.storagePath,
        'thumb_local_path': asset.thumbLocalPath,
        'thumb_storage_path': asset.thumbStoragePath,
        'sha256': asset.sha256,
        'mime_type': asset.mimeType,
        'width': asset.width,
        'height': asset.height,
        'size_bytes': asset.sizeBytes,
      },
    );
    return asset;
  }

  Future<void> markUploaded(String id) async {
    await (_db.update(_db.mealAssetsLocal)..where((tbl) => tbl.id.equals(id))).write(
      MealAssetsLocalCompanion(
        uploadStatus: const Value('uploaded'),
        uploadedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _outbox.markAssetUploadSynced(id);
  }

  Uint8List _encodeUnderTarget(img.Image image, int targetBytes) {
    for (final quality in [82, 76, 70, 64, 58]) {
      final bytes = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      if (bytes.length <= targetBytes || quality == 58) return bytes;
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 58));
  }
}
