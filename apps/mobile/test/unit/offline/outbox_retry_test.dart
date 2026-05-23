import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';

void main() {
  test('retryable outbox failures eventually become terminal', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final outbox = OutboxRepository(db);

    await outbox.enqueue(
      userId: 'user-a',
      commandType: 'settings.patch',
      payload: const {'value': true},
      clientRequestId: 'request-a',
    );

    var command = (await db.select(db.outboxCommands).get()).single;
    for (var i = 0; i < OutboxRepository.maxRetryCount; i++) {
      await outbox.markFailed(command.id, retryable: true, error: 'network');
      command = (await db.select(db.outboxCommands).get()).single;
    }

    expect(command.status, 'failed');
    expect(command.nextRetryAt, isNull);
  });
}
