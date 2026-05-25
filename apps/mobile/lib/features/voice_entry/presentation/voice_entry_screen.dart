import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/multimodal/data/multimodal_remote_service.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceEntryScreen extends ConsumerStatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  ConsumerState<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends ConsumerState<VoiceEntryScreen> {
  final _speech = SpeechToText();
  final _transcriptController = TextEditingController();
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
    return AppScaffold(
      title: 'Voice meal',
      child: ListView(
        children: [
          E2eId(
            id: 'voice_entry.transcript',
            child: TextField(
              controller: _transcriptController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Transcript',
                hintText: 'Say a short meal, then edit the transcript here.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: !_available || _loading
                      ? null
                      : (_listening ? _stop : _listen),
                  icon: Icon(_listening ? Icons.stop : Icons.mic),
                  label: Text(_listening ? 'Stop' : 'Push to talk'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: E2eId(
                  id: 'voice_entry.review',
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _parse,
                    icon: _loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.arrow_forward),
                    label: const Text('Review'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/text-entry'),
            child: const Text('Use text instead'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }

  Future<void> _initialize() async {
    final available = await _speech.initialize(
      onError: (error) {
        if (mounted) setState(() => _error = error.errorMsg);
      },
      onStatus: (status) {
        if (mounted) setState(() => _listening = status == 'listening');
      },
    );
    if (mounted) {
      setState(() {
        _available = available;
        if (!available) {
          _error = 'Microphone permission is unavailable. Use text instead.';
        }
      });
    }
  }

  Future<void> _listen() async {
    setState(() {
      _error = null;
      _listening = true;
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
      ),
      onResult: (result) {
        _transcriptController.text = result.recognizedWords;
        _transcriptController.selection =
            TextSelection.collapsed(offset: _transcriptController.text.length);
        _confidence = result.confidence > 0 ? result.confidence : null;
      },
    );
  }

  Future<void> _stop() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _parse() async {
    final transcript = _transcriptController.text.trim();
    if (transcript.isEmpty) {
      setState(() => _error = 'Record or type a transcript first.');
      return;
    }
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
      if (mounted) context.go('/meal-editor', extra: draft);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
