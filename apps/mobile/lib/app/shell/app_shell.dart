import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/design_system/components/sg_tab_bar.dart';
import 'package:snapgrub/core/design_system/motion.dart';
import 'package:snapgrub/features/milestones/presentation/milestone_celebrator.dart';

/// Tabs: Today · Progress · [Capture] · Atlas · You.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const tabs = [
    SgTabItem(
      icon: Icons.wb_sunny_outlined,
      selectedIcon: Icons.wb_sunny_rounded,
      label: 'Today',
    ),
    SgTabItem(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: 'Progress',
    ),
    SgTabItem(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'Atlas',
    ),
    SgTabItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'You',
    ),
  ];

  /// Bottom space scrollables and pinned controls need to clear the floating
  /// tab bar. Inside the shell body (extendBody) the MediaQuery bottom
  /// padding already includes the bar's height, so we only add breathing room.
  static double bottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 12;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      // Plays each newly earned milestone once (needs the Overlay above).
      body: MilestoneCelebrator(child: shell),
      bottomNavigationBar: AnimatedSlide(
        offset: keyboardOpen ? const Offset(0, 1.4) : Offset.zero,
        duration: SgMotion.of(context).settle,
        curve: Curves.easeOutCubic,
        child: E2eId(
          id: 'shell.tab_bar',
          child: SgTabBar(
            items: tabs,
            currentIndex: shell.currentIndex,
            captureKey: const ValueKey('shell.capture'),
            onCapture: () => context.push('/capture'),
            onSelect: (index) => shell.goBranch(
              index,
              // Tapping the active tab returns it to its root.
              initialLocation: index == shell.currentIndex,
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps every branch alive and fades through between them.
class FadeThroughBranches extends StatefulWidget {
  const FadeThroughBranches({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<FadeThroughBranches> createState() => _FadeThroughBranchesState();
}

class _FadeThroughBranchesState extends State<FadeThroughBranches>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  late int _previous = widget.currentIndex;

  @override
  void didUpdateWidget(covariant FadeThroughBranches oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previous = oldWidget.currentIndex;
      if (SgMotion.of(context).reduced) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.children.length; i++) _branch(i, t),
          ],
        );
      },
    );
  }

  Widget _branch(int i, double t) {
    final current = i == widget.currentIndex;
    final leaving = i == _previous && t < 1 && !current;
    final visible = current || leaving;
    double opacity;
    double scale;
    if (current) {
      final inT = Curves.easeOutCubic.transform(((t - .3) / .7).clamp(0, 1));
      opacity = inT;
      scale = .985 + .015 * inT;
    } else if (leaving) {
      final outT = Curves.easeIn.transform((t / .3).clamp(0, 1));
      opacity = 1 - outT;
      scale = 1;
    } else {
      opacity = 0;
      scale = 1;
    }
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: current,
        child: IgnorePointer(
          ignoring: !current,
          child: HeroMode(
            enabled: current,
            child: ExcludeSemantics(
              excluding: !current,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(scale: scale, child: widget.children[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
