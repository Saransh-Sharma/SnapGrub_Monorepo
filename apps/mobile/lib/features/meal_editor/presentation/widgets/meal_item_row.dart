import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_editor/presentation/widgets/meal_review_logic.dart';

/// Compact, expandable item row.
///
/// Collapsed: name, "1 cup · 180 g", kcal and mini macros. Expanded: a
/// portion stepper that scales nutrition proportionally, and an "Edit
/// nutrition" disclosure with the raw fields. Every mutation calls
/// [onChanged] so the parent can refresh the live totals.
class MealItemRow extends StatefulWidget {
  const MealItemRow({
    required this.item,
    required this.index,
    required this.onChanged,
    this.onRemove,
    this.highlighted = false,
    this.working = false,
    this.autofocusName = false,
    super.key,
  });

  final MealDraftItem item;

  /// Position in the draft; used for stable E2E ids (`meal.item.<i>.*`).
  final int index;
  final VoidCallback onChanged;

  /// Null when the item can't be removed (the last item of a meal).
  final VoidCallback? onRemove;

  /// Briefly true after an AI correction changed this row.
  final bool highlighted;

  /// True while a correction is being worked out; the row shimmers.
  final bool working;
  final bool autofocusName;

  @override
  State<MealItemRow> createState() => _MealItemRowState();
}

class _MealItemRowState extends State<MealItemRow> {
  late bool _expanded;
  late bool _nutritionOpen;
  PortionBase? _base;

  /// Raw fields the user has emptied. They stay visually empty (and count as
  /// zero) instead of snapping back to "0" mid-edit.
  final Set<String> _cleared = {};

  MealDraftItem get _item => widget.item;

  @override
  void initState() {
    super.initState();
    final blank = _item.name.trim().isEmpty;
    _expanded = blank;
    _nutritionOpen = blank;
    if (_expanded) _base = PortionBase.capture(_item);
  }

  void _toggle() {
    SgHaptics.tap();
    setState(() {
      _expanded = !_expanded;
      // Re-captured at expand time so the stepper scales from what the user
      // sees now, including any raw edits made earlier.
      if (_expanded) _base = PortionBase.capture(_item);
    });
  }

  void _setQuantity(double quantity) {
    (_base ??= PortionBase.capture(_item)).applyTo(_item, quantity);
    _cleared.clear();
    setState(() {});
    widget.onChanged();
  }

  void _raw(String field, double? value, void Function(double? value) apply) {
    if (value == null) {
      _cleared.add(field);
    } else {
      _cleared.remove(field);
    }
    apply(value);
    _base = PortionBase.capture(_item);
    setState(() {});
    widget.onChanged();
  }

  void _text(void Function() apply) {
    apply();
    setState(() {});
    widget.onChanged();
  }

  double? _shown(String field, double? value) =>
      _cleared.contains(field) ? null : value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = SgMotion.of(context);
    final paper = theme.cardTheme.color ?? scheme.surfaceContainerLow;

