import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/shell/app_shell.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/conversation/application/conversation_controller.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Pinned composer: "+" capture tray, text field with inline dictation
/// (live waveform) and a send button that morphs out of the mic.
class ConversationComposer extends ConsumerStatefulWidget {
  const ConversationComposer({required this.day, super.key});

  final DateTime day;

  @override
  ConsumerState<ConversationComposer> createState() =>
      _ConversationComposerState();
}

class _ConversationComposerState extends ConsumerState<ConversationComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _speech = SpeechToText();
  final ValueNotifier<double> _level = ValueNotifier(0);
  bool _trayOpen = false;
  bool _listening = false;
  bool? _speechReady;

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    _focusNode.dispose();
    _level.dispose();
    super.dispose();
  }

  Future<void> _toggleDictation() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    _speechReady ??= await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        final listening = status == 'listening';
        if (listening != _listening) setState(() => _listening = listening);
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (_speechReady != true) {
      // No speech engine / permission: fall back to the voice screen.
      context.push('/voice-entry');
      return;
    }
    SgHaptics.impact();
    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation),
      onSoundLevelChange: (level) =>
          _level.value = ((level + 2) / 12).clamp(0.0, 1.0),
      onResult: (result) {
        _controller.value = TextEditingValue(
          text: result.recognizedWords,
          selection:
              TextSelection.collapsed(offset: result.recognizedWords.length),
        );
      },
    );
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
    _controller.clear();
    if (_trayOpen) setState(() => _trayOpen = false);
    await ref
        .read(conversationControllerProvider.notifier)
        .sendMessage(widget.day, text);
  }

  void _open(String route) {
    setState(() => _trayOpen = false);
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationControllerProvider);
    final motion = SgMotion.of(context);
    final scheme = Theme.of(context).colorScheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          12, 4, 12, keyboard ? 8 : AppShell.bottomInset(context) - 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: motion.enter,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic),
                alignment: AlignmentDirectional.bottomStart,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _trayOpen
                  ? Padding(
                      key: const ValueKey('capture-tray'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: LiquidGlass(
                        borderRadius: 24,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 10),
                        child: Row(
                          children: [
                            _CaptureShortcut(
                              id: 'camera',
                              icon: Icons.photo_camera_rounded,
                              label: 'Camera',
                              onTap: () => _open('/capture'),
                            ),
                            _CaptureShortcut(
                              id: 'scan',
                              icon: Icons.qr_code_scanner_rounded,
                              label: 'Scan',
                              onTap: () => _open('/capture?mode=barcode'),
                            ),
                            _CaptureShortcut(
                              id: 'voice',
                              icon: Icons.graphic_eq_rounded,
                              label: 'Voice',
                              onTap: () {
                                setState(() => _trayOpen = false);
                                _toggleDictation();
                              },
                            ),
                            _CaptureShortcut(
                              id: 'manual',
                              icon: Icons.edit_note_rounded,
                              label: 'Manual',
                              onTap: () => _open('/meal-editor'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('capture-tray-closed')),
            ),
            LiquidGlass(
              borderRadius: 28,
              padding: const EdgeInsets.all(5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  E2eId(
                    id: 'conversation.add_menu',
                    child: IconButton(
                      tooltip: _trayOpen ? 'Close' : 'Add food options',
                      onPressed: state.isSending
                          ? null
                          : () {
                              SgHaptics.tick();
                              setState(() => _trayOpen = !_trayOpen);
                            },
                      icon: AnimatedRotation(
                        turns: _trayOpen ? .125 : 0,
                        duration: motion.settle,
                        curve: motion.emphasized,
                        child: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        E2eId(
                          id: 'conversation.composer',
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: _listening
                                  ? 'Listening…'
                                  : 'What did you eat?',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 12),
                            ),
                            onSubmitted: (_) => _send(),
                            onTapOutside: (_) => _focusNode.unfocus(),
                          ),
                        ),
                        if (_listening)
                          Positioned(
                            right: 4,
                            child: IgnorePointer(
                              child: _Waveform(
                                level: _level,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      final mode = hasText
                          ? 'send'
                          : _listening
                              ? 'stop'
                              : 'mic';
                      return E2eId(
                        id: 'conversation.send_or_voice',
                        child: IconButton.filled(
                          tooltip: switch (mode) {
                            'send' => 'Send',
                            'stop' => 'Stop dictation',
                            _ => 'Dictate a meal',
                          },
                          onPressed: state.isSending
                              ? null
                              : hasText
                                  ? _send
                                  : _toggleDictation,
                          icon: AnimatedSwitcher(
                            duration: motion.press,
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                              scale: CurvedAnimation(
                                  parent: animation, curve: Curves.easeOutBack),
                              child: RotationTransition(
                                turns: Tween(begin: -.1, end: 0.0)
                                    .animate(animation),
                                child: child,
                              ),
                            ),
                            child: Icon(
                              switch (mode) {
                                'send' => Icons.arrow_upward_rounded,
                                'stop' => Icons.stop_rounded,
                                _ => Icons.mic_rounded,
                              },
                              key: ValueKey(mode),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Waveform extends StatefulWidget {
  const _Waveform({required this.level, required this.color});

  final ValueNotifier<double> level;
  final Color color;

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c, widget.level]),
      builder: (context, _) => CustomPaint(
        size: const Size(46, 24),
        painter: _WavePainter(
          phase: _c.value,
          level: widget.level.value,
          color: widget.color,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.phase, required this.level, required this.color});

  final double phase;
  final double level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 7;
    final gap = size.width / bars;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < bars; i++) {
      final wobble = (math.sin((phase * 2 * math.pi) + i * .9) + 1) / 2; // 0..1
      final h = size.height * (.18 + .82 * (.25 + .75 * level) * wobble);
      final x = gap * i + gap / 2;
      canvas.drawLine(Offset(x, (size.height - h) / 2),
          Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.phase != phase || old.level != level;
}

class _CaptureShortcut extends StatelessWidget {
  const _CaptureShortcut({
    required this.id,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: E2eId(
          id: 'conversation.capture.$id',
          child: PremiumPressable(
            semanticLabel: label,
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.sg.energy.soft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 21, color: context.sg.energy.onSoft),
                ),
                const SizedBox(height: 5),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ),
      );
}

/// Assistant "thinking" row or streaming text; announced to screen readers.
class AssistantPresence extends StatelessWidget {
  const AssistantPresence({required this.state, super.key});

  final ConversationComposerState state;

  @override
  Widget build(BuildContext context) {
    final text = state.streamingText.trim();
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .82,
          ),
          child: AnimatedSwitcher(
            duration: SgMotion.of(context).settle,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            ),
            child: text.isEmpty
                ? Row(
                    key: ValueKey(state.activity),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ThinkingDots(),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          state.activity ?? 'Thinking…',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    key: const ValueKey('streaming-copy'),
                    style: theme.textTheme.bodyLarge,
                  ),
          ),
        ),
      ),
    );
  }
}

class ThinkingDots extends StatefulWidget {
  const ThinkingDots({super.key});

  @override
  State<ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SgMotion.of(context).reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final phase = (_controller.value * math.pi * 2) - index * .8;
          final lift = math.max<double>(0, math.sin(phase)) * 4;
          return Transform.translate(
            offset: Offset(0, -lift),
            child: Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          );
        }),
      ),
    );
  }
}

/// Chat bubble. User bubbles are sage; assistant text sits on the page;
/// errors get a calm tinted bubble with a retry-friendly tone.
class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final ThreadMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = message.role == ThreadMessageRole.user;
    final error = message.kind == ThreadMessageKind.error;
    final activity = message.kind == ThreadMessageKind.activity;
    final failed = message.deliveryState == MessageDeliveryState.failed ||
        message.deliveryState == MessageDeliveryState.queued;
    if (activity) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 16, color: context.sg.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.text ?? '',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .82),
        child: Column(
          crossAxisAlignment:
              user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: user
                    ? scheme.primary
                    : error
                        ? context.sg.warning.withValues(alpha: .14)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(22).copyWith(
                  bottomRight: user ? const Radius.circular(7) : null,
                  bottomLeft: user ? null : const Radius.circular(7),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: user || error ? 15 : 2,
                  vertical: user || error ? 11 : 4,
                ),
                child: Text(
                  message.text ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: user ? scheme.onPrimary : null,
                  ),
                ),
              ),
            ),
            if (user && failed)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Text(
                  message.deliveryState == MessageDeliveryState.queued
                      ? 'Waiting for connection'
                      : 'Not sent',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: context.sg.warning),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
