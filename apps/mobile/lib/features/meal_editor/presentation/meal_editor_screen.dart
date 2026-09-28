import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/app/router/nav.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/features/custom_foods/data/custom_food_repository.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/application/meal_actions.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_editor/presentation/widgets/custom_food_picker.dart';
import 'package:snapgrub/features/meal_editor/presentation/widgets/meal_fix_sentence.dart';
import 'package:snapgrub/features/meal_editor/presentation/widgets/meal_item_row.dart';
import 'package:snapgrub/features/meal_editor/presentation/widgets/meal_review_bottom_bar.dart';
import 'package:snapgrub/features/meal_editor/presentation/widgets/meal_review_header.dart';
import 'package:snapgrub/features/meal_editor/presentation/widgets/meal_review_logic.dart';
import 'package:snapgrub/features/meal_editor/presentation/widgets/meal_totals_card.dart';
import 'package:snapgrub/features/meal_editor/presentation/widgets/meal_trust_line.dart';
import 'package:snapgrub/features/multimodal/data/multimodal_remote_service.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/templates/data/template_repository.dart';

/// Meal Review: check an estimate (or edit a saved meal) and log it.
class MealEditorScreen extends ConsumerStatefulWidget {
  const MealEditorScreen({this.mealId, this.initialDraft, super.key});

  final String? mealId;
  final MealDraft? initialDraft;

  @override
  ConsumerState<MealEditorScreen> createState() => _MealEditorScreenState();
}

class _MealEditorScreenState extends ConsumerState<MealEditorScreen> {
  static const _highlightFor = Duration(milliseconds: 1800);

  final _titleController = TextEditingController();
  final _fixKey = GlobalKey<MealFixSentenceState>();

  MealDraft? _draft;
  Meal? _savedMeal;
  String _baseline = '';

  bool _loading = true;
  Object? _loadError;
  bool _missing = false;
  bool _signedOut = false;

  bool _saving = false;
  String? _saveError;

  bool _fixing = false;
  String? _fixError;

  Set<String> _highlighted = const {};
  Timer? _highlightTimer;
  String? _autofocusItemId;

  /// Set once the user has chosen to leave (saved, deleted or discarded) so
  /// the unsaved-changes guard stands aside.
  bool _leaving = false;

