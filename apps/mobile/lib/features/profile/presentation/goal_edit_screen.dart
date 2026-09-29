import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/router/nav.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/onboarding/domain/plan_calculator.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/profile/domain/profile.dart';
import 'package:snapgrub/features/progress/data/body_measurement_repository.dart';
import 'package:snapgrub/features/progress/data/goal_weight_store.dart';

/// Supported ranges; mirror `OnboardingDraft.validate` so users see inline
/// errors instead of a failed save.
class _Range {
  const _Range(this.min, this.max, this.label, this.unit);
  final double min;
  final double max;
  final String label;
  final String unit;

  String? check(double? value) {
    if (value == null) return 'Enter your $label target';
    if (value < min || value > max) {
      final f = NumberFormat.decimalPattern();
      return 'Use ${f.format(min)}–${f.format(max)} $unit';
    }
    return null;
  }
}

const _caloriesRange = _Range(500, 6000, 'calorie', 'kcal');
const _proteinRange = _Range(0, 500, 'protein', 'g');
const _carbsRange = _Range(0, 800, 'carbs', 'g');
const _fatRange = _Range(0, 400, 'fat', 'g');

const _goalLabels = {
  'lose': 'Lose',
  'maintain': 'Maintain',
  'gain': 'Gain',
  'custom': 'Custom',
};

/// `/settings/goal`: edit daily calorie and macro targets.
class GoalEditScreen extends ConsumerStatefulWidget {
  const GoalEditScreen({super.key});

