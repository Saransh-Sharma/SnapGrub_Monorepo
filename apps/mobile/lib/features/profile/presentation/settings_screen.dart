import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/shell/app_shell.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/milestones/application/streak_provider.dart';
import 'package:snapgrub/features/milestones/domain/streak.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/profile/domain/nutrition_goal.dart';
import 'package:snapgrub/features/profile/domain/profile.dart';
import 'package:snapgrub/features/profile/presentation/profile_labels.dart';
import 'package:snapgrub/features/profile/presentation/widgets/appearance_section.dart';
import 'package:snapgrub/features/profile/presentation/widgets/you_rows.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

export 'goal_edit_screen.dart';

/// The "You" tab (`/settings`): profile, plan, appearance, library, data.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await ref.read(profileControllerProvider.notifier).refresh();
      if (mounted) showSgToast(context, 'Up to date');
    } catch (error) {
      // A failed refresh leaves the controller loading; fall back to the
      // copy on this phone.
      ref.invalidate(profileControllerProvider);
      if (mounted) {
        showSgToast(
          context,
          friendlyError(error).message,
          icon: Icons.cloud_off_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Sign out?',
      message: 'Anything not yet synced stays on this phone.',
      confirmLabel: 'Sign out',
      cancelLabel: 'Cancel',
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) context.go('/auth');
    } catch (error) {
      if (mounted) showSgToast(context, friendlyError(error).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);
    final profileState = profileAsync.valueOrNull;
    final loading = profileAsync.isLoading && profileState == null;
    final user = profileState?.profile;
    final goal = profileState?.activeGoal;
    final streak = ref.watch(streakProvider);
    final sync = ref.watch(syncControllerProvider).valueOrNull;
    final theme = Theme.of(context);

    return E2eId(
      id: 'scaffold.settings',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PremiumBackdrop(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: SnapGrubDesignTokens.maxContentWidth,
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 16,
                  16,
                  AppShell.bottomInset(context) + 8,
                ),
                children: [
                  Semantics(
                    header: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                      child: Text('You', style: theme.textTheme.headlineLarge),
                    ),
                  ),
                  _ProfileHeader(
                    user: user,
                    loading: loading,
                    streak: streak,
                  ),
                  const SgSectionHeader(title: 'Goal & targets'),
                  if (loading)
                    const SgCard(child: SgSkeleton(height: 72))
                  else if (goal != null)
                    _PlanCard(goal: goal)
                  else
                    const _SetTargetsCard(),
                  const SgSectionHeader(title: 'Milestones'),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        e2eId: 'settings.milestones',
                        icon: Icons.military_tech_rounded,
                        title: 'Milestones',
                        subtitle: streak.best > 0
                            ? 'Best streak: ${_days(streak.best)}'
                            : 'Earn medals by logging',
                        onTap: () => context.push('/milestones'),
                      ),
                    ],
                  ),
                  const SgSectionHeader(title: 'Appearance'),
                  const AppearanceSection(),
                  const SgSectionHeader(title: 'Library'),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        e2eId: 'settings.templates',
                        icon: Icons.bookmarks_rounded,
                        title: 'Saved meals',
                        subtitle: 'Meals you log often',
                        onTap: () => context.push('/templates'),
                      ),
                      SettingsRow(
                        e2eId: 'settings.custom_foods',
                        icon: Icons.restaurant_menu_rounded,
                        title: 'My foods',
                        subtitle: 'Your foods and recipes',
                        onTap: () => context.push('/custom-foods'),
                      ),
                    ],
                  ),
                  const SgSectionHeader(title: 'Privacy & data'),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        e2eId: 'settings.privacy',
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy & data',
                        subtitle: 'AI, photos, export, delete account',
                        onTap: () => context.push('/settings/privacy'),
                      ),
                      SettingsRow(
                        e2eId: 'settings.sync',
                        icon: Icons.cloud_sync_outlined,
                        title: 'Sync',
                        trailing: _SyncPill(status: sync),
                        onTap: () => context.push('/sync'),
                      ),
                    ],
                  ),
                  const SgSectionHeader(title: 'Account'),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        e2eId: 'settings.refresh',
                        icon: Icons.refresh_rounded,
                        title: 'Refresh profile',
                        subtitle: 'Get your latest settings',
                        trailing: _refreshing
                            ? const SizedBox.square(
                                dimension: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                        onTap: _refreshing ? null : _refresh,
                      ),
                      SettingsRow(
                        e2eId: 'settings.sign_out',
                        icon: Icons.logout_rounded,
                        title: 'Sign out',
                        destructive: true,
                        chevron: false,
                        onTap: _signOut,
                      ),
                    ],
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

String _days(int n) => Labels.count(n, 'day');

