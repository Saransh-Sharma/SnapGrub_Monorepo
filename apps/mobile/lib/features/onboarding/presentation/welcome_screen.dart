import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';

class OnboardingWelcomeScreen extends ConsumerStatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  ConsumerState<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends ConsumerState<OnboardingWelcomeScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: ref.read(onboardingControllerProvider).displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Make SnapGrub yours', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Text('A few details help set calorie and macro targets you can edit anytime.'),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          onChanged: ref.read(onboardingControllerProvider.notifier).updateName,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
      ],
    );
  }
}
