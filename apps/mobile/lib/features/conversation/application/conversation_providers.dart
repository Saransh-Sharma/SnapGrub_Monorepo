import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/conversation/data/conversation_repository.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';

final dailyThreadProvider =
    FutureProvider.family<DailyThread?, DateTime>((ref, day) async {
  final user = await ref.watch(homeUserContextProvider.future);
  if (user == null) return null;
  return ref.watch(conversationRepositoryProvider).ensureThread(
        userId: user.userId,
        day: day,
        timezone: user.timezone,
      );
});

final threadMessagesProvider =
    StreamProvider.family<List<ThreadMessage>, DateTime>((ref, day) async* {
  final thread = await ref.watch(dailyThreadProvider(day).future);
  if (thread == null) {
    yield const [];
    return;
  }
  yield* ref.watch(conversationRepositoryProvider).watchMessages(thread.id);
});

final threadProposalsProvider =
    StreamProvider.family<List<MealChangeProposal>, DateTime>(
        (ref, day) async* {
  final thread = await ref.watch(dailyThreadProvider(day).future);
  if (thread == null) {
    yield const [];
    return;
  }
  yield* ref.watch(conversationRepositoryProvider).watchProposals(thread.id);
});
