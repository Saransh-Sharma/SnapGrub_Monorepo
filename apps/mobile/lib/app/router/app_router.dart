export 'package:snapgrub/app/splash/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/shell/app_shell.dart';
import 'package:snapgrub/app/splash/splash_screen.dart';
import 'package:snapgrub/core/feature_flags/feature_flags.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/auth/presentation/auth_screen.dart';
import 'package:snapgrub/features/barcode/presentation/barcode_screen.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/features/capture/presentation/capture_screen.dart';
import 'package:snapgrub/features/custom_foods/presentation/custom_foods_screen.dart';
import 'package:snapgrub/features/conversation/presentation/day_thread_screen.dart';
import 'package:snapgrub/features/home/presentation/home_screen.dart';
import 'package:snapgrub/features/journal/presentation/journal_screen.dart';
import 'package:snapgrub/features/meal_atlas/presentation/meal_atlas_screen.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_editor/presentation/meal_editor_screen.dart';
import 'package:snapgrub/features/milestones/presentation/milestones_screen.dart';
import 'package:snapgrub/features/recap/presentation/weekly_recap_screen.dart';
import 'package:snapgrub/features/onboarding/presentation/onboarding_flow_screen.dart';
import 'package:snapgrub/features/photo_analysis/presentation/photo_analysis_screen.dart';
import 'package:snapgrub/features/privacy/presentation/privacy_settings_screen.dart';
import 'package:snapgrub/features/progress/presentation/progress_screen.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/profile/presentation/settings_screen.dart';
import 'package:snapgrub/features/templates/presentation/templates_screen.dart';
import 'package:snapgrub/features/text_entry/presentation/text_entry_screen.dart';
import 'package:snapgrub/features/voice_entry/presentation/voice_entry_screen.dart';
import 'package:snapgrub/offline/sync/sync_status_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref
    ..onDispose(refresh.dispose)
    ..listen(authControllerProvider, (_, __) => refresh.notify())
    ..listen(profileControllerProvider, (_, __) => refresh.notify());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlowScreen(),
      ),
      // Tabs: Today · Progress · [Capture] · Atlas · You.
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            FadeThroughBranches(
          currentIndex: shell.currentIndex,
          children: children,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => _HomeEntry(
                initialDay:
                    DateTime.tryParse(state.uri.queryParameters['day'] ?? ''),
                anchorMealId: state.uri.queryParameters['meal'],
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/atlas',
              builder: (context, state) => const MealAtlasScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/capture',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          fullscreenDialog: true,
          opaque: false,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          child: CaptureScreen(
            initialMode: CaptureMode.fromName(
                state.uri.queryParameters['mode']),
          ),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: .94, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/home-legacy',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/meal-editor',
        builder: (context, state) => MealEditorScreen(
          mealId: state.uri.queryParameters['id'],
          initialDraft:
              state.extra is MealDraft ? state.extra! as MealDraft : null,
        ),
      ),
      GoRoute(
        path: '/photo-analysis',
        builder: (context, state) {
          final asset = state.extra;
          if (asset is! CaptureAsset) return const CaptureScreen();
          return PhotoAnalysisScreen(asset: asset);
        },
      ),
      GoRoute(
        path: '/barcode',
        builder: (context, state) => const BarcodeScreen(),
      ),
      GoRoute(
        path: '/text-entry',
        builder: (context, state) => const TextEntryScreen(),
      ),
      GoRoute(
        path: '/voice-entry',
        builder: (context, state) => const VoiceEntryScreen(),
      ),
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '/templates',
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        path: '/custom-foods',
        builder: (context, state) => const CustomFoodsScreen(),
      ),
      GoRoute(
        path: '/settings/goal',
        builder: (context, state) => const GoalEditScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy/ai-consent',
        builder: (context, state) => const AIConsentScreen(),
      ),
      GoRoute(
        path: '/settings/privacy/media-retention',
        builder: (context, state) => const MediaRetentionScreen(),
      ),
      GoRoute(
        path: '/settings/privacy/export',
        builder: (context, state) => const ExportDataScreen(),
      ),
      GoRoute(
        path: '/settings/privacy/delete-account',
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/settings/privacy/clear-local-data',
        builder: (context, state) => const ClearLocalDataScreen(),
      ),
      GoRoute(
        path: '/milestones',
        builder: (context, state) => const MilestonesScreen(),
      ),
      GoRoute(
        path: '/recap',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const WeeklyRecapScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/sync',
        builder: (context, state) => const SyncStatusScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final auth = ref.read(authControllerProvider);
      final profile = ref.read(profileControllerProvider);
      final authState = auth.valueOrNull;
      if (auth.isLoading || authState == null) {
        if (location == '/auth') return null;
        return location == '/splash' ? null : '/splash';
      }

      if (authState.status != AuthStatus.signedIn) {
        return location == '/auth' ? null : '/auth';
      }

      if (profile.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final profileState = profile.valueOrNull;
      if (profileState == null) return location == '/splash' ? null : '/splash';
      if (profileState.needsOnboarding) {
        return location == '/onboarding' ? null : '/onboarding';
      }

      if (location == '/splash' ||
          location == '/auth' ||
          location == '/onboarding') {
        return '/home';
      }
      return null;
    },
  );
});

class _HomeEntry extends ConsumerWidget {
  const _HomeEntry({this.initialDay, this.anchorMealId});

  final DateTime? initialDay;
  final String? anchorMealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags =
        ref.watch(profileControllerProvider).valueOrNull?.featureFlags ??
            const {};
    if (!FeatureFlags(flags).isEnabled(FeatureFlag.conversationalHome)) {
      return const HomeScreen();
    }
    return DayThreadScreen(
      initialDay: initialDay,
      anchorMealId: anchorMealId,
    );
  }
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
