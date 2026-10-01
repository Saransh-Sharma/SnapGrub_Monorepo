import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:uuid/uuid.dart';

/// A single weigh-in (always stored in kilograms).
@immutable
class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.measuredAt,
    required this.weightKg,
    this.source = 'manual',
  });

  final String id;
  final DateTime measuredAt;
  final double weightKg;
  final String source;
}

final bodyMeasurementRepositoryProvider =
    Provider<BodyMeasurementRepository>((ref) {
  return BodyMeasurementRepository(
    db: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxRepositoryProvider),
  );
});

/// Weigh-ins for the signed-in user, oldest first.
final weightEntriesProvider = StreamProvider<List<WeightEntry>>((ref) async* {
  final user = await ref.watch(homeUserContextProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(bodyMeasurementRepositoryProvider).watchWeights(user.userId);
});

/// Most recent weigh-in in kg, or null when none is recorded (or loading).
final latestWeightKgProvider = Provider<double?>((ref) {
  final entries = ref.watch(weightEntriesProvider).valueOrNull;
  if (entries == null || entries.isEmpty) return null;
  return entries.last.weightKg;
});

class BodyMeasurementRepository {
  BodyMeasurementRepository({
    required AppDatabase db,
    required OutboxRepository outbox,
  })  : _db = db,
        _outbox = outbox;

  final AppDatabase _db;
  final OutboxRepository _outbox;

  /// Weight entries, oldest first.
  ///
  /// The sync pull can store a server copy of a locally created weigh-in under
  /// a different id, so entries with the same timestamp and weight are
  /// collapsed into one.
  Stream<List<WeightEntry>> watchWeights(String userId) {
    final query = _db.select(_db.bodyMeasurementsLocal)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.weightKg.isNotNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.measuredAt)]);
    return query.watch().map((rows) {
      final seen = <String>{};
      final entries = <WeightEntry>[];
      for (final row in rows) {
        final kg = row.weightKg!;
        final key =
            '${row.measuredAt.toUtc().millisecondsSinceEpoch ~/ 1000}:${kg.toStringAsFixed(2)}';
        if (!seen.add(key)) continue;
        entries.add(WeightEntry(
          id: row.id,
          measuredAt: row.measuredAt.toLocal(),
          weightKg: kg,
          source: row.source,
        ));
      }
      return entries;
    });
  }

  /// Saves a weigh-in locally and queues it for sync
  /// (`body_measurement.create`, drained by the sync command repository).
  Future<WeightEntry> addWeight({
    required String userId,
    required double weightKg,
    DateTime? measuredAt,
  }) async {
    final id = const Uuid().v4();
    final at = (measuredAt ?? DateTime.now()).toUtc();
    await _db.into(_db.bodyMeasurementsLocal).insert(
          BodyMeasurementsLocalCompanion.insert(
            id: id,
            userId: userId,
            measuredAt: at,
            weightKg: Value(weightKg),
            source: const Value('manual'),
            syncStatus: const Value('pending'),
          ),
        );
    await _outbox.enqueue(
      userId: userId,
      commandType: 'body_measurement.create',
      clientRequestId: const Uuid().v4(),
      payload: {
        'id': id,
        'measured_at': at.toIso8601String(),
        'weight_kg': weightKg,
        'source': 'manual',
      },
    );
    return WeightEntry(id: id, measuredAt: at.toLocal(), weightKg: weightKg);
  }
}
