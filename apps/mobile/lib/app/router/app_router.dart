import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/auth/presentation/auth_screen.dart';
import 'package:snapgrub/features/barcode/presentation/barcode_screen.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/features/custom_foods/presentation/custom_foods_screen.dart';
import 'package:snapgrub/features/home/presentation/home_screen.dart';
import 'package:snapgrub/features/journal/presentation/journal_screen.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_editor/presentation/meal_editor_screen.dart';
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
  final auth = ref.watch(authControllerProvider);
  final profile = ref.watch(profileControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
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
      GoRoute(
        path: '/home',
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
          if (asset is! CaptureAsset) return const HomeScreen();
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
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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
        path: '/sync',
        builder: (context, state) => const SyncStatusScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final authState = auth.valueOrNull;
      if (auth.isLoading || authState == null || profile.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      if (authState.status == AuthStatus.configurationMissing ||
          authState.status == AuthStatus.signedOut) {
        return location == '/auth' ? null : '/auth';
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

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
