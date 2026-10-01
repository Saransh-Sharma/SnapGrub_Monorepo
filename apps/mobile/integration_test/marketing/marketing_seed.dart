// Realistic demo data for App Store / marketing captures: persona "Maya",
// a global-mix eater losing weight, with ~6 weeks of history, a gold-tier
// logging streak, a weigh-in trend and a lively "today".
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/features/conversation/data/conversation_repository.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_visuals/domain/meal_visual.dart';
import 'package:snapgrub/features/photo_analysis/application/analysis_queue_controller.dart';
import 'package:snapgrub/features/progress/data/body_measurement_repository.dart';
import 'package:snapgrub/features/progress/data/goal_weight_store.dart';

/// "Today" for every capture (matches the harness's fixed user day).
final marketingToday = DateTime(2026, 5, 30);

/// Wall-clock time shown in the app and the status bar.
final marketingNow = DateTime(2026, 5, 30, 12, 41);

const marketingHeroAssetId = 'marketing-hero-asset';

/// One dish on the menu: title, illustration id, and nutrition.
class Dish {
  const Dish(this.title, this.art, this.type, this.kcal, this.p, this.c, this.f,
      [this.items]);

  final String title;
  final String art;
  final MealType type;
  final double kcal;
  final double p;
  final double c;
  final double f;

  /// Optional component breakdown (name, kcal, p, c, f, qty, unit, grams).
  final List<(String, double, double, double, double, double, String, double)>?
      items;
}

const _breakfasts = [
  Dish('Overnight oats & berries', 'overnight-oats', MealType.breakfast, 380,
      16, 58, 10),
  Dish('Avocado toast & egg', 'avocado-toast', MealType.breakfast, 420, 18, 34,
      24),
  Dish('Greek yogurt bowl', 'greek-yogurt-bowl', MealType.breakfast, 330, 24,
      40, 8),
  Dish('Berry protein smoothie', 'berry-smoothie', MealType.breakfast, 290, 25,
      38, 5),
];
const _coffee = Dish('Flat white', 'flat-white', MealType.snack, 120, 7, 10, 6);
const _lunches = [
  Dish('Salmon poke bowl', 'poke-bowl', MealType.lunch, 610, 34, 68, 20),
  Dish('Chicken shawarma wrap', 'chicken-shawarma-wrap', MealType.lunch, 560,
      38, 52, 20),
  Dish('Chicken Caesar salad', 'caesar-salad', MealType.lunch, 480, 36, 22, 28),
  Dish('Sushi set', 'sushi-set', MealType.lunch, 520, 28, 74, 10),
  Dish('Rainbow grain bowl', 'hero-plate', MealType.lunch, 540, 24, 66, 18),
];
const _dinners = [
  Dish('Salmon, rice & greens', 'salmon-greens', MealType.dinner, 590, 40, 52,
      22),
  Dish('Dal, rice & roti', 'dal-rice', MealType.dinner, 540, 20, 88, 12),
  Dish(
      'Margherita pizza', 'margherita-pizza', MealType.dinner, 520, 22, 62, 18),
  Dish('Tonkotsu ramen', 'ramen', MealType.dinner, 680, 32, 78, 24),
];
const _snacks = [
  Dish('Apple & peanut butter', 'apple-peanut-butter', MealType.snack, 250, 7,
      28, 14),
  Dish('Dark chocolate', 'dark-chocolate', MealType.snack, 120, 2, 9, 9),
];

/// Title → illustration id, used to override meal visuals.
final Map<String, String> dishArt = {
  for (final d in [
    ..._breakfasts,
    _coffee,
    ..._lunches,
    ..._dinners,
    ..._snacks
  ])
    d.title: d.art,
};

/// The photo "being analysed" on Today, and the review draft it becomes.
const heroDish = Dish(
  'Rainbow grain bowl',
  'hero-plate',
  MealType.lunch,
  560,
  26,
  64,
  20,
  [
    ('Quinoa', 180, 7, 32, 3, 1, 'cup', 185),
    ('Roasted sweet potato', 120, 2, 27, 0.5, 0.75, 'cup', 100),
    ('Avocado', 120, 1.5, 6, 11, 0.5, 'fruit', 70),
    ('Soft-boiled egg', 70, 6, 0.5, 5, 1, 'egg', 50),
    ('Chickpeas & kale', 70, 9.5, -1.5, 0.5, 0.5, 'cup', 80),
  ],
);

