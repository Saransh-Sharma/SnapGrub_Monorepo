import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/multimodal/data/multimodal_remote_service.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

class TextEntryScreen extends ConsumerStatefulWidget {
  const TextEntryScreen({super.key});

  @override
  ConsumerState<TextEntryScreen> createState() => _TextEntryScreenState();
}

class _TextEntryScreenState extends ConsumerState<TextEntryScreen> {
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
    return AppScaffold(
      title: 'Text meal',
      child: ListView(
        children: [
          E2eId(
            id: 'text_entry.meal',
            child: TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Meal',
                hintText: '2 rotis and dal',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          E2eId(
            id: 'text_entry.review',
            child: FilledButton.icon(
              onPressed: _loading ? null : _parse,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.arrow_forward),
              label: const Text('Review'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _parse() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Enter a meal first.');
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
      final draft = await ref.read(multimodalRemoteServiceProvider).parseText(
            userId: profile.id,
            profile: profile,
            text: text,
          );
      if (mounted) context.go('/meal-editor', extra: draft);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
