import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/auth/presentation/auth_screen.dart';
import 'package:snapgrub/features/home/presentation/home_screen.dart';
import 'package:snapgrub/features/journal/presentation/journal_screen.dart';
import 'package:snapgrub/features/meal_editor/presentation/meal_editor_screen.dart';
import 'package:snapgrub/features/onboarding/presentation/onboarding_flow_screen.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/profile/presentation/settings_screen.dart';

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
        builder: (context, state) => MealEditorScreen(mealId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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

      if (location == '/splash' || location == '/auth' || location == '/onboarding') {
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
