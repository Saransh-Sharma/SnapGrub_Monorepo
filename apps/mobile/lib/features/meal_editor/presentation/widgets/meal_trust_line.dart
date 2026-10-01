import 'package:flutter/material.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

/// "Photo estimate · High confidence" with an explainer, plus any analysis
/// warnings as calm amber notes.
class MealTrustLine extends StatelessWidget {
  const MealTrustLine({required this.draft, super.key});

  final MealDraft draft;

  static bool shouldShow(MealDraft draft) =>
      draft.provenanceType != null ||
      draft.confidenceOverall != null ||
      draft.analysisWarnings.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = [
      Labels.provenance(draft.provenanceType),
      if (draft.confidenceOverall != null)
        Labels.confidence(draft.confidenceOverall),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        E2eId(
          id: 'meal.trust',
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: SnapGrubDesignTokens.iconSm, color: scheme.primary),
              const SizedBox(width: SnapGrubDesignTokens.space8),
              Expanded(
                child: Text(
                  summary,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              IconButton(
                tooltip: 'How estimates work',
                onPressed: () => showEstimateExplainer(context, draft),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
        ),
        for (final warning in draft.analysisWarnings) ...[
          const SizedBox(height: SnapGrubDesignTokens.space8),
          _WarningNote(text: warning),
        ],
      ],
    );
  }
}

class _WarningNote extends StatelessWidget {
  const _WarningNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = context.sg.warning;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SnapGrubDesignTokens.space12,
        vertical: SnapGrubDesignTokens.space12,
      ),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusXs),
        border: Border.all(color: warning.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              size: SnapGrubDesignTokens.iconMd, color: warning),
          const SizedBox(width: SnapGrubDesignTokens.space8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Explains where the numbers came from and what "Check portion" means.
Future<void> showEstimateExplainer(BuildContext context, MealDraft draft) {
  final confidence = draft.confidenceOverall;
  return showSgSheet<void>(
    context: context,
    title: 'How estimates work',
    subtitle: confidence == null
        ? Labels.provenance(draft.provenanceType)
        : '${Labels.provenance(draft.provenanceType)} · '
            '${Labels.confidence(confidence)} (${(confidence * 100).round()}%)',
    actions: Builder(
      builder: (context) => FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Got it'),
      ),
    ),
    builder: (context) => const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExplainerPoint(
          icon: Icons.restaurant_menu_rounded,
          title: 'Foods first',
          body: 'We identify each food and use verified nutrition data '
              'where we can.',
        ),
        _ExplainerPoint(
          icon: Icons.straighten_rounded,
          title: 'Portions are estimates',
          body: 'Amounts come from your photo or description. Confidence '
              'shows how sure we are.',
        ),
        _ExplainerPoint(
          icon: Icons.touch_app_rounded,
          title: 'Check flagged items',
          body: 'Tap anything marked “Check portion” to adjust it.',
        ),
      ],
    ),
  );
}

class _ExplainerPoint extends StatelessWidget {
  const _ExplainerPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: SnapGrubDesignTokens.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.energy.soft,
              borderRadius:
                  BorderRadius.circular(SnapGrubDesignTokens.radiusXs),
            ),
            child: Icon(icon,
                size: SnapGrubDesignTokens.iconMd, color: tokens.energy.onSoft),
          ),
          const SizedBox(width: SnapGrubDesignTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: SnapGrubDesignTokens.space4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