  @override
  ConsumerState<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends ConsumerState<GoalEditScreen> {
  String _goalType = 'lose';
  double? _calories = 1900;
  double? _protein = 130;
  double? _carbs = 190;
  double? _fat = 60;

  /// Profile captured once loaded; the controller drops its value while a
  /// save is in flight, so the screen keeps its own copy.
  UserProfile? _profile;
  bool _seeded = false;
  bool _dirty = false;
  bool _showRequired = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  void _seed() {
    final state = ref.read(profileControllerProvider).valueOrNull;
    if (state == null) return;
    _profile = state.profile;
    final goal = state.activeGoal;
    if (goal != null) {
      _goalType = _goalLabels.containsKey(goal.goalType) ? goal.goalType : 'custom';
      _calories = goal.caloriesKcal.roundToDouble();
      _protein = goal.proteinG.roundToDouble();
      _carbs = goal.carbsG.roundToDouble();
      _fat = goal.fatG.roundToDouble();
    }
    _seeded = true;
  }

  void _edit(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
      _error = null;
    });
  }

  bool get _valid =>
      _caloriesRange.check(_calories) == null &&
      _proteinRange.check(_protein) == null &&
      _carbsRange.check(_carbs) == null &&
      _fatRange.check(_fat) == null;

  String? _errorFor(_Range range, double? value) {
    final error = range.check(value);
    if (error == null) return null;
    if (value == null && !_showRequired) return null;
    return error;
  }

  Future<void> _save() async {
    final profile = _profile;
    if (!_valid) {
      setState(() => _showRequired = true);
      SgHaptics.warn();
      return;
    }
    if (profile == null) {
      setState(() => _error = 'Your profile is still loading. Try again.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final draft = OnboardingDraft(
        displayName: profile.displayName ?? '',
        goalType: _goalType,
        unitSystem: profile.unitSystem,
        locale: profile.locale,
        timezone: profile.timezone,
        countryCode: profile.countryCode ?? 'IN',
        cuisinePreferences: profile.cuisinePreferences,
        caloriesKcal: _calories!,
        proteinG: _protein!,
        carbsG: _carbs!,
        fatG: _fat!,
        cameraPrimerSeen: true,
      );
      await ref
          .read(profileControllerProvider.notifier)
          .completeOnboarding(profile.id, draft);
      if (!mounted) return;
      SgHaptics.logged();
      _dirty = false;
      showSgToast(context, 'Targets saved');
      context.popOrGo('/settings');
    } catch (error) {
      // The controller leaves itself loading after a failed save; reload the
      // local copy so the rest of the app recovers.
      ref.invalidate(profileControllerProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyError(error).message;
      });
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await confirmDestructive(
      context,
      title: 'Discard changes?',
      message: 'Your new targets won’t be saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      icon: Icons.undo_rounded,
    );
    if (leave && mounted) {
      setState(() => _dirty = false);
      context.popOrGo('/settings');
    }
  }

  /// Back honours the unsaved-changes guard and still works after a deep
  /// link (nothing to pop → go to the You tab).
  Future<void> _back() async {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      if (_dirty) {
        await _confirmLeave();
      } else {
        context.popOrGo('/settings');
      }
      return;
    }
    await navigator.maybePop();
  }

  void _applyPlan(NutritionPlan plan) {
    SgHaptics.tick();
    _edit(() {
      _calories = plan.caloriesKcal;
      _protein = plan.proteinG;
      _carbs = plan.carbsG;
      _fat = plan.fatG;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    if (!_seeded && profileState.hasValue) _seed();
    _profile ??= profileState.valueOrNull?.profile;

    final theme = Theme.of(context);
    final latestWeight = ref.watch(latestWeightKgProvider);
    final goalWeight = ref.watch(goalWeightProvider).valueOrNull;
    final metric = (_profile?.unitSystem ?? 'metric') != 'imperial';

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: E2eId(
        id: 'scaffold.edit_goal',
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Goal & targets'),
            leading: BackButton(onPressed: _back),
          ),
          body: PremiumBackdrop(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: SnapGrubDesignTokens.maxContentWidth,
                        ),
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            _PreviewCard(
                              calories: _calories,
                              protein: _protein ?? 0,
                              carbs: _carbs ?? 0,
                              fat: _fat ?? 0,
                            ),
                            const SgSectionHeader(title: 'Goal'),
                            SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: [
                                for (final entry in _goalLabels.entries)
                                  ButtonSegment(
                                    value: entry.key,
                                    label: Text(entry.value),
                                  ),
                              ],
                              selected: {_goalType},
                              onSelectionChanged: (value) {
                                SgHaptics.tick();
                                _edit(() => _goalType = value.single);
                              },
                            ),
                            if (latestWeight != null)
                              _RecalculateCard(
                                weightKg: latestWeight,
                                targetWeightKg: goalWeight,
                                goalType: _goalType,
                                metric: metric,
                                onApply: _applyPlan,
                              ),
                            const SgSectionHeader(title: 'Daily targets'),
                            E2eId(
                              id: 'settings.goal.calories',
                              child: SgNumberField(
                                label: 'Calories',
                                suffix: 'kcal',
                                value: _calories,
                                nullable: true,
                                decimal: false,
                                errorText: _errorFor(_caloriesRange, _calories),
                                textInputAction: TextInputAction.next,
                                onChanged: (v) => _edit(() => _calories = v),
                              ),
                            ),
                            const SizedBox(height: 12),
                            E2eId(
                              id: 'settings.goal.protein',
                              child: SgNumberField(
                                label: 'Protein',
                                suffix: 'g',
                                value: _protein,
                                nullable: true,
                                decimal: false,
                                errorText: _errorFor(_proteinRange, _protein),
                                textInputAction: TextInputAction.next,
                                onChanged: (v) => _edit(() => _protein = v),
                              ),
                            ),
                            const SizedBox(height: 12),
                            E2eId(
                              id: 'settings.goal.carbs',
                              child: SgNumberField(
                                label: 'Carbs',
                                suffix: 'g',
                                value: _carbs,
                                nullable: true,
                                decimal: false,
                                errorText: _errorFor(_carbsRange, _carbs),
                                textInputAction: TextInputAction.next,
                                onChanged: (v) => _edit(() => _carbs = v),
                              ),
                            ),
                            const SizedBox(height: 12),
                            E2eId(
                              id: 'settings.goal.fat',
                              child: SgNumberField(
                                label: 'Fat',
                                suffix: 'g',
                                value: _fat,
                                nullable: true,
                                decimal: false,
                                errorText: _errorFor(_fatRange, _fat),
                                textInputAction: TextInputAction.done,
                                onChanged: (v) => _edit(() => _fat = v),
                              ),
                            ),
                            _MacroMismatchNote(
                              calories: _calories,
                              protein: _protein,
                              carbs: _carbs,
                              fat: _fat,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              InlineError(message: _error!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  _SaveBar(
                    saving: _saving,
                    onSave: _saving ? null : _save,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saving,
    required this.onSave,
    required this.theme,
  });

  final bool saving;
  final VoidCallback? onSave;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: .94),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: E2eId(
              id: 'settings.goal.save',
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: onSave,
                child: saving
                    ? Semantics(
                        label: 'Saving',
                        child: const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Text('Save targets'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark hero card: the calorie target plus the live macro split.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double? calories;
  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final kcal = calories ?? 0;
    final energy = protein * 4 + carbs * 4 + fat * 9;
    String pct(double grams, double factor) => energy <= 0
        ? '–'
        : '${(grams * factor / energy * 100).round()}%';
    return SgCard(
      variant: SgCardVariant.hero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily target',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: tokens.onHeroMuted),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RollingNumber(
                  value: kcal.round(),
                  style: tokens.metric
                      .copyWith(color: tokens.onHero, fontSize: 40),
                  semanticsLabel: '${kcal.round()} calories a day',
                ),
                const SizedBox(width: 6),
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'kcal',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: tokens.onHeroMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MacroBar(proteinG: protein, carbsG: carbs, fatG: fat, height: 12),
          const SizedBox(height: 12),
          DefaultTextStyle.merge(
            style: TextStyle(color: tokens.onHero),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _HeroLegend(
                  color: tokens.protein.color,
                  text: 'Protein ${protein.round()} g · ${pct(protein, 4)}',
                ),
                _HeroLegend(
                  color: tokens.carbs.color,
                  text: 'Carbs ${carbs.round()} g · ${pct(carbs, 4)}',
                ),
                _HeroLegend(
                  color: tokens.fat.color,
                  text: 'Fat ${fat.round()} g · ${pct(fat, 9)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLegend extends StatelessWidget {
  const _HeroLegend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.sg.onHero,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
        ],
      );
}

/// A note when macros and calories disagree by a lot.
class _MacroMismatchNote extends StatelessWidget {
  const _MacroMismatchNote({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  @override
  Widget build(BuildContext context) {
    final kcal = calories;
    if (kcal == null || protein == null || carbs == null || fat == null) {
      return const SizedBox.shrink();
    }
    final fromMacros = protein! * 4 + carbs! * 4 + fat! * 9;
    final diff = fromMacros - kcal;
    if (diff.abs() < 100) return const SizedBox.shrink();
    final tokens = context.sg;
    final f = NumberFormat.decimalPattern();
    final text = 'Macros add up to ${f.format(fromMacros.round())} kcal, '
        '${f.format(diff.abs().round())} ${diff > 0 ? 'more' : 'less'} '
        'than your target.';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.info.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusXs),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: tokens.info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estimates targets with [PlanCalculator] from the latest logged weight.
/// Height and activity aren't stored in the profile yet, so they're asked
/// for here and used only for this estimate.
class _RecalculateCard extends StatefulWidget {
  const _RecalculateCard({
    required this.weightKg,
    required this.targetWeightKg,
    required this.goalType,
    required this.metric,
    required this.onApply,
  });

  final double weightKg;
  final double? targetWeightKg;
  final String goalType;
  final bool metric;
  final ValueChanged<NutritionPlan> onApply;

  @override
  State<_RecalculateCard> createState() => _RecalculateCardState();
}

class _RecalculateCardState extends State<_RecalculateCard> {
  double? _height;
  ActivityLevel _activity = ActivityLevel.moderate;

  double? get _heightCm {
    final h = _height;
    if (h == null) return null;
    final cm = widget.metric ? h : Units.inToCm(h);
    return cm >= 80 && cm <= 260 ? cm : null;
  }

  NutritionPlan? get _plan {
    final cm = _heightCm;
    if (cm == null) return null;
    return PlanCalculator.calculate(
      PlanInput(
        weightKg: widget.weightKg,
        heightCm: cm,
        goal: GoalType.fromStorage(widget.goalType),
        targetWeightKg: widget.targetWeightKg,
        activity: _activity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = _plan;
    final heightError = _height != null && _heightCm == null
        ? (widget.metric ? 'Use 80–260 cm' : 'Use 32–102 in')
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: E2eId(
        id: 'settings.goal.recalculate',
        child: SgCard(
          variant: SgCardVariant.raised,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Recalculate targets',
                        style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Uses your latest weight '
                '(${Units.weight(widget.weightKg, metric: widget.metric)}). '
                'Height is only used here.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              SgNumberField(
                label: 'Height',
                suffix: widget.metric ? 'cm' : 'in',
                value: _height,
                nullable: true,
                decimal: false,
                errorText: heightError,
                onChanged: (v) => setState(() => _height = v),
              ),
              const SizedBox(height: 12),
              Text('Activity', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final level in ActivityLevel.values)
                    ChoiceChip(
                      label: Text(level.title),
                      tooltip: level.detail,
                      selected: _activity == level,
                      onSelected: (_) {
                        SgHaptics.tick();
                        setState(() => _activity = level);
                      },
                    ),
                ],
              ),
              if (plan != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Suggested',
                                style: theme.textTheme.labelMedium?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text(
                              '${NumberFormat.decimalPattern().format(plan.caloriesKcal.round())} kcal',
                              style: context.sg.metricSmall,
                            ),
                            const SizedBox(height: 6),
                            MacroChips(
                              proteinG: plan.proteinG,
                              carbsG: plan.carbsG,
                              fatG: plan.fatG,
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (plan.paceClamped) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Kept to a sustainable pace.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: context.sg.warning),
                  ),
                ],
                const SizedBox(height: 12),
                E2eId(
                  id: 'settings.goal.use_suggestion',
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => widget.onApply(plan),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Use these targets'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
