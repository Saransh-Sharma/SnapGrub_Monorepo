import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';

class OnboardingCuisineScreen extends ConsumerStatefulWidget {
  const OnboardingCuisineScreen({super.key});

  @override
  ConsumerState<OnboardingCuisineScreen> createState() =>
      _OnboardingCuisineScreenState();
}

class _OnboardingCuisineScreenState
    extends ConsumerState<OnboardingCuisineScreen> {
  late final TextEditingController _cuisineController;
  late final TextEditingController _timezoneController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider);
    _cuisineController =
        TextEditingController(text: draft.cuisinePreferences.join(', '));
    _timezoneController = TextEditingController(text: draft.timezone);
  }

  @override
  void dispose() {
    _cuisineController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Food preferences',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Text('Add cuisines separated by commas.'),
        const SizedBox(height: 24),
        TextField(
          controller: _cuisineController,
          onChanged:
              ref.read(onboardingControllerProvider.notifier).updateCuisines,
          decoration: const InputDecoration(labelText: 'Cuisines'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _timezoneController,
          onChanged:
              ref.read(onboardingControllerProvider.notifier).updateTimezone,
          decoration: const InputDecoration(labelText: 'Timezone'),
        ),
      ],
    );
  }
}
