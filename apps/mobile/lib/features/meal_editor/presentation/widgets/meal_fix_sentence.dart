import 'package:flutter/material.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';

/// "Fix with a sentence": the user describes a correction in plain words and
/// the parser returns a revised set of items.
class MealFixSentence extends StatefulWidget {
  const MealFixSentence({
    required this.available,
    required this.working,
    required this.onSubmit,
    this.errorMessage,
    super.key,
  });

  /// False when this build has no parser to talk to.
  final bool available;
  final bool working;
  final ValueChanged<String> onSubmit;
  final String? errorMessage;

  @override
  State<MealFixSentence> createState() => MealFixSentenceState();
}

class MealFixSentenceState extends State<MealFixSentence> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Clears the field after a successful correction.
  void clear() => _controller.clear();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.working || !widget.available) return;
    FocusScope.of(context).unfocus();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = widget.available && !widget.working;
    return SgCard(
      padding: const EdgeInsets.all(SnapGrubDesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded,
                  size: SnapGrubDesignTokens.iconMd, color: scheme.primary),
              const SizedBox(width: SnapGrubDesignTokens.space8),
              Expanded(
                child:
                    Text('Describe a fix', style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: SnapGrubDesignTokens.space12),
          E2eId(
            id: 'meal.fix_sentence',
            child: TextField(
              controller: _controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'e.g. “2 rotis, no ghee”',
                helperText: widget.available
                    ? null
                    : 'Needs internet. You can still edit items above.',
                helperMaxLines: 3,
                suffixIcon: widget.working
                    ? const Padding(
                        padding: EdgeInsets.all(SnapGrubDesignTokens.space12),
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Apply',
                        onPressed: enabled ? _submit : null,
                        icon: const Icon(Icons.arrow_upward_rounded),
                      ),
              ),
            ),
          ),
          if (widget.working) ...[
            const SizedBox(height: SnapGrubDesignTokens.space8),
            Semantics(
              liveRegion: true,
              child: Text(
                'Updating items…',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
          if (widget.errorMessage != null) ...[
            const SizedBox(height: SnapGrubDesignTokens.space8),
            InlineError(message: widget.errorMessage!),
          ],
        ],
      ),
    );
  }
}
