import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/features/conversation/data/conversation_remote_service.dart';
import 'package:snapgrub/features/conversation/data/conversation_repository.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';

void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late ConversationRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    repository = ConversationRepository(
      db: db,
      outbox: outbox,
      remote: const ConversationRemoteService(
        client: null,
        anonKey: '',
        supabaseUrl: '',
        e2eMock: true,
      ),
    );
  });

  tearDown(() => db.close());

  test('queued user message and proposal persist without remote state',
      () async {
    final thread = await repository.ensureThread(
      userId: 'user-1',
      day: DateTime(2026, 7, 14, 18),
      timezone: 'Asia/Kolkata',
    );
    final message = await repository.addMessage(
      thread: thread,
      role: ThreadMessageRole.user,
      kind: ThreadMessageKind.text,
      text: 'Two eggs and toast',
      deliveryState: MessageDeliveryState.pending,
    );
    await repository.stageProposal(
      thread: thread,
      messageId: message.id,
      draft: MealDraft(
        userId: 'user-1',
        timezone: 'Asia/Kolkata',
        title: 'Eggs and toast',
        items: [
          MealDraftItem(name: 'Eggs', quantity: 2, unit: 'pieces'),
        ],
      ),
    );

    final messages = await repository.watchMessages(thread.id).first;
    final proposals = await repository.watchProposals(thread.id).first;
    final commands = await outbox.pendingCommands(
      userId: 'user-1',
      commandTypes: const ['thread.message.create'],
    );

    expect(thread.day, DateTime(2026, 7, 14));
    expect(messages.single.deliveryState, MessageDeliveryState.pending);
    expect(proposals.single.draft.title, 'Eggs and toast');
    expect(commands.single.clientRequestId, message.clientId);
  });

  test('delivered message closes its matching outbox command', () async {
    final thread = await repository.ensureThread(
      userId: 'user-1',
      day: DateTime(2026, 7, 14),
      timezone: 'UTC',
    );
    final message = await repository.addMessage(
      thread: thread,
      role: ThreadMessageRole.user,
      kind: ThreadMessageKind.text,
      text: 'Coffee',
      deliveryState: MessageDeliveryState.pending,
    );

    await repository.markMessageDelivered(message);

    expect(await outbox.pendingCount('user-1'), 0);
    expect(
      (await repository.watchMessages(thread.id).first).single.deliveryState,
      MessageDeliveryState.delivered,
    );
  });
}
