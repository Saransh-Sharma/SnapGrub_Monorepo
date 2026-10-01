import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/router/nav.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/milestones/application/milestones_provider.dart';
import 'package:snapgrub/features/milestones/domain/milestone.dart';
import 'package:snapgrub/features/milestones/presentation/milestone_medal.dart';

/// Milestones gallery: metal medals for earned milestones, debossed porcelain
/// silhouettes for locked ones. Tap a medal and it flies to the centre and
/// flips in 3D to reveal when it was earned (or how to earn it).
class MilestonesScreen extends ConsumerStatefulWidget {
  const MilestonesScreen({super.key});

  @override
  ConsumerState<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends ConsumerState<MilestonesScreen> {
  final Map<String, GlobalKey> _keys = {};
  MilestoneStatus? _focused;
  Rect? _origin;

  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  void _open(MilestoneStatus status) {
    final box =
        _keyFor(status.id).currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    SgHaptics.tap();
    setState(() {
      _focused = status;
      _origin = box.localToGlobal(Offset.zero) & box.size;
    });
  }

  void _close() => setState(() {
        _focused = null;
        _origin = null;
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final milestones = ref.watch(milestonesProvider);
    final focused = _focused;

    return PopScope(
      canPop: focused == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _focused != null) _close();
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: milestones.when(
                loading: () => const _GallerySkeleton(),
                error: (error, _) => ErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(milestoneFactsProvider),
                ),
                data: (all) => _Gallery(
                  milestones: all,
                  keyFor: _keyFor,
                  hiddenId: focused?.id,
                  onTap: _open,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 4,
              left: 4,
              child: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                color: theme.colorScheme.onSurface,
                onPressed: () => context.popOrGo('/progress'),
              ),
            ),
            if (focused != null && _origin != null)
              Positioned.fill(
                child: _FocusLayer(
                  key: ValueKey(focused.id),
                  status: focused,
                  origin: _origin!,
                  onClosed: _close,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.milestones,
    required this.keyFor,
    required this.hiddenId,
    required this.onTap,
  });

  final List<MilestoneStatus> milestones;
  final GlobalKey Function(String id) keyFor;
  final String? hiddenId;
  final ValueChanged<MilestoneStatus> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = milestones.where((m) => m.earned).length;
    var index = 0;
    return E2eId(
      id: 'milestones.grid',
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child:
                        Text('Milestones', style: theme.textTheme.displaySmall),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    earned == 0
                        ? 'Earn medals by logging. Your first is one meal away.'
                        : '$earned of ${milestones.length} earned. '
                            'Tap a medal to flip it.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          milestones.isEmpty ? 0 : earned / milestones.length,
                      minHeight: 6,
                      color: SgMetal.gold.base,
                      backgroundColor:
                          theme.colorScheme.onSurface.withValues(alpha: .08),
                      // semanticsValue must be numeric for the progress-bar
                      // role, so the count goes in the label.
                      semanticsLabel:
                          '$earned of ${milestones.length} milestones earned',
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final group in MilestoneGroup.values) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: SgSectionHeader(title: group.label),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 124,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  // Fixed row height: fits the medal plus a two-line label at
                  // any column count.
                  mainAxisExtent: 168,
                ),
                delegate: SliverChildListDelegate([
                  for (final m
                      in milestones.where((m) => m.definition.group == group))
                    SgEntrance(
                      index: index++,
                      scale: .9,
                      child: _MedalCell(
                        status: m,
                        medalKey: keyFor(m.id),
                        hidden: m.id == hiddenId,
                        onTap: () => onTap(m),
                      ),
                    ),
                ]),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 32),
          ),
        ],
      ),
    );
  }
}

class _MedalCell extends StatelessWidget {
  const _MedalCell({
    required this.status,
    required this.medalKey,
    required this.hidden,
    required this.onTap,
  });

