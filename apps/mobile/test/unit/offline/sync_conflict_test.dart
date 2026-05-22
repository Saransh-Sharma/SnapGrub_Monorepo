import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';

void main() {
  test('conflict commands are visible, retryable, and discardable', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final outbox = OutboxRepository(db);

    await outbox.enqueue(
      userId: 'user-a',
      commandType: 'meal.update',
      clientRequestId: 'request-a',
      payload: {'meal_id': 'meal-a'},
    );

    final command = (await db.select(db.outboxCommands).get()).single;
    await outbox.markConflict(command.id, StateError('409 revision conflict'));

    expect(await outbox.hasConflict('user-a'), isTrue);
    expect(await outbox.conflictCommands('user-a'), hasLength(1));

    await outbox.retryCommand(command.id);
    expect(await outbox.hasConflict('user-a'), isFalse);
    expect((await db.select(db.outboxCommands).getSingle()).status, 'pending');

    await outbox.markConflict(command.id, StateError('409 revision conflict'));
    await outbox.discardCommand(command.id);
    expect((await db.select(db.outboxCommands).getSingle()).status, 'synced');
  });
}