// ---------------------------------------------------------------------------
// Profile header
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.loading,
    required this.streak,
  });

  final UserProfile? user;
  final bool loading;
  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = user?.displayName?.trim();
    final hasName = name != null && name.isNotEmpty;

    return SgCard(
      variant: SgCardVariant.raised,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (hasName)
                _Avatar(initial: name.characters.first.toUpperCase())
              else
                const SnapGrubMark(size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: loading
                    ? SgSkeleton.lines(count: 2)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasName ? name : 'Your profile',
                            style: theme.textTheme.headlineSmall,
                          ),
                          if (user != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              ProfileLabels.summary(user!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: .7),
          ),
          const SizedBox(height: 14),
          E2eId(
            id: 'settings.streak',
            child: MergeSemantics(
              child: Row(
                children: [
                  StreakMedal(streak: streak),
                  const SizedBox(width: 14),
                  Expanded(child: _StreakCopy(streak: streak)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    return ExcludeSemantics(
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.energy.soft,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: tokens.energy.onSoft,
                height: 1,
              ),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }
}

class _StreakCopy extends StatelessWidget {
  const _StreakCopy({required this.streak});

  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = streak.current;
    final next = StreakTier.values
        .where((t) => t.minDays > current && t != StreakTier.none)
        .firstOrNull;
    final title = current == 0 ? 'No streak yet' : '$current-day streak';
    final String subtitle;
    if (current == 0) {
      subtitle = 'Log a meal to start one.';
    } else if (next != null) {
      final left = next.minDays - current;
      subtitle = '${_days(left)} to ${_tierName(next)}'
          '${streak.best > current ? ' · best ${_days(streak.best)}' : ''}';
    } else {
      subtitle = 'Top medal. Keep it going!';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

String _tierName(StreakTier tier) => switch (tier) {
      StreakTier.none => '',
      StreakTier.silver => 'Silver',
      StreakTier.copper => 'Copper',
      StreakTier.gold => 'Gold',
      StreakTier.holo => 'Holo',
    };

/// Streak count on a metal disc in the current tier's material; a debossed
/// porcelain disc before the first tier.
class StreakMedal extends StatelessWidget {
  const StreakMedal({required this.streak, this.size = 56, super.key});

  final StreakSummary streak;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tier = streak.tier;
    final metal = tier.metal;
    final number = Text(
      '${streak.current}',
      textScaler: TextScaler.noScaling,
      style: context.sg.metricSmall.copyWith(
        fontSize: size * .36,
        color: metal?.shadow ?? scheme.onSurfaceVariant,
        shadows: metal == null
            ? null
            : [Shadow(color: metal.highlight, offset: const Offset(0, .8))],
      ),
    );
    Widget disc = metal == null
        ? Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHigh,
              border: Border.all(color: scheme.outlineVariant, width: 2),
            ),
            alignment: Alignment.center,
            child: number,
          )
        : MetalSurface(
            metal: metal,
            shape: MetalShape.disc,
            child: Center(child: number),
          );
    if (tier == StreakTier.holo) {
      disc = HoloFoil(borderRadius: size / 2, child: disc);
    }
    return Semantics(
      label: tier == StreakTier.none
          ? 'Streak medal, ${_days(streak.current)}'
          : '${_tierName(tier)} streak medal, ${_days(streak.current)}',
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(dimension: size, child: disc),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.goal});

  final NutritionGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final kcal =
        NumberFormat.decimalPattern().format(goal.caloriesKcal.round());
    return E2eId(
      id: 'settings.goal',
      child: SgCard(
        variant: SgCardVariant.raised,
        semanticLabel: 'Daily targets: $kcal calories, protein '
            '${goal.proteinG.round()} grams, carbs ${goal.carbsG.round()} '
            'grams, fat ${goal.fatG.round()} grams. Edit targets',
        onTap: () => context.push('/settings/goal'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ProfileLabels.goalType(goal.goalType),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: kcal, style: tokens.metric),
                            TextSpan(
                              text: ' kcal a day',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_outlined,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 14),
            MacroBar(
              proteinG: goal.proteinG,
              carbsG: goal.carbsG,
              fatG: goal.fatG,
            ),
            const SizedBox(height: 10),
            MacroChips(
              proteinG: goal.proteinG,
              carbsG: goal.carbsG,
              fatG: goal.fatG,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetTargetsCard extends StatelessWidget {
  const _SetTargetsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return E2eId(
      id: 'settings.goal_cta',
      child: SgCard(
        variant: SgCardVariant.raised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set your targets', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Add calorie and macro targets to see what’s left.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => context.push('/settings/goal'),
              icon: const Icon(Icons.track_changes_rounded),
              label: const Text('Set targets'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sync
// ---------------------------------------------------------------------------

class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.status});

  final SyncStatus? status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, tone) = switch (status) {
      null => ('Checking…', Icons.cloud_outlined, StatusTone.neutral),
      SyncStatus.idle || SyncStatus.synced => (
          'Synced',
          Icons.cloud_done_outlined,
          StatusTone.positive
        ),
      SyncStatus.pending => (
          'Saved on phone',
          Icons.cloud_upload_outlined,
          StatusTone.neutral
        ),
      SyncStatus.syncing => ('Syncing…', Icons.sync_rounded, StatusTone.info),
      SyncStatus.failed => (
          'Not synced',
          Icons.sync_problem_rounded,
          StatusTone.attention
        ),
      SyncStatus.conflict => (
          'Needs review',
          Icons.report_outlined,
          StatusTone.attention
        ),
    };
    // StatusPill doesn't wrap; scale it down rather than overflow at very
    // large text sizes.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: StatusPill(label: label, icon: icon, tone: tone),
    );
  }
}
