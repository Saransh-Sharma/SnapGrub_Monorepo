import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/milestones/application/milestones_provider.dart';
import 'package:snapgrub/features/milestones/domain/milestone.dart';
import 'package:snapgrub/features/milestones/presentation/milestone_medal.dart';

/// Watches milestone state and celebrates each newly earned milestone once:
/// metal-flake [Celebration] + a medal toast that opens the gallery on tap.
///
/// ## Mounting
/// Mount exactly once, **below the app Navigator** (it needs an [Overlay])
/// and above the screens where milestones can be earned. The simplest place
/// is around the Today screen body or the shell's body:
///
/// ```dart
/// // lib/app/shell/app_shell.dart (or the Today screen)
/// body: MilestoneCelebrator(child: shell),
/// ```
///
/// Mounting it inside `MaterialApp.builder` will *not* work (no Overlay).
///
/// ## Rules
/// * "Celebrated" flags persist in shared_preferences
///   (`milestones.celebrated.<userId>`) and are written *before* anything
///   plays, so each milestone fires exactly once.
/// * First evaluation on an install (no flags yet) seeds every already-earned
///   milestone silently, so upgrading users are not hit with a barrage.
/// * Delight budget: if several milestones land at once (e.g. after a sync),
///   only the most recent is celebrated; the rest are marked and appear in
///   the gallery.
class MilestoneCelebrator extends ConsumerStatefulWidget {
  const MilestoneCelebrator(
      {required this.child, this.enabled = true, super.key});

  final Widget child;

  /// Set false to suspend celebrations (e.g. during onboarding).
  final bool enabled;

  @override
  ConsumerState<MilestoneCelebrator> createState() =>
      _MilestoneCelebratorState();
}

class _MilestoneCelebratorState extends ConsumerState<MilestoneCelebrator> {
  final List<ProviderSubscription<Object?>> _subs = [];
  bool _busy = false;
  OverlayEntry? _toast;

  @override
  void initState() {
    super.initState();
    _subs
      ..add(ref.listenManual(milestonesProvider, (_, __) => _check()))
      ..add(
          ref.listenManual(celebratedMilestonesProvider, (_, __) => _check()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didUpdateWidget(covariant MilestoneCelebrator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) _check();
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.close();
    }
    _toast?.remove();
    _toast = null;
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted || !widget.enabled || _busy) return;
    final statuses = ref.read(milestonesProvider).valueOrNull;
    final celebrated = ref.read(celebratedMilestonesProvider);
    if (statuses == null || !celebrated.hasValue) return;
    final notifier = ref.read(celebratedMilestonesProvider.notifier);
    final set = celebrated.requireValue;
    if (set == null) {
      _busy = true;
      await notifier.mark([
        for (final s in statuses)
          if (s.earned) s.id
      ]);
      _busy = false;
      return;
    }
    final fresh = newlyEarned(statuses, set);
    if (fresh.isEmpty) return;
    _busy = true;
    try {
      // Persist first: exactly-once even if the app dies mid-animation.
      await notifier.mark(fresh.map((s) => s.id));
      if (!mounted) return;
      final hero = fresh.last;
      await Celebration.play(
        context,
        key: 'milestone.${hero.id}',
        metals: [hero.definition.tier.metal, SgMetal.titanium],
        onceEver: true,
      );
      if (!mounted) return;
      _showToast(hero, extra: fresh.length - 1);
    } finally {
      _busy = false;
    }
  }

  void _showToast(MilestoneStatus status, {int extra = 0}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _toast?.remove();
    final router = GoRouter.maybeOf(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => MilestoneToast(
        status: status,
        extra: extra,
        onTap: router == null ? null : () => router.push('/milestones'),
        onDone: () {
          if (_toast == entry) _toast = null;
          entry.remove();
        },
      ),
    );
    _toast = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Slide-down toast with a live medal. Dismisses itself after ~3.2 s.
class MilestoneToast extends StatefulWidget {
  const MilestoneToast({
    required this.status,
    required this.onDone,
    this.extra = 0,
    this.onTap,
    super.key,
  });

  final MilestoneStatus status;
  final int extra;
  final VoidCallback? onTap;
  final VoidCallback onDone;

  @override
  State<MilestoneToast> createState() => _MilestoneToastState();
}

class _MilestoneToastState extends State<MilestoneToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 260),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(milliseconds: 3200), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final theme = Theme.of(context);
    final def = widget.status.definition;
    final curve = CurvedAnimation(
      parent: _c,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 8,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -1.4), end: Offset.zero)
            .animate(curve),
        child: FadeTransition(
          opacity: _c,
          child: Semantics(
            liveRegion: true,
            button: widget.onTap != null,
            label: 'Milestone unlocked: ${def.title}',
            excludeSemantics: true,
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                onTap: () {
                  widget.onTap?.call();
                  _dismiss();
                },
                onVerticalDragEnd: (_) => _dismiss(),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
                  decoration: BoxDecoration(
                    color: tokens.hero,
                    borderRadius:
                        BorderRadius.circular(SnapGrubDesignTokens.radiusPill),
                    boxShadow: tokens.elevation3,
                  ),
                  child: Row(
                    children: [
                      MilestoneMedal(
                        icon: def.icon,
                        tier: def.tier,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.extra > 0
                                  ? 'Milestone unlocked · +${widget.extra} more'
                                  : 'Milestone unlocked',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: tokens.onHeroMuted,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              def.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: tokens.onHero),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: tokens.onHeroMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
