import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:uuid/uuid.dart';

class E2eData {
  static const enabledFlags = <String, Object?>{
    'snapstrip.enabled': true,
    'photo_analysis.enabled': true,
    'barcode.enabled': true,
    'ocr_assist.enabled': true,
    'voice_capture.enabled': true,
    'weekly_insights.enabled': true,
  };

  static Future<void> ensureFeatureFlags(AppDatabase db) async {
    for (final entry in enabledFlags.entries) {
      await db.into(db.featureFlagsLocal).insertOnConflictUpdate(
            FeatureFlagsLocalCompanion.insert(
              key: entry.key,
              valueJson: jsonEncode(entry.value),
            ),
          );
    }
  }

  static String userIdForEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final safe = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'e2e-${safe.isEmpty ? 'user' : safe}';
  }

  static MealDraft mockDraft({
    required String userId,
    required String timezone,
    required MealSource source,
    required String title,
    String provenanceType = 'e2e_mock',
  }) {
    return MealDraft(
      userId: userId,
      timezone: timezone,
      title: title,
      source: source,
      mealType: MealType.lunch,
      confidenceOverall: source == MealSource.manual ? null : 0.92,
      provenanceType: provenanceType,
      analysisWarnings: source == MealSource.barcode
          ? const ['E2E barcode fallback. Review nutrition before saving.']
          : const [],
      items: [
        MealDraftItem(
          name: title,
          quantity: 1,
          unit: 'serving',
          gramsEstimated: 250,
          caloriesKcal: 420,
          proteinG: 24,
          carbsG: 48,
          fatG: 14,
          confidence: source == MealSource.manual ? null : 0.9,
          sourceType: provenanceType,
        ),
      ],
    );
  }

  static Future<CaptureAsset> fixtureAsset(String userId) async {
    final id = const Uuid().v4();
    final dir = await getApplicationDocumentsDirectory();
    final captureDir = Directory(p.join(dir.path, 'e2e-fixtures', userId));
    await captureDir.create(recursive: true);
    final localPath = p.join(captureDir.path, '$id.jpg');
    await File(localPath).writeAsBytes(_jpegBytes, flush: true);
    return CaptureAsset(
      id: id,
      userId: userId,
      createdAt: DateTime.now().toUtc(),
      localPath: localPath,
      storageBucket: 'meal-originals-private',
      storagePath: '$userId/$id.jpg',
      sha256: 'e2e-fixture-$id',
      mimeType: 'image/jpeg',
      sizeBytes: _jpegBytes.length,
      width: 1,
      height: 1,
    );
  }

  static final Uint8List _jpegBytes = Uint8List.fromList(const [
    0xff,
    0xd8,
    0xff,
    0xe0,
    0x00,
    0x10,
    0x4a,
    0x46,
    0x49,
    0x46,
    0x00,
    0x01,
    0x01,
    0x01,
    0x00,
    0x48,
    0x00,
    0x48,
    0x00,
    0x00,
    0xff,
    0xdb,
    0x00,
    0x43,
    0x00,
    0xff,
    0xc0,
    0x00,
    0x0b,
    0x08,
    0x00,
    0x01,
    0x00,
    0x01,
    0x01,
    0x01,
    0x11,
    0x00,
    0xff,
    0xc4,
    0x00,
    0x14,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x08,
    0xff,
    0xc4,
    0x00,
    0x14,
    0x10,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xff,
    0xda,
    0x00,
    0x08,
    0x01,
    0x01,
    0x00,
    0x00,
    0x3f,
    0x00,
    0x37,
    0xff,
    0xd9,
  ]);
}
