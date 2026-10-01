import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/time/clock.dart';
import 'package:snapgrub/core/time/user_day.dart';
import 'package:snapgrub/features/capture/application/capture_controller.dart';
import 'package:snapgrub/features/conversation/application/conversation_controller.dart';
import 'package:snapgrub/features/conversation/application/conversation_providers.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';
import 'package:snapgrub/features/conversation/presentation/today/calorie_hero_card.dart';
import 'package:snapgrub/features/conversation/presentation/today/macro_cards_row.dart';
import 'package:snapgrub/features/conversation/presentation/today/pending_analysis_card.dart';
import 'package:snapgrub/features/conversation/presentation/today/suggestions_strip.dart';
import 'package:snapgrub/features/conversation/presentation/today/today_header.dart';
import 'package:snapgrub/features/conversation/presentation/widgets/composer.dart';
import 'package:snapgrub/features/conversation/presentation/widgets/conversation_meal_card.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/application/meal_actions.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/photo_analysis/application/analysis_queue_controller.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

/// Today: a Cal AI–style dashboard (week strip, calorie hero, macro rings,
/// suggestions) with the conversational day log beneath it. Swipe between
/// days; the composer and capture tray stay pinned above the tab bar.
class DayThreadScreen extends ConsumerStatefulWidget {
  const DayThreadScreen({this.initialDay, this.anchorMealId, super.key});

  final DateTime? initialDay;
  final String? anchorMealId;

  @override
  ConsumerState<DayThreadScreen> createState() => _DayThreadScreenState();
}

