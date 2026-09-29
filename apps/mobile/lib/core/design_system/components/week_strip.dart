import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:snapgrub/core/design_system/components/sg_ring.dart';
import 'package:snapgrub/core/design_system/haptics.dart';
import 'package:snapgrub/core/design_system/motion.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

/// Seven-day strip (Mon–Sun) with a mini calorie ring per day and a
/// selection pill that glides between days. Swipe to change week.
class WeekStrip extends StatefulWidget {
  const WeekStrip({
    required this.selected,
    required this.onSelect,
    required this.progressFor,
    this.today,
    super.key,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  /// Calorie progress (0..2) for a day, or null when nothing is known.
  final double? Function(DateTime day) progressFor;
  final DateTime? today;

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  static const _pages = 520; // ~10 years of history
  late final PageController _controller =
      PageController(initialPage: _pageFor(widget.selected));

  DateTime get _today => DateUtils.dateOnly(widget.today ?? DateTime.now());

  DateTime _mondayOf(DateTime day) {
    final d = DateUtils.dateOnly(day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  int _pageFor(DateTime day) {
    final weeks =
        _mondayOf(_today).difference(_mondayOf(day)).inDays ~/ 7;
    return (_pages - 1 - weeks).clamp(0, _pages - 1);
  }

  DateTime _mondayForPage(int page) =>
      _mondayOf(_today).subtract(Duration(days: 7 * (_pages - 1 - page)));

  @override
  void didUpdateWidget(covariant WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _pageFor(widget.selected);
    if (_controller.hasClients && _controller.page?.round() != target) {
      final motion = SgMotion.of(context);
      if (motion.reduced) {
        _controller.jumpToPage(target);
      } else {
        _controller.animateToPage(target,
            duration: motion.page, curve: motion.standard);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return SizedBox(
      height: 78 * scale,
      child: PageView.builder(
        controller: _controller,
        itemCount: _pages,
        onPageChanged: (_) => SgHaptics.tick(),
        itemBuilder: (context, page) => _WeekRow(
          monday: _mondayForPage(page),
          selected: DateUtils.dateOnly(widget.selected),
          today: _today,
          progressFor: widget.progressFor,
          onSelect: (day) {
            SgHaptics.tick();
            widget.onSelect(day);
          },
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.monday,
    required this.selected,
    required this.today,
    required this.progressFor,
    required this.onSelect,
  });

  final DateTime monday;
  final DateTime selected;
  final DateTime today;
  final double? Function(DateTime day) progressFor;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final motion = SgMotion.of(context);
    final days = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    final selectedIndex = days.indexWhere((d) => d == selected);
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth / 7;
        return Stack(
          children: [
            if (selectedIndex >= 0)
              AnimatedPositioned(
                duration: motion.settle,
                curve: motion.emphasized,
                left: selectedIndex * slot + 4,
                width: slot - 8,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.sg.dark
                        ? Theme.of(context).colorScheme.primaryContainer
                        : context.sg.hero,
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: _DayCell(
                      day: day,
                      selected: day == selected,
                      isToday: day == today,
                      future: day.isAfter(today),
                      progress: progressFor(day),
                      onTap: () => onSelect(day),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.future,
    required this.progress,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool future;
  final double? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final fg = selected ? tokens.onHero : theme.colorScheme.onSurface;
    final muted = selected
        ? tokens.onHeroMuted
        : theme.colorScheme.onSurfaceVariant;
    final ringColor = selected ? tokens.onHero : tokens.energy.color;
    final label = DateFormat('EEEE d MMMM').format(day);
    return Semantics(
      button: !future,
      selected: selected,
      label: '$label${isToday ? ', today' : ''}'
          '${progress == null ? '' : ', ${(progress! * 100).round()} percent of calories'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: future ? null : onTap,
        child: Opacity(
          opacity: future ? .38 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E').format(day).substring(0, 1),
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 5),
              SgRing(
                size: 34,
                thickness: 3,
                progress: progress ?? 0,
                color: ringColor,
                trackColor: (selected ? tokens.onHero : theme.colorScheme.onSurface)
                    .withValues(alpha: .12),
                semanticsLabel: null,
                child: FittedBox(
                  child: Text(
                    '${day.day}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