    Widget row = AnimatedContainer(
      duration: motion.reveal,
      curve: motion.standard,
      decoration: BoxDecoration(
        color: widget.highlighted
            ? Color.alphaBlend(
                scheme.primaryContainer.withValues(alpha: .75), paper)
            : paper,
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusSm),
        border: Border.all(
          color: widget.highlighted
              ? scheme.primary.withValues(alpha: .45)
              : scheme.outlineVariant.withValues(alpha: .8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            AnimatedSize(
              duration: motion.settle,
              curve: motion.standard,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? _buildDetails(context)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );

    if (widget.working) {
      row = Stack(
        children: [
          Opacity(opacity: .45, child: row),
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: .7,
                child: SgSkeleton(radius: SnapGrubDesignTokens.radiusSm),
              ),
            ),
          ),
        ],
      );
    }
    return E2eId(id: 'meal.item.${widget.index}', child: row);
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.sg;
    final motion = SgMotion.of(context);
    final item = _item;
    final low = isLowConfidence(item);
    final name = item.name.trim().isEmpty ? 'New item' : item.name.trim();
    return Semantics(
      button: true,
      expanded: _expanded,
      label: itemSemanticLabel(item),
      hint: _expanded ? 'Collapse' : 'Adjust portion',
      onTap: widget.working ? null : _toggle,
      excludeSemantics: true,
      customSemanticsActions: widget.onRemove == null
          ? null
          : {
              const CustomSemanticsAction(label: 'Remove item'):
                  widget.onRemove!,
            },
      child: InkWell(
        onTap: widget.working ? null : _toggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SnapGrubDesignTokens.space16,
              SnapGrubDesignTokens.space12,
              SnapGrubDesignTokens.space12,
              SnapGrubDesignTokens.space12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: item.name.trim().isEmpty
                              ? scheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      const SizedBox(height: SnapGrubDesignTokens.space4),
                      Text(
                        [
                          portionLabel(item),
                          if (itemSourceLabel(item) case final source?) source,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      if (low) ...[
                        const SizedBox(height: SnapGrubDesignTokens.space4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: tokens.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: SnapGrubDesignTokens.space8),
                            Flexible(
                              child: Text(
                                'Check portion',
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(color: tokens.warning),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: SnapGrubDesignTokens.space8),
                      MacroChips(
                        proteinG: item.proteinG,
                        carbsG: item.carbsG,
                        fatG: item.fatG,
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: SnapGrubDesignTokens.space12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.caloriesKcal.round()}',
                      style:
                          tokens.metricSmall.copyWith(color: scheme.onSurface),
                    ),
                    Text(
                      'kcal',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: SnapGrubDesignTokens.space4),
                    AnimatedRotation(
                      turns: _expanded ? .5 : 0,
                      duration: motion.settle,
                      curve: motion.standard,
                      child: Icon(Icons.expand_more_rounded,
                          color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = SgMotion.of(context);
    final item = _item;
    final name = item.name.trim().isEmpty ? 'this item' : item.name.trim();
    final i = widget.index;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SnapGrubDesignTokens.space16,
        0,
        SnapGrubDesignTokens.space16,
        SnapGrubDesignTokens.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
              height: 1, color: scheme.outlineVariant.withValues(alpha: .6)),
          const SizedBox(height: SnapGrubDesignTokens.space12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: SnapGrubDesignTokens.space12,
            runSpacing: SnapGrubDesignTokens.space8,
            children: [
              Text('Portion', style: theme.textTheme.titleSmall),
              E2eId(
                id: 'meal.item.$i.stepper',
                child: SgStepper(
                  value: item.quantity,
                  step: .25,
                  min: .25,
                  max: 999,
                  semanticLabel: 'Portion of $name in ${item.unit}',
                  format: (value) {
                    final unit = item.unit.trim();
                    final amount = formatNumber(value, decimals: 2);
                    return unit.isEmpty ? amount : '$amount $unit';
                  },
                  onChanged: _setQuantity,
                ),
              ),
            ],
          ),
          const SizedBox(height: SnapGrubDesignTokens.space8),
          Text(
            'Nutrition updates with the portion.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (item.foodRefKind != 'manual' || item.confidence != null) ...[
            const SizedBox(height: SnapGrubDesignTokens.space12),
            Wrap(
              spacing: SnapGrubDesignTokens.space8,
              runSpacing: SnapGrubDesignTokens.space8,
              children: [
                if (item.foodRefKind != 'manual')
                  _InfoChip(
                    label: Labels.foodReference(item.foodRefKind),
                    icon: Icons.verified_outlined,
                    color: context.sg.info,
                  ),
                if (item.confidence != null)
                  _InfoChip(
                    label: Labels.confidence(item.confidence),
                    icon: Icons.auto_awesome_rounded,
                    color: isLowConfidence(item)
                        ? context.sg.warning
                        : scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
          const SizedBox(height: SnapGrubDesignTokens.space8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: SnapGrubDesignTokens.space8,
            children: [
              E2eId(
                id: 'meal.item.$i.edit_nutrition',
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize:
                        const Size(0, SnapGrubDesignTokens.minTapTarget),
                  ),
                  onPressed: () {
                    SgHaptics.tap();
                    setState(() => _nutritionOpen = !_nutritionOpen);
                  },
                  icon: AnimatedRotation(
                    turns: _nutritionOpen ? .5 : 0,
                    duration: motion.settle,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                  label: Text(
                      _nutritionOpen ? 'Hide nutrition' : 'Edit nutrition'),
                ),
              ),
              if (widget.onRemove != null)
                E2eId(
                  id: 'meal.item.$i.remove',
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize:
                          const Size(0, SnapGrubDesignTokens.minTapTarget),
                      foregroundColor: scheme.onSurfaceVariant,
                    ),
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove'),
                  ),
                ),
            ],
          ),
          AnimatedSize(
            duration: motion.settle,
            curve: motion.standard,
            alignment: Alignment.topCenter,
            child: _nutritionOpen
                ? _buildNutritionFields(context)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionFields(BuildContext context) {
    final item = _item;
    final i = widget.index;
    const gap = SizedBox(height: SnapGrubDesignTokens.space12);
    return Padding(
      padding: const EdgeInsets.only(top: SnapGrubDesignTokens.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          E2eId(
            id: 'meal.item.$i.food',
            child: TextFormField(
              key: ValueKey('food-${item.id}'),
              initialValue: item.name,
              autofocus: widget.autofocusName,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Food'),
              onChanged: (value) => _text(() => item.name = value),
            ),
          ),
          gap,
          _FieldGrid(
            children: [
              E2eId(
                id: 'meal.item.$i.qty',
                child: SgNumberField(
                  label: 'Amount',
                  value: _shown('qty', item.quantity),
                  nullable: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) =>
                      _raw('qty', v, (v) => item.quantity = v ?? 0),
                ),
              ),
              E2eId(
                id: 'meal.item.$i.unit',
                child: TextFormField(
                  key: ValueKey('unit-${item.id}'),
                  initialValue: item.unit,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  onChanged: (value) => _text(() => item.unit = value),
                ),
              ),
              E2eId(
                id: 'meal.item.$i.grams',
                child: SgNumberField(
                  label: 'Weight',
                  suffix: 'g',
                  value: item.gramsEstimated,
                  nullable: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) =>
                      _raw('grams', v, (v) => item.gramsEstimated = v),
                ),
              ),
            ],
          ),
          gap,
          _FieldGrid(
            children: [
              E2eId(
                id: 'meal.item.$i.kcal',
                child: SgNumberField(
                  label: 'Calories',
                  suffix: 'kcal',
                  value: _shown('kcal', item.caloriesKcal),
                  nullable: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) =>
                      _raw('kcal', v, (v) => item.caloriesKcal = v ?? 0),
                ),
              ),
              E2eId(
                id: 'meal.item.$i.protein',
                child: SgNumberField(
                  label: 'Protein',
                  suffix: 'g',
                  value: _shown('protein', item.proteinG),
                  nullable: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) =>
                      _raw('protein', v, (v) => item.proteinG = v ?? 0),
                ),
              ),
              E2eId(
                id: 'meal.item.$i.carbs',
                child: SgNumberField(
                  label: 'Carbs',
                  suffix: 'g',
                  value: _shown('carbs', item.carbsG),
                  nullable: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) =>
                      _raw('carbs', v, (v) => item.carbsG = v ?? 0),
                ),
              ),
              E2eId(
                id: 'meal.item.$i.fat',
                child: SgNumberField(
                  label: 'Fat',
                  suffix: 'g',
                  value: _shown('fat', item.fatG),
                  nullable: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) => _raw('fat', v, (v) => item.fatG = v ?? 0),
                ),
              ),
            ],
          ),
          gap,
          E2eId(
            id: 'meal.item.$i.notes',
            child: TextFormField(
              key: ValueKey('notes-${item.id}'),
              initialValue: item.notes,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes'),
              onChanged: (value) =>
                  _text(() => item.notes = value.trim().isEmpty ? null : value),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tinted label (food reference, confidence) that wraps at large text
/// sizes instead of overflowing.
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SnapGrubDesignTokens.space8,
        vertical: SnapGrubDesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: SnapGrubDesignTokens.iconSm, color: color),
          const SizedBox(width: SnapGrubDesignTokens.space4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays fields out in as many columns as fit, so large text sizes wrap to
/// one field per line instead of squeezing labels.
class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = SnapGrubDesignTokens.space8;
        final minWidth = 120 * scale;
        final fit = ((constraints.maxWidth + spacing) / (minWidth + spacing))
            .floor()
            .clamp(1, children.length);
        final columns = children.length == 4 && fit == 3 ? 2 : fit;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: SnapGrubDesignTokens.space12,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