class _DayThreadScreenState extends ConsumerState<DayThreadScreen>
    with WidgetsBindingObserver {
  static const _todayPage = 10000;
  late final PageController _pageController;
  late DateTime _selectedDay;
  late DateTime _today;
  bool _didOpenAtlas = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final today = DateUtils.dateOnly(DateTime.now());
    _today = today;
    final requested = widget.initialDay == null
        ? today
        : DateUtils.dateOnly(
            widget.initialDay!.isAfter(today) ? today : widget.initialDay!);
    _selectedDay = requested;
    _pageController = PageController(
      initialPage: (_todayPage - today.difference(requested).inDays)
          .clamp(0, _todayPage),
    );
  }

  @override
  void didUpdateWidget(covariant DayThreadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final day = widget.initialDay;
    if (day != null && day != oldWidget.initialDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToDay(day));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(ref.read(captureControllerProvider.notifier).pausePreview());
    }
  }

  int _pageFor(DateTime day) =>
      (_todayPage - _today.difference(DateUtils.dateOnly(day)).inDays)
          .clamp(0, _todayPage);

  DateTime _dayFor(int page) =>
      _today.subtract(Duration(days: _todayPage - page));

  Future<void> _goToDay(DateTime day) async {
    if (!_pageController.hasClients) return;
    final target = _pageFor(day);
    final motion = SgMotion.of(context);
    if (motion.reduced || (target - (_pageController.page ?? 0)).abs() > 7) {
      _pageController.jumpToPage(target);
    } else {
      await _pageController.animateToPage(target,
          duration: motion.page, curve: motion.standard);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: _today,
      helpText: 'Go to date',
    );
    if (picked != null) await _goToDay(picked);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(homeUserContextProvider).valueOrNull;
    if (user != null) {
      final userToday =
          DateUtils.dateOnly(ref.watch(userDayTickProvider(user.timezone)));
      if (userToday != _today) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final selected =
              _selectedDay.isAfter(userToday) ? userToday : _selectedDay;
          setState(() {
            _today = userToday;
            _selectedDay = selected;
          });
          _pageController.jumpToPage(_pageFor(selected));
        });
      }
    }
    final weekProgress = ref.watch(_weekProgressProvider(_selectedDay));

    return E2eId(
      id: 'screen.day_thread',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: MeshAurora(
          child: SafeArea(
            bottom: false,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: (_) => _didOpenAtlas = false,
              onScaleUpdate: (details) {
                if (!_didOpenAtlas &&
                    details.pointerCount >= 2 &&
                    details.scale < .82) {
                  _didOpenAtlas = true;
                  SgHaptics.impact();
                  context.go('/atlas');
                }
              },
              child: Column(
                children: [
                  TodayHeader(
                    day: _selectedDay,
                    today: _today,
                    onPrevious: () => _goToDay(
                        _selectedDay.subtract(const Duration(days: 1))),
                    onNext: _selectedDay == _today
                        ? null
                        : () =>
                            _goToDay(_selectedDay.add(const Duration(days: 1))),
                    onCalendar: _pickDate,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: WeekStrip(
                      selected: _selectedDay,
                      today: _today,
                      onSelect: _goToDay,
                      progressFor: (day) =>
                          weekProgress[DateUtils.dateOnly(day)],
                    ),
                  ),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                        stops: [0, .035],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _todayPage + 1,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() => _selectedDay = _dayFor(index));
                          SgHaptics.tick();
                        },
                        itemBuilder: (context, index) {
                          final day = _dayFor(index);
                          return _DayPage(
                            day: day,
                            isToday: day == _today,
                            anchorMealId: day == _selectedDay
                                ? widget.anchorMealId
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                  ConversationComposer(day: _selectedDay),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Calorie progress for the selected day's week ±1 week (for the WeekStrip).
final _weekProgressProvider =
    Provider.family<Map<DateTime, double>, DateTime>((ref, selected) {
  final user = ref.watch(homeUserContextProvider).valueOrNull;
  final goal = user?.calorieGoal;
  if (goal == null || goal <= 0) return const {};
  final monday = selected.subtract(Duration(days: selected.weekday - 1));
  final result = <DateTime, double>{};
  for (var i = -7; i < 14; i++) {
    final day = DateUtils.dateOnly(monday.add(Duration(days: i)));
    final rollup = ref.watch(rollupForDayProvider(day)).valueOrNull;
    if (rollup != null && rollup.mealCount > 0) {
      result[day] = rollup.caloriesKcal / goal;
    }
  }
  return result;
});

class _DayPage extends ConsumerStatefulWidget {
  const _DayPage({required this.day, required this.isToday, this.anchorMealId});

  final DateTime day;
  final bool isToday;
  final String? anchorMealId;

  @override
  ConsumerState<_DayPage> createState() => _DayPageState();
}

class _DayPageState extends ConsumerState<_DayPage>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _anchorKey = GlobalKey();
  bool _didScrollToAnchor = false;

  @override
  bool get wantKeepAlive => widget.isToday;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final day = widget.day;
    final messages =
        ref.watch(threadMessagesProvider(day)).valueOrNull ?? const [];
    final proposals =
        ref.watch(threadProposalsProvider(day)).valueOrNull ?? const [];
    final mealsAsync = ref.watch(mealsForDayProvider(day));
    final hidden = ref.watch(pendingMealDeletionsProvider);
    final meals = (mealsAsync.valueOrNull ?? const <Meal>[])
        .where((meal) => !hidden.contains(meal.id))
        .toList();
    final rollup = ref.watch(rollupForDayProvider(day)).valueOrNull;
    final user = ref.watch(homeUserContextProvider).valueOrNull;
    final profile = ref.watch(profileControllerProvider).valueOrNull?.profile;
    final composer = ref.watch(conversationControllerProvider);
    final jobs = ref
        .watch(analysisQueueProvider)
        .where((job) => DateUtils.isSameDay(job.day, day))
        .toList();

    final items = <_TimelineItem>[
      ...messages.map(_TimelineItem.message),
      ...proposals
          .where((proposal) => proposal.status == ProposalStatus.pending)
          .map(_TimelineItem.proposal),
      ...meals.map(_TimelineItem.meal),
      ...jobs.map(_TimelineItem.job),
    ]..sort((a, b) => a.time.compareTo(b.time));
    final showPresence = composer.isSending &&
        composer.activeDay != null &&
        DateUtils.isSameDay(composer.activeDay, day);

    // Recompute calories from visible meals so optimistic deletes update the
    // rings immediately.
    final eaten = hidden.isEmpty
        ? (rollup?.caloriesKcal ?? 0)
        : meals.fold<double>(0, (sum, m) => sum + m.caloriesKcal);
    double sumOf(double Function(Meal m) f) =>
        meals.fold<double>(0, (sum, m) => sum + f(m));
    final protein =
        hidden.isEmpty ? (rollup?.proteinG ?? 0) : sumOf((m) => m.proteinG);
    final carbs =
        hidden.isEmpty ? (rollup?.carbsG ?? 0) : sumOf((m) => m.carbsG);
    final fat = hidden.isEmpty ? (rollup?.fatG ?? 0) : sumOf((m) => m.fatG);

    if (!_didScrollToAnchor && widget.anchorMealId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final anchorContext = _anchorKey.currentContext;
        if (anchorContext != null && mounted) {
          _didScrollToAnchor = true;
          await Scrollable.ensureVisible(anchorContext,
              duration: SgMotion.of(context).page, alignment: .35);
        }
      });
    }

    final now = ref.watch(clockProvider)();
    final localNow = user == null ? now : userLocalTimeFor(now, user.timezone);
    final firstName = profile?.displayName?.trim().split(' ').firstOrNull;
    final loading = mealsAsync.isLoading && !mealsAsync.hasValue;

    final children = <Widget>[
      _Greeting(
        key: const ValueKey('greeting'),
        day: day,
        isToday: widget.isToday,
        now: localNow,
        firstName: firstName,
      ),
      SgEntrance(
        key: const ValueKey('hero'),
        index: 0,
        child: CalorieHeroCard(
          eaten: eaten,
          goal: user?.calorieGoal,
          mealCount: meals.length,
        ),
      ),
      const SizedBox(key: ValueKey('hero-gap'), height: 10),
      SgEntrance(
        key: const ValueKey('macros'),
        index: 1,
        child: MacroCardsRow(
          day: day,
          proteinG: protein,
          carbsG: carbs,
          fatG: fat,
          proteinGoal: user?.proteinGoal,
          carbsGoal: user?.carbsGoal,
          fatGoal: user?.fatGoal,
        ),
      ),
      if (widget.isToday && user != null)
        SgEntrance(
            key: const ValueKey('suggestions'),
            index: 2,
            child: SuggestionsStrip(user: user)),
      SgSectionHeader(
        key: const ValueKey('section'),
        title: 'Meals',
        action: meals.isEmpty
            ? null
            : Labels.count(meals.length, 'logged', 'logged'),
      ),
    ];

    if (loading) {
      children.addAll(const [
        SgMealCardSkeleton(key: ValueKey('skeleton-a')),
        SgMealCardSkeleton(key: ValueKey('skeleton-b')),
      ]);
    } else if (items.isEmpty && !showPresence) {
      children.add(
        widget.isToday
            ? EmptyState(
                key: const ValueKey('empty'),
                compact: true,
                illustration: SgIllustrationKind.plate,
                title: 'Snap your first meal',
                message: 'Take a photo, or type what you ate below.',
                actionLabel: 'Open camera',
                onAction: () => context.push('/capture'),
              )
            : EmptyState(
                key: const ValueKey('empty'),
                compact: true,
                illustration: SgIllustrationKind.notebook,
                title: 'Nothing logged on ${DateFormat('EEEE').format(day)}',
                message: 'Type below to add a meal to this day.',
              ),
      );
    } else {
      _TimeOfDay? lastBucket;
      var index = 0;
      for (final item in items) {
        final bucket = _TimeOfDay.of(item.time);
        if (bucket != lastBucket) {
          lastBucket = bucket;
          children.add(_BucketLabel(
              key: ValueKey('bucket-${bucket.name}'), bucket: bucket));
        }
        // Only a real meal can be the deep-link anchor (null == null must not
        // tag every message/proposal row with the same GlobalKey).
        final isAnchor =
            widget.anchorMealId != null && item.meal?.id == widget.anchorMealId;
        children.add(
          Padding(
            key: isAnchor ? _anchorKey : ValueKey(item.key),
            padding: const EdgeInsets.only(bottom: 10),
            child: SgEntrance(
              index: math.min(index++, 6),
              child: switch (item.type) {
                _TimelineType.message => MessageBubble(message: item.message!),
                _TimelineType.proposal =>
                  ProposalMealCard(proposal: item.proposal!),
                _TimelineType.meal =>
                  ConfirmedMealCard(meal: item.meal!, highlight: isAnchor),
                _TimelineType.job => PendingAnalysisCard(job: item.job!),
              },
            ),
          ),
        );
      }
    }
    if (showPresence) {
      children.add(Padding(
        key: const ValueKey('presence'),
        padding: const EdgeInsets.only(bottom: 14),
        child: AssistantPresence(state: composer),
      ));
    }
    final closeCard = _DayCloseCard.maybe(
      isToday: widget.isToday,
      now: localNow,
      meals: meals,
      eaten: eaten,
      proteinG: protein,
      proteinGoal: user?.proteinGoal,
    );
    if (closeCard != null) {
      children.add(
          KeyedSubtree(key: const ValueKey('day-close'), child: closeCard));
    }
    children.add(const SizedBox(key: ValueKey('end'), height: 16));

    // Timeline rows move when items are inserted or re-timed (a proposal is
    // confirmed, a photo finishes). Keyed lookup lets the lazy list move each
    // row's element — and any GlobalKeys inside it, e.g. Heroes — with it.
    assert(children.every((c) => c.key != null),
        'Every Today row needs a stable key for index lookup.');
    final keyed = children;
    final indexOf = <Key, int>{
      for (var i = 0; i < keyed.length; i++) keyed[i].key!: i,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            maxWidth: SnapGrubDesignTokens.maxConversationWidth),
        child: ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          itemCount: keyed.length,
          itemBuilder: (context, i) => keyed[i],
          findChildIndexCallback: (key) => indexOf[key],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.day,
    super.key,
    required this.isToday,
    required this.now,
    this.firstName,
  });

  final DateTime day;
  final bool isToday;
  final DateTime now;
  final String? firstName;

  static String greeting(DateTime now) => switch (dayPhaseFor(now)) {
        DayPhase.dawn => 'Good morning',
        DayPhase.noon => 'Good afternoon',
        DayPhase.dusk => 'Good evening',
        DayPhase.night => 'Good evening',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = firstName?.isNotEmpty == true ? ', $firstName' : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Text(
        isToday
            ? '${greeting(now)}$name'
            : DateFormat('EEEE, d MMMM').format(day),
        style: theme.textTheme.headlineMedium,
      ),
    );
  }
}

