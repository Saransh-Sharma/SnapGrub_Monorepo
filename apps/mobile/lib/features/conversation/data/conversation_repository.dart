import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';
import 'package:snapgrub/features/conversation/data/conversation_remote_service.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:uuid/uuid.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository(
    db: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxRepositoryProvider),
    remote: ref.watch(conversationRemoteServiceProvider),
  );
});

class ConversationRepository {
  ConversationRepository(
      {required AppDatabase db,
      required OutboxRepository outbox,
      required ConversationRemoteService remote})
      : _db = db,
        _outbox = outbox,
        _remote = remote;

  final AppDatabase _db;
  final OutboxRepository _outbox;
  final ConversationRemoteService _remote;

  Future<DailyThread> ensureThread({
    required String userId,
    required DateTime day,
    required String timezone,
  }) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final existing = await (_db.select(_db.dailyThreadsLocal)
          ..where(
              (row) => row.userId.equals(userId) & row.day.equals(normalized)))
        .getSingleOrNull();
    if (existing != null) return _threadFromRow(existing);
    final id = const Uuid().v4();
    await _db.into(_db.dailyThreadsLocal).insert(
          DailyThreadsLocalCompanion.insert(
            id: id,
            userId: userId,
            day: normalized,
            timezone: timezone,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final row = await (_db.select(_db.dailyThreadsLocal)
          ..where((item) =>
              item.userId.equals(userId) & item.day.equals(normalized)))
        .getSingle();
    return _threadFromRow(row);
  }

  Stream<List<ThreadMessage>> watchMessages(String threadId) {
    final query = _db.select(_db.threadMessagesLocal)
      ..where((row) => row.threadId.equals(threadId))
      ..orderBy([(row) => OrderingTerm.asc(row.sequence)]);
    return query.watch().map(
          (rows) => rows
              .map((row) => ThreadMessage(
                    id: row.id,
                    threadId: row.threadId,
                    userId: row.userId,
                    clientId: row.clientId,
                    role: ThreadMessageRole.values.byName(row.role),
                    kind: ThreadMessageKind.values.byName(row.kind),
                    text: row.textContent,
                    payload: Map<String, Object?>.from(
                        jsonDecode(row.payloadJson) as Map? ?? const {}),
                    sequence: row.sequence,
                    deliveryState:
                        MessageDeliveryState.values.byName(row.deliveryState),
                    createdAt: row.createdAt,
                  ))
              .toList(),
        );
  }

  Stream<List<MealChangeProposal>> watchProposals(String threadId) {
    final query = _db.select(_db.mealChangeProposalsLocal)
      ..where((row) => row.threadId.equals(threadId))
      ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]);
    return query.watch().map(
          (rows) => rows
              .map((row) => MealChangeProposal(
                    id: row.id,
                    threadId: row.threadId,
                    userId: row.userId,
                    messageId: row.messageId,
                    operation: ProposalOperation.values.byName(row.operation),
                    targetMealId: row.targetMealId,
                    expectedRevision: row.expectedRevision,
                    draft: decodeDraft(row.draftJson),
                    status: ProposalStatus.values.byName(row.status),
                    createdAt: row.createdAt,
                  ))
              .toList(),
        );
  }

  Future<ThreadMessage> addMessage({
    required DailyThread thread,
    required ThreadMessageRole role,
    required ThreadMessageKind kind,
    String? text,
    Map<String, Object?> payload = const {},
    MessageDeliveryState deliveryState = MessageDeliveryState.delivered,
    String? id,
    String? clientId,
  }) async {
    final messageId = id ?? const Uuid().v4();
    final messageClientId = clientId ?? const Uuid().v4();
    final sequence = await _nextSequence(thread.id);
    final now = DateTime.now().toUtc();
    await _db.into(_db.threadMessagesLocal).insert(
          ThreadMessagesLocalCompanion.insert(
            id: messageId,
            threadId: thread.id,
            userId: thread.userId,
            clientId: messageClientId,
            role: role.name,
            kind: Value(kind.name),
            textContent: Value(text),
            payloadJson: Value(jsonEncode(payload)),
            sequence: sequence,
            deliveryState: Value(deliveryState.name),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    if (role == ThreadMessageRole.user) {
      await _outbox.enqueue(
        userId: thread.userId,
        commandType: 'thread.message.create',
        payload: {
          'thread_id': thread.id,
          'message_id': messageId,
          'client_id': messageClientId,
          'role': role.name,
          'kind': kind.name,
          'text': text,
          'payload': payload,
          'sequence': sequence,
          'created_at': now.toIso8601String(),
        },
        clientRequestId: messageClientId,
      );
    }
    return ThreadMessage(
      id: messageId,
      threadId: thread.id,
      userId: thread.userId,
      clientId: messageClientId,
      role: role,
      kind: kind,
      text: text,
      payload: payload,
      sequence: sequence,
      deliveryState: deliveryState,
      createdAt: now,
    );
  }

  Future<MealChangeProposal> stageProposal({
    required DailyThread thread,
    required MealDraft draft,
    ProposalOperation operation = ProposalOperation.create,
    String? messageId,
    String? targetMealId,
    int? expectedRevision,
    String? id,
  }) async {
    final proposalId = id ?? const Uuid().v4();
    final now = DateTime.now().toUtc();
    await _db.into(_db.mealChangeProposalsLocal).insertOnConflictUpdate(
          MealChangeProposalsLocalCompanion.insert(
            id: proposalId,
            threadId: thread.id,
            userId: thread.userId,
            messageId: Value(messageId),
            operation: operation.name,
            targetMealId: Value(targetMealId),
            expectedRevision: Value(expectedRevision),
            draftJson: encodeDraft(draft),
            status: const Value('pending'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return MealChangeProposal(
      id: proposalId,
      threadId: thread.id,
      userId: thread.userId,
      messageId: messageId,
      operation: operation,
      targetMealId: targetMealId,
      expectedRevision: expectedRevision,
      draft: draft,
      status: ProposalStatus.pending,
      createdAt: now,
    );
  }

  Future<void> setProposalStatus(
    MealChangeProposal proposal,
    ProposalStatus status,
  ) async {
    await (_db.update(_db.mealChangeProposalsLocal)
          ..where((row) => row.id.equals(proposal.id)))
        .write(
      MealChangeProposalsLocalCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    final clientRequestId = const Uuid().v4();
    await _outbox.enqueue(
      userId: proposal.userId,
      commandType: 'agent.proposal.acknowledge',
      payload: {'proposal_id': proposal.id, 'status': status.name},
      clientRequestId: clientRequestId,
    );
  }

  Future<void> markMessageDelivered(ThreadMessage message) async {
    await (_db.update(_db.threadMessagesLocal)
          ..where((row) => row.id.equals(message.id)))
        .write(
      ThreadMessagesLocalCompanion(
        deliveryState: const Value('delivered'),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _outbox.markClientRequestSynced(message.clientId);
  }

  Future<void> drainOutbox(String userId) async {
    if (!_remote.isConfigured) return;
    final commands = await _outbox.pendingCommands(
      userId: userId,
      commandTypes: const [
        'thread.message.create',
        'agent.proposal.acknowledge',
      ],
    );
    for (final command in commands) {
      try {
        final payload =
            Map<String, dynamic>.from(jsonDecode(command.payloadJson) as Map);
        if (command.commandType == 'agent.proposal.acknowledge') {
          final status =
              ProposalStatus.values.byName(payload['status'] as String);
          await _remote.acknowledge(
            proposalId: payload['proposal_id'] as String,
            status: status,
            clientRequestId: command.clientRequestId,
          );
        } else {
          await _replayQueuedMessage(payload, command.clientRequestId);
        }
        await _outbox.markSynced(command.id);
      } catch (error) {
        await _outbox.markFailed(command.id, error: error);
      }
    }
  }

  Future<void> _replayQueuedMessage(
    Map<String, dynamic> payload,
    String clientRequestId,
  ) async {
    final threadRow = await (_db.select(_db.dailyThreadsLocal)
          ..where((row) => row.id.equals(payload['thread_id'] as String)))
        .getSingle();
    final thread = _threadFromRow(threadRow);
    var assistantText = '';
    MealDraft? draft;
    String? proposalId;
    var operation = ProposalOperation.create;
    String? targetMealId;
    int? expectedRevision;
    await for (final event in _remote.run(
      thread: thread,
      clientRequestId: clientRequestId,
      message: payload['text'] as String? ?? '',
      locale: 'en',
      cuisineHints: const [],
    )) {
      if (event.event == 'assistant.delta') {
        assistantText += event.data['text'] as String? ?? '';
      } else if (event.event == 'proposal.ready') {
        final rawDraft = event.data['draft'];
        if (rawDraft is Map) {
          draft = mealDraftFromJson(Map<String, dynamic>.from(rawDraft));
        }
        proposalId = event.data['proposal_id'] as String?;
        final operationName = event.data['operation'] as String?;
        if (operationName != null) {
          operation = ProposalOperation.values.byName(operationName);
        }
        targetMealId = event.data['target_meal_id'] as String?;
        expectedRevision = (event.data['expected_revision'] as num?)?.toInt();
      } else if (event.event == 'run.failed') {
        throw StateError(
            event.data['message'] as String? ?? 'Couldn’t finish that.');
      }
    }
    final message = await addMessage(
      thread: thread,
      role: ThreadMessageRole.assistant,
      kind: ThreadMessageKind.text,
      text: assistantText.trim().isEmpty
          ? 'Here’s a meal to review.'
          : assistantText.trim(),
    );
    if (draft != null) {
      await stageProposal(
        thread: thread,
        draft: draft,
        messageId: message.id,
        id: proposalId,
        operation: operation,
        targetMealId: targetMealId,
        expectedRevision: expectedRevision,
      );
    }
    await (_db.update(_db.threadMessagesLocal)
          ..where((row) => row.id.equals(payload['message_id'] as String)))
        .write(
      ThreadMessagesLocalCompanion(
        deliveryState: const Value('delivered'),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<int> _nextSequence(String threadId) async {
    final sequence = _db.threadMessagesLocal.sequence.max();
    final row = await (_db.selectOnly(_db.threadMessagesLocal)
          ..addColumns([sequence])
          ..where(_db.threadMessagesLocal.threadId.equals(threadId)))
        .getSingle();
    return (row.read(sequence) ?? 0) + 1;
  }

  DailyThread _threadFromRow(DailyThreadsLocalData row) => DailyThread(
        id: row.id,
        userId: row.userId,
        day: row.day,
        timezone: row.timezone,
      );
}
