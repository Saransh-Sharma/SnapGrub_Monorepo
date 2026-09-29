import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_steps.dart';
import 'package:snapgrub/features/onboarding/domain/plan_calculator.dart';
import 'package:snapgrub/features/onboarding/presentation/widgets/onboarding_chrome.dart';

// ---------------------------------------------------------------------------
// 9. Activity
// ---------------------------------------------------------------------------

class ActivityStep extends ConsumerWidget {
  const ActivityStep({super.key});

  static IconData _icon(ActivityLevel level) => switch (level) {
        ActivityLevel.sedentary => Icons.chair_rounded,
        ActivityLevel.light => Icons.directions_walk_rounded,
        ActivityLevel.moderate => Icons.directions_run_rounded,
        ActivityLevel.high => Icons.fitness_center_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final tokens = context.sg;
    return OnboardingStepBody(
      question: 'How active are you?',
      why: 'Pick the closest match.',
      children: [
        for (final level in ActivityLevel.values)
          OnboardingChoiceCard(
            id: 'onboarding.activity.${level.storageKey}',
            title: level.title,
            subtitle: level.detail,
            selected: draft.activityLevel == level.storageKey,
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tokens.energy.soft,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(level), color: tokens.energy.color),
            ),
            onTap: () => notifier.updateActivityLevel(level.storageKey),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 10. Pace
// ---------------------------------------------------------------------------

class PaceStep extends ConsumerWidget {
  const PaceStep({super.key});

  static String _paceName(double pace) => switch (pace) {
        <= .25 => 'Gentle',
        <= .5 => 'Steady',
        <= .75 => 'Brisk',
        _ => 'Ambitious',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);
    final tokens = context.sg;
    final motion = SgMotion.of(context);
    final metric = draft.isMetric;
    final losing = draft.goalType == 'lose';
    final today = DateUtils.dateOnly(DateTime.now());
    final withDefaults = draft.copyWith(
      weightKg: OnboardingDefaults.weight(draft),
      heightCm: OnboardingDefaults.height(draft),
      targetWeightKg: OnboardingDefaults.target(draft),
      birthYear: OnboardingDefaults.birthYearOf(draft, today),
    );
    final plan = withDefaults.plan(today: today);
    final pace = draft.paceKgPerWeek
        .clamp(OnboardingDefaults.minPace, OnboardingDefaults.maxPace)
        .toDouble();
    final paceShown = metric ? pace : Units.kgToLb(pace);
    final unit = metric ? 'kg' : 'lb';
    final target = OnboardingDefaults.target(draft);
    final goalDate = plan?.goalDate;
    final dateText =
        goalDate == null ? '—' : DateFormat.MMMd().format(goalDate);
    final weeks = plan?.weeksToGoal ?? 0;
    final eased = plan != null &&
        plan.paceClamped &&
        plan.weeklyChangeKg.abs() < pace - 1e-6;
    final floorHit = plan != null && plan.paceClamped && !eased;
    final age = draft.ageYears(now: today);

    return OnboardingStepBody(
      question: losing
          ? 'How fast do you want to lose?'
          : 'How fast do you want to gain?',
      why: 'Slower is easier to stick with.',
      children: [
        Semantics(
          liveRegion: true,
          label: '${_paceName(pace)} pace, '
              '${paceShown.toStringAsFixed(1)} $unit per week',
          excludeSemantics: true,
          child: Column(
            children: [
              Text(
                _paceName(pace),
                style:
                    tokens.editorial.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: SnapGrubDesignTokens.space4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    RollingNumber(
                      value: double.parse(paceShown.toStringAsFixed(1)),
                      format: NumberFormat('0.0'),
                      style: tokens.heroNumber,
                    ),
                    const SizedBox(width: SnapGrubDesignTokens.space8),
                    Text('$unit / week',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space16),
        E2eId(
          id: 'onboarding.pace',
          child: Slider(
            value: pace,
            min: OnboardingDefaults.minPace,
            max: OnboardingDefaults.maxPace,
            divisions:
                ((OnboardingDefaults.maxPace - OnboardingDefaults.minPace) /
                        OnboardingDefaults.paceStep)
                    .round(),
            label: '${paceShown.toStringAsFixed(1)} $unit',
            semanticFormatterCallback: (v) {
              final shown = metric ? v : Units.kgToLb(v);
              return '${_paceName(v)}, ${shown.toStringAsFixed(1)} $unit per week';
            },
            onChanged: (v) {
              final snapped = (v / OnboardingDefaults.paceStep).round() *
                  OnboardingDefaults.paceStep;
              if ((snapped - draft.paceKgPerWeek).abs() < 1e-6) return;
              SgHaptics.tick();
              notifier.updatePace(snapped);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: SnapGrubDesignTokens.space8),
          child: Row(
            children: [
              Expanded(
                child: Text('Gentle', style: theme.textTheme.labelMedium),
              ),
              Expanded(
                child: Text('Ambitious',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium),
              ),
            ],
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space24),
        SgCard(
          semanticLabel: goalDate == null
              ? null
              : 'Reach ${Units.weight(target, metric: metric)} by $dateText, '
                  'about ${Labels.count(weeks, 'week')}',
          child: _MaybeExclude(
            exclude: goalDate != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text('Reach ${Units.weight(target, metric: metric)} by',
                        style: theme.textTheme.titleMedium),
                    AnimatedSwitcher(
                      duration: motion.settle,
                      transitionBuilder: (child, animation) => ClipRect(
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, .6),
                            end: Offset.zero,
                          ).animate(animation),
                          child:
                              FadeTransition(opacity: animation, child: child),
                        ),
                      ),
                      child: Text(
                        dateText,
                        key: ValueKey(dateText),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SnapGrubDesignTokens.space8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Text('About', style: theme.textTheme.bodyMedium),
                    RollingNumber(
                      value: weeks,
                      style: theme.textTheme.bodyMedium!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(weeks == 1 ? 'week ·' : 'weeks ·',
                        style: theme.textTheme.bodyMedium),
                    RollingNumber(
                      value: plan?.caloriesKcal.round() ?? 0,
                      prefix: '~',
                      style: theme.textTheme.bodyMedium!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text('kcal a day', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (eased || floorHit) ...[
          const SizedBox(height: SnapGrubDesignTokens.space12),
          _GentleNote(
            text: eased
                ? 'Set to '
                    '${Units.weight(plan.weeklyChangeKg.abs(), metric: metric)} '
                    'a week, the safe maximum for now.'
                : 'Your target won’t go below a safe minimum, so progress '
                    'may be slower.',
          ),
        ],
        if (age != null && age < 18) ...[
          const SizedBox(height: SnapGrubDesignTokens.space12),
          const _GentleNote(
            text: 'Under 18? Talk to a doctor before changing how you eat.',
          ),
        ],
      ],
    );
  }
}

class _MaybeExclude extends StatelessWidget {
  const _MaybeExclude({required this.exclude, required this.child});

  final bool exclude;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      exclude ? ExcludeSemantics(child: child) : child;
}

/// Amber, never red: information, not a warning.
class _GentleNote extends StatelessWidget {
  const _GentleNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(SnapGrubDesignTokens.space12),
        decoration: BoxDecoration(
          color: tokens.warning.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusXs),
          border: Border.all(color: tokens.warning.withValues(alpha: .4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.eco_rounded,
                size: SnapGrubDesignTokens.iconMd, color: tokens.warning),
            const SizedBox(width: SnapGrubDesignTokens.space8),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 11. Cuisines
// ---------------------------------------------------------------------------

class CuisinesStep extends ConsumerWidget {
  const CuisinesStep({super.key});

  static const cuisines = [
    'Indian',
    'South Indian',
    'Mediterranean',
    'Italian',
    'Mexican',
    'Chinese',
    'Japanese',
    'Thai',
    'Korean',
    'Middle Eastern',
    'American',
    'French',
    'Vegetarian',
    'Vegan',
  ];

  static String slug(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '_');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);
    final count = draft.cuisinePreferences.length;
    return OnboardingStepBody(
      question: 'What do you like to eat?',
      why: 'Helps us recognize your meals. Optional.',
      children: [
        E2eId(
          id: 'onboarding.cuisines',
          child: Wrap(
            spacing: SnapGrubDesignTokens.space8,
            runSpacing: SnapGrubDesignTokens.space8,
            children: [
              for (final cuisine in cuisines)
                PopChip(
                  id: 'onboarding.cuisine.${slug(cuisine)}',
                  label: cuisine,
                  selected: draft.cuisinePreferences.contains(cuisine),
                  onTap: () => notifier.toggleCuisine(cuisine),
                ),
            ],
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space16),
        Text(
          count == 0 ? 'Optional' : '$count selected',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 12. Reminders & permissions primer
// ---------------------------------------------------------------------------

class RemindersStep extends ConsumerWidget {
  const RemindersStep({super.key});

  static const slots = [
    (
      'breakfast',
      'Breakfast',
      TimeOfDay(hour: 8, minute: 0),
      Icons.free_breakfast_rounded
    ),
    (
      'lunch',
      'Lunch',
      TimeOfDay(hour: 13, minute: 0),
      Icons.lunch_dining_rounded
    ),
    ('snack', 'Snack', TimeOfDay(hour: 16, minute: 30), Icons.cookie_rounded),
    (
      'dinner',
      'Dinner',
      TimeOfDay(hour: 20, minute: 0),
      Icons.dinner_dining_rounded
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.sg;
    final localizations = MaterialLocalizations.of(context);
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    return OnboardingStepBody(
      question: 'Want mealtime reminders?',
      why: 'Reminders are coming soon.',
      children: [
        SgCard(
          padding: const EdgeInsets.symmetric(
            horizontal: SnapGrubDesignTokens.space16,
            vertical: SnapGrubDesignTokens.space4,
          ),
          child: E2eId(
            id: 'onboarding.notifications',
            // Transparent Material so the tile's ink shows on the card.
            child: Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: draft.notificationPreference,
                onChanged: (value) {
                  SgHaptics.tap();
                  notifier.updateNotificationPreference(value);
                },
                title: const Text('Meal reminders'),
                subtitle: Text(draft.notificationPreference
                    ? 'We’ll let you know when they’re ready.'
                    : 'Turn on to hear when they’re ready.'),
              ),
            ),
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space12),
        Wrap(
          spacing: SnapGrubDesignTokens.space8,
          runSpacing: SnapGrubDesignTokens.space8,
          children: [
            for (final (id, label, time, icon) in slots)
              PopChip(
                id: 'onboarding.reminder.$id',
                icon: icon,
                label:
                    '$label · ${localizations.formatTimeOfDay(time, alwaysUse24HourFormat: use24h)}',
                selected: draft.mealReminders.contains(id),
                onTap: () => notifier.toggleMealReminder(id),
              ),
          ],
        ),
        const SizedBox(height: SnapGrubDesignTokens.space12),
        E2eId(
          id: 'onboarding.timezone',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.schedule_rounded,
                  size: SnapGrubDesignTokens.iconSm,
                  color: scheme.onSurfaceVariant),
              const SizedBox(width: SnapGrubDesignTokens.space8),
              Expanded(
                child: Text(
                  'Times follow your phone’s time zone '
                  '(${Labels.timezone(draft.timezone)}).',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space24),
        SgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tokens.protein.soft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_camera_rounded,
                        color: tokens.protein.color),
                  ),
                  const SizedBox(width: SnapGrubDesignTokens.space12),
                  Expanded(
                    child: Text('Your camera, your call',
                        style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: SnapGrubDesignTokens.space12),
              Text(
                'We’ll ask for camera access when you first snap a meal. '
                'Typing always works without it.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: SnapGrubDesignTokens.space4),
              E2eId(
                id: 'onboarding.camera_primer',
                child: Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: draft.cameraPrimerSeen,
                    onChanged: (_) => notifier.markCameraPrimerSeen(),
                    title: const Text('Got it'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
