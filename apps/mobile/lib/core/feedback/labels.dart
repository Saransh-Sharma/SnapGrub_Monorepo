import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/core/design_system/components/status_pill.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

/// Human labels for internal values. UI code must never print `.name` of an
/// enum or a raw backend identifier; route it through here instead.
class Labels {
  const Labels._();

  static String mealType(MealType type) => switch (type) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
        MealType.unknown => 'Other',
      };

  static IconData mealTypeIcon(MealType type) => switch (type) {
        MealType.breakfast => Icons.wb_twilight_rounded,
        MealType.lunch => Icons.wb_sunny_rounded,
        MealType.dinner => Icons.nights_stay_rounded,
        MealType.snack => Icons.cookie_rounded,
        MealType.unknown => Icons.restaurant_rounded,
      };

  static String mealSource(MealSource source) => switch (source) {
        MealSource.photo => 'Photo',
        MealSource.barcode => 'Barcode',
        MealSource.text => 'Text',
        MealSource.voice => 'Voice',
        MealSource.manual => 'Manual',
        MealSource.duplicate => 'Repeat',
      };

  /// Null when the meal is synced: synced state needs no label at all.
  static ({String label, IconData icon, StatusTone tone})? mealSync(
      MealSyncStatus status) {
    return switch (status) {
      MealSyncStatus.synced => null,
      MealSyncStatus.pending => (
          label: 'Saved on phone',
          icon: Icons.cloud_upload_outlined,
          tone: StatusTone.neutral,
        ),
      MealSyncStatus.failed => (
          label: 'Not synced',
          icon: Icons.sync_problem_rounded,
          tone: StatusTone.attention,
        ),
    };
  }

  static String provenance(String? provenanceType) =>
      switch (provenanceType) {
        'ai_photo' || 'photo_ai' => 'Photo estimate',
        'barcode' => 'Barcode match',
        'text_parser' => 'Text estimate',
        'voice_parser' => 'Voice estimate',
        'label_ocr' => 'Nutrition label',
        'barcode_manual' => 'From the package',
        'manual' => 'Entered manually',
        'duplicate' => 'Logged again',
        'template' => 'From a saved meal',
        'agent' || 'conversation' => 'From chat',
        _ => 'Estimate',
      };

  static String foodReference(String kind) => switch (kind) {
        'canonical' => 'Verified food',
        'branded' => 'Packaged product',
        'custom' => 'Your food',
        _ => 'Estimated',
      };

  /// "High confidence" style wording from a 0..1 score.
  static String confidence(double? value) {
    if (value == null) return 'Not rated';
    if (value >= .8) return 'High confidence';
    if (value >= .6) return 'Medium confidence';
    return 'Low confidence';
  }

  static String outboxCommand(String commandType) => switch (commandType) {
        'meal.upsert' || 'meal.create' || 'meal.update' => 'Meal changes',
        'meal.delete' => 'Deleted meal',
        'meal.visual.create' => 'Meal image',
        'asset.upload' => 'Photo upload',
        'template.upsert' => 'Saved meal',
        'template.delete' => 'Deleted saved meal',
        'custom_food.upsert' => 'My food',
        'custom_food.delete' => 'Deleted food',
        'settings.patch' => 'Settings',
        'thread.message.create' => 'Chat message',
        'agent.proposal.acknowledge' => 'Chat suggestion',
        'analytics.batch' => 'Usage stats',
        _ => 'Change',
      };

  /// "Today, 1:05 PM" / "Yesterday, 8:30 AM" / "Mon 12 May, 7:10 PM".
  static String when(DateTime time, {DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final day = DateUtils.dateOnly(time);
    final clock = DateFormat.jm().format(time);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today, $clock';
    if (diff == 1) return 'Yesterday, $clock';
    if (diff == -1) return 'Tomorrow, $clock';
    return '${DateFormat('EEE d MMM').format(time)}, $clock';
  }

  /// "Today" / "Yesterday" / "Monday" (this week) / "Mon 12 May".
  static String day(DateTime date, {DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final day = DateUtils.dateOnly(date);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('EEE d MMM').format(date);
  }

  /// "in 3 days" / "2 hours ago" style relative time.
  static String relative(DateTime time, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final diff = time.difference(ref);
    final future = !diff.isNegative;
    final abs = diff.abs();
    String unit;
    if (abs.inMinutes < 1) return future ? 'in a moment' : 'just now';
    if (abs.inHours < 1) {
      unit = '${abs.inMinutes} min';
    } else if (abs.inDays < 1) {
      unit = count(abs.inHours, 'hour');
    } else {
      unit = count(abs.inDays, 'day');
    }
    return future ? 'in $unit' : '$unit ago';
  }

  /// "Asia/Kolkata" → "Kolkata"; "America/New_York" → "New York".
  static String timezone(String iana) {
    final last = iana.split('/').last;
    return last.replaceAll('_', ' ');
  }

  static String kcal(num value) =>
      '${NumberFormat.decimalPattern().format(value.round())} kcal';

  static String grams(num value) => '${value.round()} g';

  /// "1 meal" / "3 meals". Pass [plural] for irregular nouns.
  /// Grouped with the locale's separators: "1,240 meals".
  static String count(int n, String singular, [String? plural]) =>
      '${NumberFormat.decimalPattern().format(n)} '
      '${n == 1 ? singular : (plural ?? '${singular}s')}';
}
