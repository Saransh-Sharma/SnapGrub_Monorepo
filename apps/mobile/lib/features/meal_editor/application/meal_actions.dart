import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/design_system/haptics.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

/// Meals hidden optimistically while their delete waits out the Undo window.
final pendingMealDeletionsProvider =
    NotifierProvider<PendingMealDeletions, Set<String>>(
  PendingMealDeletions.new,
);

class PendingMealDeletions extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void hide(String id) => state = {...state, id};
  void show(String id) => state = {...state}..remove(id);
}

/// Consistent meal actions with feedback. Every destructive action is
/// deferred behind an Undo snackbar; nothing is deleted instantly.
class MealActions {
  const MealActions._();

  static Future<void> deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    Meal meal,
  ) async {
    final pending = ref.read(pendingMealDeletionsProvider.notifier);
    final repository = ref.read(mealRepositoryProvider);
    SgHaptics.warn();
    pending.hide(meal.id);
    await showUndoSnackBar(
      context,
      message: '“${meal.title}” deleted',
      icon: Icons.delete_outline_rounded,
      onUndo: () => pending.show(meal.id),
      commit: () async {
        try {
          await repository.deleteMeal(meal);
        } finally {
          pending.show(meal.id);
        }
      },
    );
  }

  static Future<Meal?> duplicate(
    BuildContext context,
    WidgetRef ref,
    Meal meal,
  ) async {
    try {
      final copy = await ref.read(mealRepositoryProvider).duplicateMeal(meal);
      SgHaptics.logged();
      if (context.mounted) {
        showSgToast(context, 'Logged “${meal.title}” again',
            icon: Icons.copy_rounded);
      }
      return copy;
    } catch (error) {
      if (context.mounted) {
        showSgToast(context, friendlyError(error).message,
            icon: Icons.info_outline_rounded);
      }
      return null;
    }
  }

  /// After a brand-new meal is logged: "Logged · Undo" (undo removes it).
  static Future<void> announceLogged(
    BuildContext context,
    WidgetRef ref,
    Meal meal,
  ) async {
    final pending = ref.read(pendingMealDeletionsProvider.notifier);
    final repository = ref.read(mealRepositoryProvider);
    var undone = false;
    await showUndoSnackBar(
      context,
      message: 'Logged “${meal.title}” · ${Labels.kcal(meal.caloriesKcal)}',
      onUndo: () {
        undone = true;
        pending.hide(meal.id);
      },
      commit: () async {},
    );
    if (undone) {
      try {
        await repository.deleteMeal(meal);
      } finally {
        pending.show(meal.id);
      }
    }
  }
}