  bool get _isNew => widget.mealId == null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDraft;
    if (initial != null) {
      _adopt(initial);
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Loading

  void _adopt(MealDraft draft) {
    _titleController.text = draft.title;
    _baseline = mealDraftFingerprint(draft);
    _draft = draft;
    _loading = false;
  }

  Future<void> _load() async {
    try {
      final user = await ref.read(homeUserContextProvider.future);
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _signedOut = true;
          _loading = false;
        });
        return;
      }
      final repo = ref.read(mealRepositoryProvider);
      final mealId = widget.mealId;
      if (mealId == null) {
        final draft =
            repo.newManualDraft(userId: user.userId, timezone: user.timezone);
        setState(() => _adopt(draft));
        return;
      }
      final meal = await repo.getMeal(mealId);
      if (!mounted) return;
      if (meal == null || meal.isDeleted) {
        setState(() {
          _missing = true;
          _loading = false;
        });
        return;
      }
      setState(() {
        _savedMeal = meal;
        _adopt(_draftFromMeal(meal));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  void _retryLoad() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  MealDraft _draftFromMeal(Meal meal) => MealDraft(
        id: meal.id,
        userId: meal.userId,
        clientId: meal.clientId,
        timezone: meal.timezone,
        title: meal.title,
        mealType: meal.mealType,
        source: meal.source,
        loggedAt: meal.loggedAt,
        expectedRevision: meal.revision,
        confidenceOverall: meal.confidenceOverall,
        provenanceType: meal.provenanceType,
        analysisJobId: meal.analysisJobId,
        photoAssetId: meal.photoAssetId,
        items: [
          for (final item in meal.items)
            MealDraftItem(
              id: item.id,
              clientId: item.clientId,
              name: item.name,
              foodRefKind: item.foodRefKind,
              canonicalFoodId: item.canonicalFoodId,
              brandedProductId: item.brandedProductId,
              customFoodId: item.customFoodId,
              quantity: item.quantity,
              unit: item.unit,
              gramsEstimated: item.gramsEstimated,
              caloriesKcal: item.caloriesKcal,
              proteinG: item.proteinG,
              carbsG: item.carbsG,
              fatG: item.fatG,
              confidence: item.confidence,
              sourceType: item.sourceType,
              sourceId: item.sourceId,
              notes: item.notes,
            ),
        ],
      );

  // ---------------------------------------------------------------------------
  // Leaving

  bool get _dirty {
    final draft = _draft;
    if (draft == null || _leaving) return false;
    // A fresh estimate that hasn't been logged yet would be lost entirely.
    if (_isNew && widget.initialDraft != null) return true;
    return mealDraftFingerprint(draft) != _baseline;
  }

  Future<bool> _confirmDiscard() => confirmDestructive(
        context,
        title: _isNew ? 'Discard this meal?' : 'Discard changes?',
        message: _isNew
            ? 'It hasn’t been logged yet.'
            : 'Your edits won’t be saved.',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep editing',
        icon: Icons.edit_off_rounded,
      );

  Future<void> _handleBack() async {
    if (_dirty && !await _confirmDiscard()) return;
    if (!mounted) return;
    _leaving = true;
    // Item-removal undo snackbars belong to this screen only.
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    context.popOrGo('/home');
  }

  // ---------------------------------------------------------------------------
  // Meal-level edits

  void _changed() => setState(() {});

  Future<void> _pickMealType() async {
    final draft = _draft!;
    final type = await showMealTypeSheet(context, draft.mealType);
    if (type == null || !mounted) return;
    setState(() => draft.mealType = type);
  }

  Future<void> _pickTime() async {
    final draft = _draft!;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
      initialDate: draft.loggedAt,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(draft.loggedAt),
    );
    if (time == null || !mounted) return;
    SgHaptics.tick();
    setState(() {
      draft.loggedAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _onTitleTap() {
    if (!ref.read(appConfigProvider).isE2e) return;
    _titleController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _titleController.text.length,
    );
  }

  // ---------------------------------------------------------------------------
  // Items

  /// True when the draft is just the untouched placeholder item.
  bool _onlyBlankItem(MealDraft draft) =>
      draft.items.length == 1 &&
      draft.items.first.name.trim().isEmpty &&
      draft.items.first.caloriesKcal == 0;

  void _addItem() {
    final item = MealDraftItem();
    SgHaptics.tap();
    setState(() {
      _draft!.items.add(item);
      _autofocusItemId = item.id;
    });
  }

  void _removeItem(MealDraftItem item) {
    final draft = _draft!;
    final index = draft.items.indexOf(item);
    if (index < 0 || draft.items.length <= 1) return;
    SgHaptics.tap();
    setState(() => draft.items.removeAt(index));
    final name = item.name.trim().isEmpty ? 'Item' : '“${item.name.trim()}”';
    showUndoSnackBar(
      context,
      message: '$name removed',
      icon: Icons.delete_outline_rounded,
      commit: () async {},
      onUndo: () {
        if (!mounted || _leaving || draft.items.contains(item)) return;
        setState(() {
          draft.items.insert(index.clamp(0, draft.items.length), item);
        });
      },
    );
  }

  Future<void> _addCustomFood() async {
    final draft = _draft!;
    try {
      final user = await ref.read(homeUserContextProvider.future);
      if (user == null || !mounted) return;
      final foods =
          await ref.read(customFoodsProvider(user.userId).future);
      if (!mounted) return;
      final selected = await showCustomFoodPicker(context, foods);
      if (selected == null || !mounted) return;
      final item = ref.read(customFoodRepositoryProvider).toMealItem(selected);
      setState(() {
        if (_onlyBlankItem(draft)) draft.items.clear();
        draft.items.add(item);
      });
      _flash({item.id});
    } catch (error) {
      if (!mounted) return;
      showSgToast(context, friendlyError(error).message,
          icon: Icons.info_outline_rounded);
    }
  }

  void _flash(Set<String> ids) {
    if (ids.isEmpty) return;
    _highlightTimer?.cancel();
    setState(() => _highlighted = ids);
    _highlightTimer = Timer(_highlightFor, () {
      if (mounted) setState(() => _highlighted = const {});
    });
  }

  // ---------------------------------------------------------------------------
  // Fix with a sentence

  Future<void> _applyFix(String correction) async {
    final draft = _draft!;
    setState(() {
      _fixing = true;
      _fixError = null;
    });
    try {
      final user = await ref.read(homeUserContextProvider.future);
      final profile = (await ref.read(profileControllerProvider.future)).profile;
      if (user == null || profile == null) {
        throw ArgumentError('Finish setting up your profile first.');
      }
      final revised = await ref.read(multimodalRemoteServiceProvider).parseText(
            userId: user.userId,
            profile: profile,
            text: correctionPrompt(draft, correction),
          );
      if (!mounted) return;
      final before = draft.items.map(itemContentSignature).toSet();
      final changed = {
        for (final item in revised.items)
          if (!before.contains(itemContentSignature(item))) item.id,
      };
      setState(() {
        if (revised.items.isNotEmpty) draft.items = revised.items;
        if (revised.confidenceOverall != null) {
          draft.confidenceOverall = revised.confidenceOverall;
        }
        _fixing = false;
      });
      _fixKey.currentState?.clear();
      _flash(changed);
      SgHaptics.tick();
      showSgToast(
        context,
        changed.isEmpty
            ? 'No changes needed'
            : 'Updated ${Labels.count(changed.length, 'item')}',
        icon: Icons.auto_fix_high_rounded,
      );
    } catch (error) {
      if (!mounted) return;
      SgHaptics.warn();
      setState(() {
        _fixing = false;
        _fixError = friendlyError(error).message;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Save / saved meal / delete

  Future<void> _save() async {
    final draft = _draft!;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final meal = await ref.read(mealRepositoryProvider).saveDraft(draft);
      if (!mounted) return;
      unawaited(SgHaptics.logged());
      _leaving = true;
      _saving = false;
      // Resolve everything the confirmation needs before the pop: the root
      // ScaffoldMessenger outlives this route, so the snackbar lands on the
      // destination screen.
      final isNew = _isNew;
      context.popOrGo('/home', meal);
      if (isNew) {
        unawaited(MealActions.announceLogged(context, ref, meal));
      } else {
        showSgToast(context, 'Saved');
      }
    } catch (error) {
      if (!mounted) return;
      SgHaptics.warn();
      setState(() {
        _saving = false;
        _saveError = friendlyError(error).message;
      });
    }
  }

  Future<void> _saveTemplate() async {
    final draft = _draft!;
    try {
      draft.validate();
      await ref.read(templateRepositoryProvider).saveFromDraft(draft);
      if (!mounted) return;
      SgHaptics.tap();
      showSgToast(context, 'Added to Saved meals',
          icon: Icons.bookmark_added_rounded);
    } catch (error) {
      if (!mounted) return;
      showSgToast(context, friendlyError(error).message,
          icon: Icons.info_outline_rounded);
    }
  }

  Future<void> _delete() async {
    final mealId = widget.mealId;
    if (mealId == null) return;
    final confirmed = await confirmDestructive(
      context,
      title: 'Delete this meal?',
      message: 'This removes it from your totals.',
      confirmLabel: 'Delete meal',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final repo = ref.read(mealRepositoryProvider);
      final meal = await repo.getMeal(mealId) ?? _savedMeal;
      if (meal != null) await repo.deleteMeal(meal);
      if (!mounted) return;
      _leaving = true;
      _saving = false;
      context.popOrGo('/home');
      showSgToast(context, 'Meal deleted', icon: Icons.delete_outline_rounded);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = friendlyError(error).message;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return PopScope<Object?>(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: E2eId(
        id: 'scaffold.meal_editor',
        child: Scaffold(
          appBar: _buildAppBar(context, draft),
          bottomNavigationBar: draft == null
              ? null
              : MealReviewBottomBar(
                  caloriesKcal: draft.caloriesKcal,
                  proteinG: draft.proteinG,
                  carbsG: draft.carbsG,
                  fatG: draft.fatG,
                  actionLabel: _isNew ? 'Log meal' : 'Save changes',
                  saving: _saving,
                  onSave: _fixing ? null : _save,
                  errorMessage: _saveError,
                ),
          body: PremiumBackdrop(child: _buildBody(context)),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, MealDraft? draft) {
    return AppBar(
      leading: E2eId(
        id: 'nav.home',
        child: IconButton(
          tooltip: _isNew ? 'Close' : 'Back',
          onPressed: _handleBack,
          icon: Icon(
              _isNew ? Icons.close_rounded : Icons.arrow_back_rounded),
        ),
      ),
      title: Text(_isNew ? 'Review meal' : 'Edit meal'),
      actions: [
        if (draft != null)
          E2eId(
            id: 'meal.save_template',
            child: IconButton(
              tooltip: 'Save meal',
              onPressed: _saving ? null : _saveTemplate,
              icon: const Icon(Icons.bookmark_add_outlined),
            ),
          ),
        if (draft != null && !_isNew)
          E2eId(
            id: 'meal.more',
            child: PopupMenuButton<String>(
              tooltip: 'More',
              enabled: !_saving,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'delete') _delete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: E2eId(
                    id: 'meal.delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: SnapGrubDesignTokens.space12),
                        const Text('Delete meal'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const _ReviewSkeleton();
    if (_signedOut) {
      return EmptyState(
        illustration: SgIllustrationKind.notebook,
        title: 'Sign in to log meals',
        message: 'Meals are saved to your account.',
        actionLabel: 'Go back',
        onAction: () => context.popOrGo('/home'),
      );
    }
    if (_missing) {
      return EmptyState(
        illustration: SgIllustrationKind.notebook,
        title: 'Meal not found',
        message: 'It may have been deleted on another device.',
        actionLabel: 'Back to Today',
        onAction: () => context.popOrGo('/home'),
      );
    }
    final loadError = _loadError;
    if (loadError != null) {
      return ErrorState(error: loadError, onRetry: _retryLoad);
    }

    final draft = _draft!;
    final theme = Theme.of(context);
    final canRemove = draft.items.length > 1 && !_fixing;
    final showFix = draft.items.any((item) => item.name.trim().isNotEmpty);
    final remote = ref.watch(multimodalRemoteServiceProvider);
    final itemCount = draft.items.length;

    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: SnapGrubDesignTokens.maxContentWidth),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            SnapGrubDesignTokens.space16,
            SnapGrubDesignTokens.space8,
            SnapGrubDesignTokens.space16,
            SnapGrubDesignTokens.space32,
          ),
          children: [
            MealReviewHeader(
              draft: draft,
              savedMeal: _savedMeal,
              titleController: _titleController,
              onTitleChanged: (value) => setState(() => draft.title = value),
              onTitleTap: _onTitleTap,
              onPickMealType: _pickMealType,
              onPickTime: _pickTime,
            ),
            const SizedBox(height: SnapGrubDesignTokens.space20),
            MealTotalsCard(
              caloriesKcal: draft.caloriesKcal,
              proteinG: draft.proteinG,
              carbsG: draft.carbsG,
              fatG: draft.fatG,
            ),
            if (MealTrustLine.shouldShow(draft)) ...[
              const SizedBox(height: SnapGrubDesignTokens.space12),
              MealTrustLine(draft: draft),
            ],
            const SizedBox(height: SnapGrubDesignTokens.space24),
            Semantics(
              header: true,
              child: Row(
                children: [
                  Expanded(
                    child: Text('Items',
                        style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    Labels.count(itemCount, 'item'),
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space12),
            for (var i = 0; i < draft.items.length; i++)
              _buildItem(draft.items[i], i, canRemove),
            const SizedBox(height: SnapGrubDesignTokens.space4),
            Wrap(
              spacing: SnapGrubDesignTokens.space8,
              runSpacing: SnapGrubDesignTokens.space8,
              children: [
                E2eId(
                  id: 'meal.add_item',
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                          const Size(0, SnapGrubDesignTokens.minTapTarget),
                    ),
                    onPressed: _fixing ? null : _addItem,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add item'),
                  ),
                ),
                E2eId(
                  id: 'meal.add_custom_food',
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                          const Size(0, SnapGrubDesignTokens.minTapTarget),
                    ),
                    onPressed: _fixing ? null : _addCustomFood,
                    icon: const Icon(Icons.bookmark_outline_rounded),
                    label: const Text('Add from My foods'),
                  ),
                ),
              ],
            ),
            if (showFix) ...[
              const SizedBox(height: SnapGrubDesignTokens.space24),
              MealFixSentence(
                key: _fixKey,
                available: remote.isConfigured || remote.e2eMock,
                working: _fixing,
                errorMessage: _fixError,
                onSubmit: _applyFix,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItem(MealDraftItem item, int index, bool canRemove) {
    return KeyedSubtree(
      key: ValueKey(item.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: SnapGrubDesignTokens.space8),
        child: SgEntrance(
          index: index,
          child: Dismissible(
            key: ValueKey('dismiss-${item.id}'),
            direction: canRemove
                ? DismissDirection.endToStart
                : DismissDirection.none,
            background: const _SwipeToRemoveBackground(),
            onDismissed: (_) => _removeItem(item),
            child: MealItemRow(
              item: item,
              index: index,
              onChanged: _changed,
              onRemove: canRemove ? () => _removeItem(item) : null,
              highlighted: _highlighted.contains(item.id),
              working: _fixing,
              autofocusName: item.id == _autofocusItemId,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeToRemoveBackground extends StatelessWidget {
  const _SwipeToRemoveBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding:
          const EdgeInsets.symmetric(horizontal: SnapGrubDesignTokens.space24),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: SnapGrubDesignTokens.space8),
          Text('Remove',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: scheme.onErrorContainer)),
        ],
      ),
    );
  }
}

/// Placeholder shaped like the review screen while a saved meal loads.
class _ReviewSkeleton extends StatelessWidget {
  const _ReviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading meal',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          SnapGrubDesignTokens.space16,
          SnapGrubDesignTokens.space8,
          SnapGrubDesignTokens.space16,
          SnapGrubDesignTokens.space32,
        ),
        children: const [
          SgSkeleton(height: 200, radius: SnapGrubDesignTokens.radiusLg),
          SizedBox(height: SnapGrubDesignTokens.space16),
          SgSkeleton(width: 220, height: 32),
          SizedBox(height: SnapGrubDesignTokens.space12),
          Row(
            children: [
              SgSkeleton(
                  width: 110,
                  height: 40,
                  radius: SnapGrubDesignTokens.radiusPill),
              SizedBox(width: SnapGrubDesignTokens.space8),
              SgSkeleton(
                  width: 150,
                  height: 40,
                  radius: SnapGrubDesignTokens.radiusPill),
            ],
          ),
          SizedBox(height: SnapGrubDesignTokens.space20),
          SgSkeleton(height: 170, radius: SnapGrubDesignTokens.radiusMd),
          SizedBox(height: SnapGrubDesignTokens.space24),
          SgMealCardSkeleton(),
          SgMealCardSkeleton(),
          SgMealCardSkeleton(),
        ],
      ),
    );
  }
}
