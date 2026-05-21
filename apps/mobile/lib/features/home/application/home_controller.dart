import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

final homeUserContextProvider = FutureProvider<HomeUserContext?>((ref) async {
  final auth = await ref.watch(authControllerProvider.future);
  if (auth.status != AuthStatus.signedIn || auth.userId == null) return null;
  final profile = await ref.watch(profileControllerProvider.future);
  return HomeUserContext(
    userId: auth.userId!,
    timezone: profile.profile?.timezone ?? 'UTC',
    calorieGoal: profile.activeGoal?.caloriesKcal,
    proteinGoal: profile.activeGoal?.proteinG,
    carbsGoal: profile.activeGoal?.carbsG,
    fatGoal: profile.activeGoal?.fatG,
    weeklyInsightsEnabled: profile.featureFlags['weekly_insights.enabled'] == true,
  );
});

final todayMealsProvider = StreamProvider<List<Meal>>((ref) async* {
  final context = await ref.watch(homeUserContextProvider.future);
  if (context == null) {
    yield const [];
    return;
  }
  yield* ref.watch(mealRepositoryProvider).watchMealsForDay(context.userId, DateTime.now());
});

final todayRollupProvider = StreamProvider<DailyRollup>((ref) async* {
  final context = await ref.watch(homeUserContextProvider.future);
  if (context == null) return;
  yield* ref.watch(mealRepositoryProvider).watchRollup(context.userId, DateTime.now());
});

class HomeUserContext {
  const HomeUserContext({
    required this.userId,
    required this.timezone,
    this.calorieGoal,
    this.proteinGoal,
    this.carbsGoal,
    this.fatGoal,
    this.weeklyInsightsEnabled = false,
  });

  final String userId;
  final String timezone;
  final double? calorieGoal;
  final double? proteinGoal;
  final double? carbsGoal;
  final double? fatGoal;
  final bool weeklyInsightsEnabled;
}