MealDraft draftFor(Dish d, DateTime at, String userId, String timezone,
    {String? photoAssetId, MealSource source = MealSource.manual}) {
  final items =
      d.items ?? [(d.title, d.kcal, d.p, d.c, d.f, 1.0, 'serving', 0.0)];
  return MealDraft(
    userId: userId,
    timezone: timezone,
    title: d.title,
    source: source,
    mealType: d.type,
    loggedAt: at,
    photoAssetId: photoAssetId,
    provenanceType: source == MealSource.photo ? 'ai_photo' : null,
    confidenceOverall: source == MealSource.photo ? .86 : null,
    items: [
      for (final (name, kcal, p, c, f, qty, unit, grams) in items)
        MealDraftItem(
          name: name,
          quantity: qty,
          unit: unit,
          gramsEstimated: grams == 0 ? null : grams,
          caloriesKcal: kcal,
          proteinG: p,
          carbsG: math.max(0, c),
          fatG: f,
          confidence: source == MealSource.photo
              ? (name == 'Chickpeas & kale' ? .62 : .9)
              : null,
        ),
    ],
  );
}

/// Seeds the database for [userId]. Returns the analysis job to show on Today.
Future<void> seedMarketingData({
  required AppDatabase db,
  required ProviderContainer container,
  required String userId,
  required String timezone,
}) async {
  // Profile: Maya, losing weight on a 1,850 kcal plan.
  await (db.update(db.profilesLocal)..where((t) => t.id.equals(userId))).write(
    const ProfilesLocalCompanion(
      displayName: Value('Maya'),
      cuisinePreferencesJson:
          Value('["mediterranean","japanese","indian","american"]'),
    ),
  );
  await db.into(db.nutritionGoalsLocal).insertOnConflictUpdate(
        NutritionGoalsLocalCompanion.insert(
          id: 'goal-$userId',
          userId: userId,
          goalType: 'lose',
          caloriesKcal: 1850,
          proteinG: 130,
          carbsG: 190,
          fatG: 62,
          startsOn: marketingToday.subtract(const Duration(days: 60)),
          syncStatus: const Value('synced'),
        ),
      );
  await GoalWeightStore.save(userId, 63);

  final meals = container.read(mealRepositoryProvider);
  final rnd = math.Random(7);
  DateTime at(DateTime day, int h, int m) =>
      DateTime(day.year, day.month, day.day, h, m + rnd.nextInt(20));

  // History: days 1–43 back. A 34-day streak (with one freeze on day 12),
  // a two-day break, then an earlier stretch.
  for (var back = 43; back >= 1; back--) {
    if (back == 12 || back == 35 || back == 36) continue;
    final day = marketingToday.subtract(Duration(days: back));
    final b = _breakfasts[rnd.nextInt(_breakfasts.length)];
    final l = _lunches[rnd.nextInt(_lunches.length)];
    final d = _dinners[rnd.nextInt(_dinners.length)];
    await meals.saveDraft(draftFor(b, at(day, 7, 50), userId, timezone));
    if (rnd.nextDouble() < .6) {
      await meals
          .saveDraft(draftFor(_coffee, at(day, 8, 20), userId, timezone));
    }
    await meals.saveDraft(draftFor(l, at(day, 13, 5), userId, timezone));
    if (rnd.nextDouble() < .5) {
      final s = _snacks[rnd.nextInt(_snacks.length)];
      await meals.saveDraft(draftFor(s, at(day, 16, 30), userId, timezone));
    }
    await meals.saveDraft(draftFor(d, at(day, 19, 45), userId, timezone));
  }

  // Today (12:41): breakfast, coffee and a snack logged.
  await meals.saveDraft(
      draftFor(_breakfasts[0], DateTime(2026, 5, 30, 8, 5), userId, timezone));
  await meals.saveDraft(
      draftFor(_coffee, DateTime(2026, 5, 30, 8, 12), userId, timezone));
  await meals.saveDraft(
      draftFor(_snacks[0], DateTime(2026, 5, 30, 11, 2), userId, timezone));

  // Weigh-ins: 69.4 → 66.1 kg over six weeks, with realistic noise.
  final weights = container.read(bodyMeasurementRepositoryProvider);
  for (var back = 42; back >= 0; back -= 2) {
    final t = 1 - back / 42;
    final kg = 69.4 - 3.3 * t + math.sin(back * 1.7) * .32;
    await weights.addWeight(
      userId: userId,
      weightKg: double.parse(kg.toStringAsFixed(1)),
      measuredAt: DateTime(marketingToday.year, marketingToday.month,
          marketingToday.day - back, 7, 10),
    );
  }

  // Chat: planning dinner; the assistant proposes a meal to confirm.
  final conversation = container.read(conversationRepositoryProvider);
  final thread = await conversation.ensureThread(
      userId: userId, day: marketingToday, timezone: timezone);
  final user = await conversation.addMessage(
    thread: thread,
    role: ThreadMessageRole.user,
    kind: ThreadMessageKind.text,
    text: 'Planning salmon, rice and some greens for dinner',
  );
  final reply = await conversation.addMessage(
    thread: thread,
    role: ThreadMessageRole.assistant,
    kind: ThreadMessageKind.text,
    text:
        'Nice choice — about 590 kcal with 40 g protein. Add it now or tweak the portions first.',
  );
  final proposal = await conversation.stageProposal(
    thread: thread,
    messageId: reply.id,
    draft: draftFor(
        _dinners[0], DateTime(2026, 5, 30, 19, 30), userId, timezone,
        source: MealSource.text),
  );
  // Pin the chat to lunchtime so it sits in the right part of the day.
  final userAt = DateTime(2026, 5, 30, 12, 34).toUtc();
  final replyAt = DateTime(2026, 5, 30, 12, 35).toUtc();
  await (db.update(db.threadMessagesLocal)..where((t) => t.id.equals(user.id)))
      .write(ThreadMessagesLocalCompanion(createdAt: Value(userAt)));
  await (db.update(db.threadMessagesLocal)..where((t) => t.id.equals(reply.id)))
      .write(ThreadMessagesLocalCompanion(createdAt: Value(replyAt)));
  await (db.update(db.mealChangeProposalsLocal)
        ..where((t) => t.id.equals(proposal.id)))
      .write(MealChangeProposalsLocalCompanion(createdAt: Value(replyAt)));
}