  final MilestoneStatus status;
  final GlobalKey medalKey;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = status.definition;
    return Semantics(
      button: true,
      label: medalSemantics(status),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Opacity(
                opacity: hidden ? 0 : 1,
                child: MilestoneMedal(
                  key: medalKey,
                  icon: def.icon,
                  tier: def.tier,
                  earned: status.earned,
                  size: 72,
                  // Grid medals render one static metal frame; only the
                  // focused medal runs live and follows tilt.
                  live: false,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                def.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: status.earned
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The medal lifted out of the grid: flies to centre, then flips on tap.
class _FocusLayer extends StatefulWidget {
  const _FocusLayer({
    required this.status,
    required this.origin,
    required this.onClosed,
    super.key,
  });

  final MilestoneStatus status;
  final Rect origin;
  final VoidCallback onClosed;

  @override
  State<_FocusLayer> createState() => _FocusLayerState();
}

class _FocusLayerState extends State<_FocusLayer>
    with TickerProviderStateMixin {
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
    reverseDuration: const Duration(milliseconds: 420),
  );
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _closing = false;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = SgMotion.of(context).reduced;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_reduced) {
        _fly.value = 1;
        _flip.value = 1;
        return;
      }
      await _fly.forward();
      if (!mounted) return;
      // Reveal the back automatically once it lands.
      await _flip.animateTo(1, curve: Curves.easeInOutCubic);
      if (mounted) SgHaptics.tick();
    });
  }

  @override
  void dispose() {
    _fly.dispose();
    _flip.dispose();
    super.dispose();
  }

  Future<void> _toggleFlip() async {
    SgHaptics.tick();
    final target = _flip.value > .5 ? 0.0 : 1.0;
    if (_reduced) {
      setState(() => _flip.value = target);
      return;
    }
    await _flip.animateTo(target, curve: Curves.easeInOutCubic);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    if (!_reduced) {
      if (_flip.value > 0) {
        await _flip.animateBack(0,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOutCubic);
      }
      await _fly.reverse();
    }
    widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final theme = Theme.of(context);
    final def = widget.status.definition;
    final screen = MediaQuery.sizeOf(context);
    final size = math.min(screen.width * .62, 240.0);
    final target = Rect.fromCenter(
      center: Offset(screen.width / 2, screen.height * .42),
      width: size,
      height: size,
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: def.title,
      child: AnimatedBuilder(
        animation: Listenable.merge([_fly, _flip]),
        builder: (context, _) {
          final flyT = _reduced
              ? _fly.value
              : Curves.easeOutBack.transform(_fly.value.clamp(0.0, 1.0));
          final rect = Rect.lerp(widget.origin, target, flyT)!;
          final fade = _fly.value.clamp(0.0, 1.0);
          final angle = _reduced ? 0.0 : _flip.value * math.pi;
          final showBack = _flip.value >= .5;
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _close,
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                        sigmaX: 14 * fade, sigmaY: 14 * fade),
                    child: ColoredBox(
                      color: tokens.hero.withValues(alpha: .72 * fade),
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: rect,
                child: GestureDetector(
                  onTap: _toggleFlip,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: _reduced
                        ? AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: showBack
                                ? _MedalBack(
                                    key: const ValueKey('back'),
                                    status: widget.status,
                                    size: rect.width,
                                    mirrored: false,
                                  )
                                : _front(rect.width),
                          )
                        : showBack
                            ? _MedalBack(
                                status: widget.status,
                                size: rect.width,
                                mirrored: true,
                              )
                            : _front(rect.width),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: target.bottom + 28,
                child: Opacity(
                  opacity: Curves.easeIn.transform(fade),
                  child: Column(
                    children: [
                      Text(
                        def.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: tokens.onHero),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.status.earned
                            ? '${def.tier.label} medal · ${def.howTo}'
                            : def.howTo,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: tokens.onHeroMuted),
                      ),
                      const SizedBox(height: 18),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                            foregroundColor: tokens.onHero),
                        onPressed: _toggleFlip,
                        icon: const Icon(Icons.flip_rounded, size: 18),
                        label: Text(showBack ? 'Show front' : 'Flip'),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 4,
                right: 8,
                child: Opacity(
                  opacity: fade,
                  child: IconButton(
                    tooltip: 'Close',
                    color: tokens.onHero,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _close,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _front(double size) {
    final def = widget.status.definition;
    return MilestoneMedal(
      key: const ValueKey('front'),
      icon: def.icon,
      tier: def.tier,
      earned: widget.status.earned,
      size: size,
      semanticLabel: medalSemantics(widget.status),
    );
  }
}

/// Reverse of a medal: engraved date for earned medals, the challenge and
/// progress for locked ones. [mirrored] cancels the 180° flip so text reads.
class _MedalBack extends StatelessWidget {
  const _MedalBack({
    required this.status,
    required this.size,
    required this.mirrored,
    super.key,
  });

  final MilestoneStatus status;
  final double size;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = status.definition;
    final earned = status.earned;
    final metal = def.tier.metal;
    final ink = earned ? metal.shadow : theme.colorScheme.onSurfaceVariant;
    final at = status.earnedAt;

    final Widget face = Padding(
      padding: EdgeInsets.all(size * .16),
      child: FittedBox(
        child: SizedBox(
          width: 160,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                earned ? 'EARNED' : 'LOCKED',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: ink.withValues(alpha: .8),
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 6),
              if (earned) ...[
                Text(
                  at == null ? '—' : DateFormat('d MMM').format(at),
                  style: theme.textTheme.displaySmall?.copyWith(color: ink),
                ),
                if (at != null)
                  Text(
                    DateFormat('y').format(at),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ink.withValues(alpha: .85),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ] else ...[
                Text(
                  def.howTo,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(color: ink),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: status.progress,
                    minHeight: 5,
                    color: context.sg.energy.color,
                    backgroundColor: ink.withValues(alpha: .15),
                  ),
                ),
                if (status.progressLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    status.progressLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(color: ink),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );

    Widget disc;
    if (earned) {
      disc = MetalSurface(
        metal: metal,
        shape: MetalShape.disc,
        child: Center(
          child: Container(
            width: size * .86,
            height: size * .86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: metal.shadow.withValues(alpha: .3), width: 1.5),
            ),
            child: face,
          ),
        ),
      );
      if (def.tier == MilestoneTier.holo) {
        disc = HoloFoil(borderRadius: size / 2, intensity: .8, child: disc);
      }
    } else {
      disc = Stack(
        fit: StackFit.expand,
        children: [
          MilestoneMedal(icon: def.icon, earned: false, size: size),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: .92),
            ),
            margin: EdgeInsets.all(size * .07),
            child: face,
          ),
        ],
      );
    }
    final sized = Semantics(
      label: medalSemantics(status),
      excludeSemantics: true,
      child: SizedBox.square(dimension: size, child: disc),
    );
    return mirrored
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: sized,
          )
        : sized;
  }
}

class _GallerySkeleton extends StatelessWidget {
  const _GallerySkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SgSkeleton(width: 200, height: 40, radius: 12),
            const SizedBox(height: 28),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                for (var i = 0; i < 9; i++)
                  const SgSkeleton(width: 72, height: 72, circle: true),
              ],
            ),
          ],
        ),
      );
}
