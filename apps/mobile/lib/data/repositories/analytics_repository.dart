import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/events_remote_service.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:uuid/uuid.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(
    remote: ref.watch(eventsRemoteServiceProvider),
    outbox: ref.watch(outboxRepositoryProvider),
    ref: ref,
  );
});

class AnalyticsRepository {
  const AnalyticsRepository({
    required EventsRemoteService remote,
    required OutboxRepository outbox,
    required Ref ref,
  })  : _remote = remote,
        _outbox = outbox,
        _ref = ref;

  final EventsRemoteService _remote;
  final OutboxRepository _outbox;
  final Ref _ref;

  Future<void> track(String eventName,
      {Map<String, Object?> properties = const {}}) async {
    final event = {
      'event_name': eventName,
      'properties': properties,
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    };
    final clientRequestId = const Uuid().v4();
    try {
      await _remote.ingest([event], clientRequestId: clientRequestId);
    } catch (_) {
      final auth = _ref.read(authControllerProvider).valueOrNull;
      if (auth?.status == AuthStatus.signedIn && auth?.userId != null) {
        await _outbox.enqueue(
          userId: auth!.userId!,
          commandType: 'analytics.batch',
          payload: {
            'events': [event]
          },
          clientRequestId: clientRequestId,
        );
      }
    }
  }
}
