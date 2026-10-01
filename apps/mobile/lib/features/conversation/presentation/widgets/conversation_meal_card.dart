import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feature_flags/feature_flags.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/features/conversation/application/conversation_controller.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';
import 'package:snapgrub/features/meal_editor/application/meal_actions.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_visuals/data/meal_visual_repository.dart';
import 'package:snapgrub/features/meal_visuals/presentation/meal_artwork.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

/// A logged meal on Today: artwork thumbnail, title, time, kcal and macros.
/// Swipe to dissolve-delete (with Undo); tap for details and actions.
class ConfirmedMealCard extends ConsumerStatefulWidget {
  const ConfirmedMealCard(
      {required this.meal, this.highlight = false, super.key});

  final Meal meal;
  final bool highlight;

  @override
  ConsumerState<ConfirmedMealCard> createState() => _ConfirmedMealCardState();
}

class _ConfirmedMealCardState extends ConsumerState<ConfirmedMealCard>
    with TickerProviderStateMixin {
  late final AnimationController _drag =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _dissolve = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _pastThreshold = false;
  late bool _highlight = widget.highlight;

  static const _threshold = .38;

  @override
  void initState() {
    super.initState();
    if (_highlight) {
      Future<void>.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) setState(() => _highlight = false);
      });
    }
  }

  @override
  void dispose() {
    _drag.dispose();
    _dissolve.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    final next = (_drag.value + details.primaryDelta! / width).clamp(-1.0, 0.0);
    _drag.value = next;
    final past = next.abs() > _threshold;
    if (past != _pastThreshold) {
      _pastThreshold = past;
      past ? SgHaptics.warn() : SgHaptics.tick();
    }
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final fling = (details.primaryVelocity ?? 0) < -900;
    if (_pastThreshold || fling) {
      await _deleteWithDissolve();
    } else {
      await _drag.animateTo(0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack);
    }
    _pastThreshold = false;
  }

  Future<void> _deleteWithDissolve() async {
    if (SgMotion.of(context).reduced || !SgEffectsScope.of(context).shaders) {
      _drag.value = 0;
    } else {
      await _dissolve.forward(from: 0);
    }
    if (!mounted) return;
    await MealActions.deleteWithUndo(context, ref, widget.meal);
    if (mounted) {
      _dissolve.value = 0;
      _drag.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final theme = Theme.of(context);
    final tokens = context.sg;
    final motion = SgMotion.of(context);
    final sync = Labels.mealSync(meal.syncStatus);
    final label = '${meal.title}, ${Labels.mealType(meal.mealType)} at '
        '${DateFormat.jm().format(meal.loggedAt)}, '
        '${meal.caloriesKcal.round()} calories';

    final card = AnimatedContainer(
      duration: motion.reveal,
      curve: motion.standard,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: _highlight
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: .28),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : const [],
      ),
      child: SgCard(
        padding: const EdgeInsets.all(10),
        onTap: () => _showDetails(context),
        semanticLabel: label,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox.square(
                dimension: 72,
                child: MealArtwork(
                  meal: meal,
                  borderRadius: 0,
                  hero: true,
                  showGenerationLabel: false,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meal.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${meal.caloriesKcal.round()}',
                          style: tokens.metricSmall),
                      Padding(
                        padding: const EdgeInsets.only(left: 3, top: 2),
                        child: Text('kcal', style: theme.textTheme.labelSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Labels.mealTypeIcon(meal.mealType),
                          size: 13, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${Labels.mealType(meal.mealType)} · ${DateFormat.jm().format(meal.loggedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      if (sync != null) ...[
                        const SizedBox(width: 6),
                        Icon(sync.icon,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  MacroChips(
                    proteinG: meal.proteinG,
                    carbsG: meal.carbsG,
                    fatG: meal.fatG,
                    dense: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return E2eId(
      id: 'conversation.meal.${meal.id}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            onHorizontalDragUpdate: (d) => _onDragUpdate(d, width),
            onHorizontalDragEnd: _onDragEnd,
            onLongPress: () {
              SgHaptics.impact();
              _showDetails(context);
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _drag,
                    builder: (context, _) {
                      final t =
                          (_drag.value.abs() / _threshold).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: t,
                        child: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer
                                .withValues(alpha: .6 * t),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Transform.scale(
                            scale: .7 + .3 * t,
                            child: Icon(Icons.delete_outline_rounded,
                                color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                AnimatedBuilder(
                  animation: _drag,
                  child: DissolveTransition(
                    progress: _dissolve,
                    direction: const Offset(-1, 0),
                    child: card,
                  ),
                  builder: (context, child) => Transform.translate(
                    offset: Offset(_drag.value * width, 0),
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final meal = widget.meal;
    final theme = Theme.of(context);
    final tokens = context.sg;
    showSgSheet<void>(
      context: context,
      title: meal.title,
      subtitle:
          '${Labels.mealType(meal.mealType)} · ${Labels.when(meal.loggedAt)} · ${Labels.mealSource(meal.source)}',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${meal.caloriesKcal.round()}', style: tokens.metric),
              const SizedBox(width: 6),
              Text('kcal', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          MacroBar(
            proteinG: meal.proteinG,
            carbsG: meal.carbsG,
            fatG: meal.fatG,
          ),
          const SizedBox(height: 10),
          MacroChips(
            proteinG: meal.proteinG,
            carbsG: meal.carbsG,
            fatG: meal.fatG,
          ),
          if (meal.items.isNotEmpty) ...[
            const SgSectionHeader(title: 'Items'),
            for (final item in meal.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} · ${formatNumber(item.quantity, decimals: 2)} ${item.unit}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text('${item.caloriesKcal.round()} kcal',
                        style: theme.textTheme.labelMedium),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 8),
          Text('Meal images may be AI-generated.',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          SgSheetAction(
            icon: Icons.tune_rounded,
            label: 'Edit meal',
            onTap: () {
              Navigator.pop(sheetContext);
              context.push('/meal-editor?id=${meal.id}');
            },
          ),
          SgSheetAction(
            icon: Icons.copy_rounded,
            label: 'Log again',
            subtitle: 'Adds it at the current time',
            onTap: () {
              Navigator.pop(sheetContext);
              MealActions.duplicate(context, ref, meal);
            },
          ),
          SgSheetAction(
            icon: Icons.delete_outline_rounded,
            label: 'Delete meal',
            destructive: true,
            onTap: () {
              Navigator.pop(sheetContext);
              _deleteWithDissolve();
            },
          ),
        ],
      ),
    );
  }
}

/// An AI draft waiting for the user's confirmation.
class ProposalMealCard extends ConsumerStatefulWidget {
  const ProposalMealCard({required this.proposal, super.key});

  final MealChangeProposal proposal;

  @override
  ConsumerState<ProposalMealCard> createState() => _ProposalMealCardState();
}

class _ProposalMealCardState extends ConsumerState<ProposalMealCard> {
  bool _working = false;
  bool _committed = false;
  final _ripple = RippleController();

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.proposal.draft;
    final theme = Theme.of(context);
    final tokens = context.sg;
    final motion = SgMotion.of(context);
    final operation = widget.proposal.operation;
    final headline = switch (operation) {
      ProposalOperation.create => _committed ? 'Logged' : 'Review meal',
      ProposalOperation.update => _committed ? 'Updated' : 'Suggested change',
      ProposalOperation.delete => _committed ? 'Deleted' : 'Delete this meal?',
    };
    return E2eId(
      id: 'conversation.proposal.${widget.proposal.id}',
      child: SgRipple(
        controller: _ripple,
        child: SgCard(
          variant: SgCardVariant.raised,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: motion.settle,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      _committed
                          ? Icons.check_circle_rounded
                          : Icons.auto_awesome_rounded,
                      key: ValueKey(_committed),
                      size: 18,
                      color: _committed
                          ? tokens.success
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    headline,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _committed
                          ? tokens.success
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox.square(
                      dimension: 58,
                      child: StudioMealPlaceholder(title: draft.title),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(draft.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${Labels.count(draft.items.length, 'item')} · ${Labels.mealType(draft.mealType)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  RollingNumber(
                    value: draft.caloriesKcal.round(),
                    suffix: ' kcal',
                    style: tokens.metricSmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              MacroChips(
                proteinG: draft.proteinG,
                carbsG: draft.carbsG,
                fatG: draft.fatG,
                dense: true,
              ),
              AnimatedSize(
                duration: motion.settle,
                curve: motion.standard,
                child: _committed
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (operation != ProposalOperation.delete) ...[
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _working ? null : _editProposal,
                                      child: const Text('Edit'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  flex: 2,
                                  child: E2eId(
                                    id: 'conversation.proposal.confirm',
                                    child: FilledButton.icon(
                                      onPressed: _working ? null : _confirm,
                                      icon: _working
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : const Icon(Icons.check_rounded),
                                      label: Text(switch (operation) {
                                        ProposalOperation.create => 'Log meal',
                                        ProposalOperation.update =>
                                          'Save change',
                                        ProposalOperation.delete =>
                                          'Delete meal',
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _working
                                  ? null
                                  : () => ref
                                      .read(conversationControllerProvider
                                          .notifier)
                                      .rejectProposal(widget.proposal),
                              child: const Text('Dismiss'),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _working = true);
    try {
      final meal = await ref
          .read(conversationControllerProvider.notifier)
          .confirmProposal(widget.proposal);
      if (!mounted) return;
      _ripple.fire();
      setState(() => _committed = true);
      final profile = ref.read(profileControllerProvider).valueOrNull;
      if (meal != null &&
          FeatureFlags(profile?.featureFlags ?? const {})
              .isEnabled(FeatureFlag.generatedMealVisuals)) {
        await ref.read(mealVisualRepositoryProvider).request(meal);
        await ref
            .read(syncControllerProvider.notifier)
            .syncNow(trigger: SyncTrigger.foreground);
      }
    } catch (error) {
      if (mounted) {
        SgHaptics.warn();
        showSgToast(
            context,
            error is ProposalTargetMissing
                ? error.message
                : friendlyError(error).message,
            icon: Icons.info_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _editProposal() {
    final proposal = widget.proposal;
    if (proposal.operation == ProposalOperation.update &&
        proposal.targetMealId != null) {
      final json = mealDraftToJson(proposal.draft)
        ..['id'] = proposal.targetMealId
        ..['expected_revision'] = proposal.expectedRevision;
      context.push(
        '/meal-editor',
        extra: mealDraftFromJson(Map<String, dynamic>.from(json)),
      );
      return;
    }
    context.push('/meal-editor', extra: proposal.draft);
  }
}
