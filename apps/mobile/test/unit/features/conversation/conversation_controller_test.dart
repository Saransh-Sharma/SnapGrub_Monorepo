import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/conversation/application/conversation_controller.dart';
import 'package:snapgrub/features/conversation/data/conversation_remote_service.dart';
import 'package:snapgrub/features/conversation/data/conversation_repository.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';

import '../../../helpers/mobile_test_harness.dart';

/// Replays a fixed set of stream events instead of calling the backend.
class _ScriptedRemote extends ConversationRemoteService {
  const _ScriptedRemote(this.events)
      : super(client: null, anonKey: '', supabaseUrl: '', e2eMock: false);

  final List<AgentStreamEvent> events;

  @override
  bool get isConfigured => true;

  @override
  Stream<AgentStreamEvent> run({
    required DailyThread thread,
    required String clientRequestId,
    required String message,
    required String locale,
    required List<String> cuisineHints,
  }) =>
      Stream.fromIterable(events);
}

AgentStreamEvent _proposal({
  required DateTime loggedAt,
  required String operation,
  String? targetMealId,
}) {
  final draft = testMealDraft(title: 'Breakfast')..loggedAt = loggedAt;
  return AgentStreamEvent(
    event: 'proposal.ready',
    runId: 'run-1',
    sequence: 1,
    data: {
      'proposal_id': 'proposal-$operation',
      'draft': mealDraftToJson(draft),
      'operation': operation,
      'target_meal_id': targetMealId,
      'expected_revision': targetMealId == null ? null : 2,
    },
  );
}

Future<MealChangeProposal> _send(AgentStreamEvent event) async {
  final harness = await MobileTestHarness.create(
    overrides: [
      conversationRemoteServiceProvider
          .overrideWithValue(_ScriptedRemote([event])),
    ],
  );
  addTearDown(harness.dispose);
  final day = DateTime(2026, 5, 30);
  await harness.container
      .read(conversationControllerProvider.notifier)
      .sendMessage(day, 'add curd to breakfast');
  final repository = harness.container.read(conversationRepositoryProvider);
  final thread = await repository.ensureThread(
    userId: testUserId,
    day: day,
    timezone: testTimezone,
  );
  return (await repository.watchProposals(thread.id).first).single;
}

void main() {
  // The controller fires a haptic tick, which needs the services binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a chat update keeps the time the meal was logged at', () async {
    final original = DateTime.utc(2026, 5, 30, 3, 15);

    final proposal = await _send(_proposal(
      loggedAt: original,
      operation: 'update',
      targetMealId: 'meal-1',
    ));

    expect(proposal.operation, ProposalOperation.update);
    expect(proposal.targetMealId, 'meal-1');
    expect(proposal.draft.loggedAt.isAtSameMomentAs(original), isTrue);
  });

  test('a new meal from chat is placed on the open day', () async {
    final proposal = await _send(_proposal(
      loggedAt: DateTime.utc(2026, 1, 1, 12),
      operation: 'create',
    ));

    expect(proposal.operation, ProposalOperation.create);
    final placed = proposal.draft.loggedAt.toLocal();
    expect((placed.year, placed.month, placed.day), (2026, 5, 30));
  });
}