enum _TimeOfDay {
  morning('Morning'),
  midday('Midday'),
  evening('Evening'),
  late('Late');

  const _TimeOfDay(this.label);
  final String label;

  static _TimeOfDay of(DateTime time) {
    final h = time.toLocal().hour;
    if (h >= 4 && h < 11) return _TimeOfDay.morning;
    if (h >= 11 && h < 16) return _TimeOfDay.midday;
    if (h >= 16 && h < 21) return _TimeOfDay.evening;
    return _TimeOfDay.late;
  }
}

class _BucketLabel extends StatelessWidget {
  const _BucketLabel({required this.bucket, super.key});

  final _TimeOfDay bucket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 4, 8),
      child: Row(
        children: [
          Text(
            bucket.label,
            style: context.sg.editorial.copyWith(
              fontSize: 17,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: .6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat-first, non-judgmental recap once the day is winding down.
class _DayCloseCard extends StatelessWidget {
  const _DayCloseCard({
    required this.headline,
    required this.detail,
  });

  final String headline;
  final String detail;

  static Widget? maybe({
    required bool isToday,
    required DateTime now,
    required List<Meal> meals,
    required double eaten,
    required double proteinG,
    required double? proteinGoal,
  }) {
    if (meals.isEmpty) return null;
    if (isToday && now.hour < 20) return null;
    final proteinText = proteinGoal == null || proteinGoal <= 0
        ? ''
        : ' · ${(proteinG / proteinGoal * 100).round()}% protein';
    return _DayCloseCard(
      headline: 'That’s a wrap',
      detail:
          '${Labels.count(meals.length, 'meal')} · ${Labels.kcal(eaten)}$proteinText',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SgCard(
        color: theme.colorScheme.primaryContainer.withValues(alpha: .45),
        child: Row(
          children: [
            const SgIllustration(kind: SgIllustrationKind.sunrise, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline, style: context.sg.editorial),
                  const SizedBox(height: 2),
                  Text(detail, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TimelineType { message, proposal, meal, job }

class _TimelineItem {
  const _TimelineItem._({
    required this.type,
    required this.time,
    required this.key,
    this.message,
    this.proposal,
    this.meal,
    this.job,
  });

  factory _TimelineItem.message(ThreadMessage value) => _TimelineItem._(
        type: _TimelineType.message,
        time: value.createdAt,
        key: 'm-${value.id}',
        message: value,
      );

  factory _TimelineItem.proposal(MealChangeProposal value) => _TimelineItem._(
        type: _TimelineType.proposal,
        time: value.createdAt.add(const Duration(milliseconds: 1)),
        key: 'p-${value.id}',
        proposal: value,
      );

  factory _TimelineItem.meal(Meal value) => _TimelineItem._(
        type: _TimelineType.meal,
        time: value.loggedAt,
        key: 'meal-${value.id}',
        meal: value,
      );

  factory _TimelineItem.job(AnalysisJob value) => _TimelineItem._(
        type: _TimelineType.job,
        time: value.startedAt,
        key: 'job-${value.id}',
        job: value,
      );

  final _TimelineType type;
  final DateTime time;
  final String key;
  final ThreadMessage? message;
  final MealChangeProposal? proposal;
  final Meal? meal;
  final AnalysisJob? job;
}
