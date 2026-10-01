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
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Log a meal by speaking. The transcript stays editable, and the estimate
/// opens in the meal editor for review.
class VoiceEntryScreen extends ConsumerStatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  ConsumerState<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends ConsumerState<VoiceEntryScreen> {
  static const unavailableMessage = 'Microphone access is off. Type instead.';

  final _speech = SpeechToText();
  final _transcriptController = TextEditingController();
  bool _initializing = true;
  bool _available = false;
  bool _listening = false;
  bool _loading = false;
  double? _confidence;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _speech.stop();
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (headline, caption) = _initializing
        ? ('Getting mic ready…', ' ')
        : !_available
            ? ('Voice unavailable', 'Type your meal below.')
            : _listening
                ? ('Listening…', 'Tap when you’re done.')
                : ('Tap to talk', 'Try “oatmeal with banana.”');

    return AppScaffold(
      title: 'Voice meal',
      e2eId: 'scaffold.voice_meal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const SizedBox(height: SnapGrubDesignTokens.space16),
                Center(
                  child: E2eId(
                    id: 'voice_entry.mic',
                    child: _MicButton(
                      listening: _listening,
                      enabled: _available && !_loading && !_initializing,
                      onPressed: _listening ? _stop : _listen,
                    ),
                  ),
                ),
                const SizedBox(height: SnapGrubDesignTokens.space16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: SnapGrubDesignTokens.space4),
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SnapGrubDesignTokens.space24),
                E2eId(
                  id: 'voice_entry.transcript',
                  child: TextField(
                    controller: _transcriptController,
                    enabled: !_loading,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) {
                      // A hand-edited transcript no longer carries the
                      // recognizer's confidence.
                      _confidence = null;
                      if (_error != null && _available) {
                        setState(() => _error = null);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'What you said',
                      hintText: 'Edit anything we misheard.',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
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
            child: Row(
              children: [
                E2eId(
                  id: 'voice_entry.use_text',
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            if (_listening) await _stop();
                            if (context.mounted) {
                              context.continueTo('/text-entry');
                            }
                          },
                    child: const Text('Type instead'),
                  ),
                ),
                const SizedBox(width: SnapGrubDesignTokens.space8),
                Expanded(
                  child: E2eId(
                    id: 'voice_entry.review',
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
          ),
        ],
      ),
    );
  }

  Future<void> _initialize() async {
    var available = false;
    try {
      available = await _speech.initialize(
        onError: _onSpeechError,
        onStatus: (status) {
          if (mounted) setState(() => _listening = status == 'listening');
        },
      );
    } catch (_) {
      available = false;
    }
    if (!mounted) return;
    setState(() {
      _initializing = false;
      _available = available;
      if (!available) _error = unavailableMessage;
    });
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    final message = switch (error.errorMsg) {
      'error_no_match' ||
      'error_speech_timeout' =>
        'Didn’t catch that. Try again or type it.',
      'error_network' ||
      'error_network_timeout' ||
      'error_server' =>
        'Voice needs internet. Type it instead.',
      'error_permission' ||
      'error_insufficient_permissions' =>
        unavailableMessage,
      'error_busy' => 'Mic is busy. Try again.',
      _ => 'Voice stopped. Try again or type it.',
    };
    setState(() {
      _listening = false;
      _error = message;
    });
  }

  Future<void> _listen() async {
    SgHaptics.tap();
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _listening = true;
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
      ),
      onResult: (result) {
        _transcriptController.value = TextEditingValue(
          text: result.recognizedWords,
          selection:
              TextSelection.collapsed(offset: result.recognizedWords.length),
        );
        _confidence = result.confidence > 0 ? result.confidence : null;
      },
    );
  }

  Future<void> _stop() async {
    SgHaptics.tick();
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _parse() async {
    if (_listening) await _stop();
    final transcript = _transcriptController.text.trim();
    if (transcript.isEmpty) {
      SgHaptics.warn();
      setState(() => _error = _available
          ? 'Say or type your meal first.'
          : 'Type your meal first.');
      return;
    }
    SgHaptics.tap();
    if (mounted) FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = await ref.read(profileControllerProvider.future);
      final profile = state.profile;
      if (profile == null) throw StateError('Profile is not available.');
      final draft =
          await ref.read(multimodalRemoteServiceProvider).parseVoiceTranscript(
                userId: profile.id,
                profile: profile,
                transcript: transcript,
                transcriptConfidence: _confidence,
              );
      if (mounted) context.continueTo('/meal-editor', extra: draft);
    } catch (error) {
      if (mounted) {
        setState(() =>
            _error = 'Couldn’t estimate that. ${friendlyError(error).message}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/// Large round microphone control with a soft pulse while listening.
class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.listening,
    required this.enabled,
    required this.onPressed,
  });

  final bool listening;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.listening && !reduceMotion) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = widget.listening ? scheme.error : scheme.primary;
    final fg = widget.listening ? scheme.onError : scheme.onPrimary;
    const size = 96.0;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.listening ? 'Stop listening' : 'Start listening',
      child: SizedBox.square(
        dimension: size + 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Container(
                  width: size + 40 * t,
                  height: size + 40 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: base.withValues(
                        alpha: widget.listening ? .22 * (1 - t) : 0),
                  ),
                );
              },
            ),
            Material(
              color: widget.enabled ? base : scheme.surfaceContainerHighest,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              elevation: widget.enabled ? 2 : 0,
              child: InkWell(
                onTap: widget.enabled ? widget.onPressed : null,
                child: SizedBox.square(
                  dimension: size,
                  child: ExcludeSemantics(
                    child: Icon(
                      widget.listening ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 40,
                      color: widget.enabled ? fg : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
