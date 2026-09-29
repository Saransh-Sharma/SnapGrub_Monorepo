import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/router/nav.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/multimodal/data/multimodal_remote_service.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

/// Log a meal by describing it. Nothing is saved here: the estimate opens in
/// the meal editor for review.
class TextEntryScreen extends ConsumerStatefulWidget {
  const TextEntryScreen({super.key});

  @override
  ConsumerState<TextEntryScreen> createState() => _TextEntryScreenState();
}

class _TextEntryScreenState extends ConsumerState<TextEntryScreen> {
  static const _examples = [
    '2 rotis and dal',
    'Oats with banana and milk',
    'Chicken wrap and a latte',
  ];

  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Describe a meal',
      e2eId: 'scaffold.text_meal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text('What did you eat?', style: theme.textTheme.titleLarge),
                const SizedBox(height: SnapGrubDesignTokens.space4),
                Text(
                  'Rough amounts are fine.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SnapGrubDesignTokens.space16),
                E2eId(
                  id: 'text_entry.meal',
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    enabled: !_loading,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Meal',
                      hintText: 'e.g. rice, dal and a salad',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: SnapGrubDesignTokens.space8),
                Text(
                  'Examples',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SnapGrubDesignTokens.space8),
                Wrap(
                  spacing: SnapGrubDesignTokens.space8,
                  runSpacing: SnapGrubDesignTokens.space8,
                  children: [
                    for (final example in _examples)
                      ActionChip(
                        label: Text(example),
                        onPressed: _loading
                            ? null
                            : () {
                                SgHaptics.tick();
                                _controller.value = TextEditingValue(
                                  text: example,
                                  selection: TextSelection.collapsed(
                                    offset: example.length,
                                  ),
                                );
                                setState(() => _error = null);
                              },
                      ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: SnapGrubDesignTokens.space16),
                  InlineError(message: _error!),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: SnapGrubDesignTokens.space12,
            ),
            child: E2eId(
              id: 'text_entry.review',
              child: FilledButton.icon(
                onPressed: _loading ? null : _parse,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(_loading ? 'Estimating…' : 'Review'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _parse() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      SgHaptics.warn();
      setState(() => _error = 'Describe your meal first.');
      return;
    }
    SgHaptics.tap();
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = await ref.read(profileControllerProvider.future);
      final profile = state.profile;
      if (profile == null) {
        throw StateError('Profile is not available.');
      }
      final draft = await ref.read(multimodalRemoteServiceProvider).parseText(
            userId: profile.id,
            profile: profile,
            text: text,
          );
      if (mounted) context.continueTo('/meal-editor', extra: draft);
    } catch (error) {
      if (mounted) {
        setState(() => _error =
            'Couldn’t estimate that. ${friendlyError(error).message}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
