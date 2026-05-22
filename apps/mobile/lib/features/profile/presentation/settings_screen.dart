import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final user = profile?.profile;
    final goal = profile?.activeGoal;

    return AppScaffold(
      title: 'Settings',
      child: ListView(
        children: [
          ListTile(
            title: Text(user?.displayName?.isNotEmpty == true
                ? user!.displayName!
                : 'Profile'),
            subtitle: Text(user == null
                ? 'Not loaded'
                : '${user.locale} - ${user.unitSystem}'),
          ),
          if (goal != null)
            ListTile(
              title: const Text('Active goal'),
              subtitle: Text(
                '${goal.caloriesKcal.toStringAsFixed(0)} kcal - '
                'P ${goal.proteinG.toStringAsFixed(0)} '
                'C ${goal.carbsG.toStringAsFixed(0)} '
                'F ${goal.fatG.toStringAsFixed(0)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const GoalEditScreen()),
              ),
            ),
          const Divider(),
          ListTile(
            title: const Text('Refresh profile'),
            leading: const Icon(Icons.sync),
            onTap: () => ref.read(profileControllerProvider.notifier).refresh(),
          ),
          ListTile(
            title: const Text('Privacy'),
            subtitle: const Text('AI consent, media retention, export, delete'),
            leading: const Icon(Icons.privacy_tip_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/privacy'),
          ),
          ListTile(
            title: const Text('Sign out'),
            leading: const Icon(Icons.logout),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
    );
  }
}

class GoalEditScreen extends ConsumerStatefulWidget {
  const GoalEditScreen({super.key});

  @override
  ConsumerState<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends ConsumerState<GoalEditScreen> {
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  String _goalType = 'lose';
  String? _error;

  @override
  void initState() {
    super.initState();
    final goal = ref.read(profileControllerProvider).valueOrNull?.activeGoal;
    _goalType = goal?.goalType ?? 'lose';
    _caloriesController = TextEditingController(
        text: (goal?.caloriesKcal ?? 1900).toStringAsFixed(0));
    _proteinController =
        TextEditingController(text: (goal?.proteinG ?? 130).toStringAsFixed(0));
    _carbsController =
        TextEditingController(text: (goal?.carbsG ?? 190).toStringAsFixed(0));
    _fatController =
        TextEditingController(text: (goal?.fatG ?? 60).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.valueOrNull?.profile;

    return AppScaffold(
      title: 'Edit Goal',
      child: ListView(
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'lose', label: Text('Lose')),
              ButtonSegment(value: 'maintain', label: Text('Maintain')),
              ButtonSegment(value: 'gain', label: Text('Gain')),
              ButtonSegment(value: 'custom', label: Text('Custom')),
            ],
            selected: {_goalType},
            onSelectionChanged: (value) =>
                setState(() => _goalType = value.single),
          ),
          const SizedBox(height: 16),
          _NumberField(controller: _caloriesController, label: 'Calories'),
          _NumberField(controller: _proteinController, label: 'Protein g'),
          _NumberField(controller: _carbsController, label: 'Carbs g'),
          _NumberField(controller: _fatController, label: 'Fat g'),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          FilledButton(
            onPressed: profileState.isLoading || profile == null
                ? null
                : () async {
                    try {
                      final draft = OnboardingDraft(
                        displayName: profile.displayName ?? '',
                        goalType: _goalType,
                        unitSystem: profile.unitSystem,
                        locale: profile.locale,
                        timezone: profile.timezone,
                        countryCode: profile.countryCode ?? 'IN',
                        cuisinePreferences: profile.cuisinePreferences,
                        caloriesKcal: double.parse(_caloriesController.text),
                        proteinG: double.parse(_proteinController.text),
                        carbsG: double.parse(_carbsController.text),
                        fatG: double.parse(_fatController.text),
                        cameraPrimerSeen: true,
                      );
                      await ref
                          .read(profileControllerProvider.notifier)
                          .completeOnboarding(profile.id, draft);
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (error) {
                      setState(() => _error = error
                          .toString()
                          .replaceFirst('Invalid argument(s): ', ''));
                    }
                  },
            child: profileState.isLoading
                ? const Text('Saving...')
                : const Text('Save goal'),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
