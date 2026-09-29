import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/design_system/effects/device_capabilities.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/core/preferences/ui_preferences.dart';
import 'package:snapgrub/features/milestones/application/streak_provider.dart';
import 'package:snapgrub/features/profile/presentation/widgets/you_rows.dart';

/// Theme, visual effects, haptics, calorie framing and app icon.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  static String effectsCaption(VisualEffectsLevel level) => switch (level) {
        VisualEffectsLevel.full =>
          'Metallic shine and motion. Uses more battery.',
        VisualEffectsLevel.reduced => 'Shine without motion.',
        VisualEffectsLevel.off => 'Flat colors. Best for battery.',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(uiPreferencesProvider);
    final controller = ref.read(uiPreferencesProvider.notifier);
    final osReducedMotion = SgMotion.of(context).reduced;

    return SettingsGroup(
      children: [
        SettingsControl(
          title: 'Theme',
          e2eId: 'settings.theme',
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: {prefs.themeMode},
            onSelectionChanged: (value) {
              SgHaptics.tick();
              controller.setThemeMode(value.single);
            },
          ),
        ),
        SettingsControl(
          title: 'Visual effects',
          e2eId: 'settings.effects',
          caption: osReducedMotion && prefs.effects == VisualEffectsLevel.full
              ? '${effectsCaption(prefs.effects)} Reduce Motion is on.'
              : effectsCaption(prefs.effects),
          child: SegmentedButton<VisualEffectsLevel>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                  value: VisualEffectsLevel.full, label: Text('Full')),
              ButtonSegment(
                  value: VisualEffectsLevel.reduced, label: Text('Reduced')),
              ButtonSegment(value: VisualEffectsLevel.off, label: Text('Off')),
            ],
            selected: {prefs.effects},
            onSelectionChanged: (value) {
              SgHaptics.tick();
              controller.setEffects(value.single);
            },
          ),
        ),
        E2eId(
          id: 'settings.haptics',
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('Haptics'),
            subtitle: const Text('Vibrate on key actions'),
            value: prefs.haptics,
            onChanged: (value) async {
              await controller.setHaptics(value);
              SgHaptics.enabled = value;
              SgHaptics.tick();
            },
          ),
        ),
        SettingsControl(
          title: 'Calorie display',
          e2eId: 'settings.calorie_framing',
          caption: prefs.calorieFraming == CalorieFraming.remaining
              ? 'Show calories left.'
              : 'Show calories eaten.',
          child: SegmentedButton<CalorieFraming>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                  value: CalorieFraming.remaining, label: Text('Remaining')),
              ButtonSegment(value: CalorieFraming.eaten, label: Text('Eaten')),
            ],
            selected: {prefs.calorieFraming},
            onSelectionChanged: (value) {
              SgHaptics.tick();
              controller.setCalorieFraming(value.single);
            },
          ),
        ),
        const _AppIconPicker(),
      ],
    );
  }
}

enum AppIconChoice {
  standard(null, 'Default', 0),
  titanium('AppIconTitanium', 'Titanium', 0),
  gold('AppIconGold', 'Gold', 30),
  holo('AppIconHolo', 'Holo', 100);

  const AppIconChoice(this.iosName, this.label, this.unlockStreakDays);

  /// Name registered under `CFBundleAlternateIcons` (null = primary icon).
  final String? iosName;
  final String label;

  /// Best logging streak needed to unlock (0 = always available).
  final int unlockStreakDays;
}

/// Alternate app icons; rendered only where the platform supports them.
class _AppIconPicker extends ConsumerStatefulWidget {
  const _AppIconPicker();

  @override
  ConsumerState<_AppIconPicker> createState() => _AppIconPickerState();
}

class _AppIconPickerState extends ConsumerState<_AppIconPicker> {
  static const _prefsKey = 'ui.app_icon';

  bool _supported = false;
  AppIconChoice _current = AppIconChoice.standard;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supported = await DeviceCapabilities.instance.supportsAlternateIcons();
    AppIconChoice current = AppIconChoice.standard;
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_prefsKey);
      current = AppIconChoice.values.firstWhere(
        (c) => c.name == name,
        orElse: () => AppIconChoice.standard,
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _supported = supported;
      _current = current;
    });
  }

  Future<void> _choose(AppIconChoice choice, int bestStreak) async {
    if (_busy || choice == _current) return;
    if (bestStreak < choice.unlockStreakDays) {
      SgHaptics.tick();
      showSgToast(
        context,
        'Unlock ${choice.label} with a ${choice.unlockStreakDays}-day streak.',
        icon: Icons.lock_outline_rounded,
      );
      return;
    }
    setState(() => _busy = true);
    SgHaptics.tap();
    final ok = await DeviceCapabilities.instance.setAlternateIcon(choice.iosName);
    if (!mounted) return;
    if (ok) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, choice.name);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _current = choice;
        _busy = false;
      });
    } else {
      setState(() => _busy = false);
      showSgToast(
        context,
        'This icon isn’t available on your device.',
        icon: Icons.info_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) return const SizedBox.shrink();
    final best = ref.watch(streakProvider).best;
    return SettingsControl(
      title: 'App icon',
      e2eId: 'settings.app_icon',
      caption: 'Unlock Gold and Holo with longer streaks.',
      child: Wrap(
        spacing: SnapGrubDesignTokens.space12,
        runSpacing: SnapGrubDesignTokens.space12,
        children: [
          for (final choice in AppIconChoice.values)
            _IconOption(
              choice: choice,
              selected: choice == _current,
              locked: best < choice.unlockStreakDays,
              onTap: () => _choose(choice, best),
            ),
        ],
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.choice,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final AppIconChoice choice;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const size = 52.0;
    const radius = 14.0;
    const mark = Center(child: SnapGrubMark(size: 34));
    final Widget tile = switch (choice) {
      AppIconChoice.standard => DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: mark,
        ),
      AppIconChoice.titanium => const MetalSurface(
          metal: SgMetal.titanium,
          borderRadius: radius,
          child: mark,
        ),
      AppIconChoice.gold => const MetalSurface(
          metal: SgMetal.gold,
          borderRadius: radius,
          child: mark,
        ),
      AppIconChoice.holo => HoloFoil(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: mark,
          ),
        ),
    };
    final label = locked
        ? '${choice.label} icon, locked. Unlock with a '
            '${choice.unlockStreakDays}-day streak'
        : '${choice.label} icon';

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius + 6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: SgMotion.of(context).press,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius + 3),
                  border: Border.all(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: SizedBox.square(
                  dimension: size,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(opacity: locked ? .45 : 1, child: tile),
                      if (locked)
                        Center(
                          child: Icon(Icons.lock_rounded,
                              size: 18, color: scheme.onSurface),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(choice.label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
