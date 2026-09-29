import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_visuals/data/meal_visual_repository.dart';
import 'package:snapgrub/features/meal_visuals/presentation/meal_artwork.dart';

/// Photo (or artwork / soft gradient), editable serif title and the meal type
/// and time chips.
class MealReviewHeader extends StatelessWidget {
  const MealReviewHeader({
    required this.draft,
    required this.titleController,
    required this.onTitleChanged,
    required this.onTitleTap,
    required this.onPickMealType,
    required this.onPickTime,
    this.savedMeal,
    super.key,
  });

  final MealDraft draft;

  /// The persisted meal when editing; drives the shared-element artwork.
  final Meal? savedMeal;
  final TextEditingController titleController;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onTitleTap;
  final VoidCallback onPickMealType;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderVisual(draft: draft, savedMeal: savedMeal),
        const SizedBox(height: SnapGrubDesignTokens.space16),
        E2eId(
          id: 'meal.title',
          child: TextField(
            controller: titleController,
            onTap: onTitleTap,
            onChanged: onTitleChanged,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLines: null,
            style: theme.textTheme.headlineMedium,
            decoration: InputDecoration(
              hintText: 'Meal name',
              hintStyle: theme.textTheme.headlineMedium
                  ?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: .6)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: SnapGrubDesignTokens.space4),
              suffixIcon: Icon(Icons.edit_rounded,
                  size: SnapGrubDesignTokens.iconMd,
                  color: scheme.onSurfaceVariant),
              semanticCounterText: '',
            ),
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space12),
        Wrap(
          spacing: SnapGrubDesignTokens.space8,
          runSpacing: SnapGrubDesignTokens.space8,
          children: [
            E2eId(
              id: 'meal.type',
              child: _HeaderChip(
                icon: Labels.mealTypeIcon(draft.mealType),
                label: Labels.mealType(draft.mealType),
                semanticLabel:
                    'Meal type, ${Labels.mealType(draft.mealType)}. Change',
                onTap: onPickMealType,
              ),
            ),
            E2eId(
              id: 'meal.time',
              child: _HeaderChip(
                icon: Icons.schedule_rounded,
                label: Labels.when(draft.loggedAt),
                semanticLabel: 'Time, ${Labels.when(draft.loggedAt)}. Change',
                onTap: onPickTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    void activate() {
      SgHaptics.tap();
      onTap();
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: activate,
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: activate,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                minHeight: SnapGrubDesignTokens.minTapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: SnapGrubDesignTokens.space16,
                  vertical: SnapGrubDesignTokens.space8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: SnapGrubDesignTokens.iconSm, color: scheme.primary),
                  const SizedBox(width: SnapGrubDesignTokens.space8),
                  Flexible(
                    child: Text(label, style: theme.textTheme.labelLarge),
                  ),
                  const SizedBox(width: SnapGrubDesignTokens.space4),
                  Icon(Icons.expand_more_rounded,
                      size: SnapGrubDesignTokens.iconSm,
                      color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderVisual extends ConsumerWidget {
  const _HeaderVisual({required this.draft, this.savedMeal});

  final MealDraft draft;
  final Meal? savedMeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meal = savedMeal;
    if (meal != null) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: MealArtwork(
          meal: meal,
          hero: true,
          borderRadius: SnapGrubDesignTokens.radiusLg,
          showGenerationLabel: false,
        ),
      );
    }
    final assetId = draft.photoAssetId;
    if (assetId != null) {
      final path = ref.watch(mealAssetPathProvider(assetId)).valueOrNull;
      if (path != null && File(path).existsSync()) {
        return AspectRatio(
          aspectRatio: 16 / 10,
          child: Semantics(
            image: true,
            label: 'Your meal photo',
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(SnapGrubDesignTokens.radiusLg),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    StudioMealPlaceholder(title: draft.title),
              ),
            ),
          ),
        );
      }
    }
    return _GradientBand(mealType: draft.mealType);
  }
}

/// Soft brand gradient with the meal-type medallion, for meals with no photo.
class _GradientBand extends StatelessWidget {
  const _GradientBand({required this.mealType});

  final MealType mealType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.sg;
    final motion = SgMotion.of(context);
    return ExcludeSemantics(
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusLg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tokens.energy.soft,
              scheme.surfaceContainerLow,
              tokens.carbs.soft,
            ],
          ),
          border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .6)),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(SnapGrubDesignTokens.space20),
        child: AnimatedSwitcher(
          duration: motion.settle,
          child: Container(
            key: ValueKey(mealType),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
              boxShadow: tokens.elevation1,
            ),
            child: Icon(Labels.mealTypeIcon(mealType),
                size: SnapGrubDesignTokens.iconXl, color: scheme.primary),
          ),
        ),
      ),
    );
  }
}

/// Meal type picker as an SgSheet list. Returns the chosen type.
Future<MealType?> showMealTypeSheet(BuildContext context, MealType current) {
  return showSgSheet<MealType>(
    context: context,
    title: 'Meal type',
    builder: (context) {
      final theme = Theme.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in const [
            MealType.breakfast,
            MealType.lunch,
            MealType.dinner,
            MealType.snack,
            MealType.unknown,
          ])
            E2eId(
              id: 'meal.type.${type.name}',
              child: ListTile(
                minTileHeight: 56,
                selected: type == current,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(SnapGrubDesignTokens.radiusXs)),
                leading: Icon(Labels.mealTypeIcon(type)),
                title: Text(Labels.mealType(type)),
                trailing: type == current
                    ? Icon(Icons.check_rounded,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  SgHaptics.tick();
                  Navigator.of(context).pop(type);
                },
              ),
            ),
        ],
      );
    },
  );
}
