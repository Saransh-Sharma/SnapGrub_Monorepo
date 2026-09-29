import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';

/// Persists which milestones have already been celebrated, per user.
///
/// Key: `milestones.celebrated.<userId>` (string list). A missing key means
/// the user has never been evaluated on this install — see
/// `MilestoneCelebrator` for how that first evaluation is seeded silently.
class MilestoneStore {
  const MilestoneStore();

  static String key(String userId) => 'milestones.celebrated.$userId';

  /// Null when this user has never been evaluated on this install.
  Future<Set<String>?> celebrated(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key(userId))?.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<Set<String>> markCelebrated(String userId, Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final next = {...?prefs.getStringList(key(userId)), ...ids};
    await prefs.setStringList(key(userId), next.toList()..sort());
    return next;
  }
}

final milestoneStoreProvider = Provider<MilestoneStore>((ref) {
  return const MilestoneStore();
});

/// Template count and first creation time, straight from the local table
/// (the template domain model does not carry `createdAt`).
typedef TemplateStats = ({int count, DateTime? firstCreatedAt});

Stream<TemplateStats> watchTemplateStats(AppDatabase db, String userId) {
  final query = db.select(db.mealTemplatesLocal)
    ..where((tbl) => tbl.userId.equals(userId) & tbl.deletedAt.isNull())
    ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
  return query.watch().map((rows) => (
        count: rows.length,
        firstCreatedAt: rows.isEmpty ? null : rows.first.createdAt.toLocal(),
      ));
}