/// Meal visual pointing at the illustration for [meal], if we have one.
MealVisual? marketingVisual(Meal meal, String artDir) {
  final art = dishArt[meal.title];
  if (art == null) return null;
  return MealVisual(
    id: 'visual-${meal.id}',
    mealId: meal.id,
    userId: meal.userId,
    promptSignature: 'marketing',
    styleVersion: 'marketing-illustration-v1',
    status: MealVisualStatus.ready,
    localPath: '$artDir/$art.png',
  );
}

/// The lunch photo being analysed on Today.
AnalysisJob heroJob(String userId, String artDir, AnalysisJobStatus status) {
  final asset = CaptureAsset(
    id: marketingHeroAssetId,
    userId: userId,
    createdAt: DateTime(2026, 5, 30, 12, 20),
    localPath: '$artDir/hero-plate.png',
    thumbLocalPath: '$artDir/hero-plate.png',
    storageBucket: 'marketing',
    storagePath: 'marketing/hero-plate.png',
    sha256: 'marketing',
    mimeType: 'image/png',
    sizeBytes: 1,
    width: 1200,
    height: 1200,
  );
  return AnalysisJob(
    id: 'marketing-job',
    asset: asset,
    day: DateUtils.dateOnly(marketingToday),
    status: status,
    startedAt: DateTime(2026, 5, 30, 12, 20),
    draft: status == AnalysisJobStatus.ready
        ? draftFor(
            heroDish, DateTime(2026, 5, 30, 12, 20), userId, 'Asia/Kolkata',
            photoAssetId: marketingHeroAssetId, source: MealSource.photo)
        : null,
  );
}

/// Analysis queue that starts with a fixed job and never calls the network.
class MarketingAnalysisQueue extends AnalysisQueueController {
  MarketingAnalysisQueue(this.initial);

  final List<AnalysisJob> initial;

  @override
  List<AnalysisJob> build() => initial;

  void show(AnalysisJob job) => state = [job];
}
