import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';

final eventsRemoteServiceProvider = Provider<EventsRemoteService>((ref) {
  return EventsRemoteService(ref.watch(supabaseClientProvider));
});

class EventsRemoteService {
  const EventsRemoteService(this._client);

  final dynamic _client;

  bool get isConfigured => _client != null;

  Future<void> ingest(List<Map<String, Object?>> events,
      {String? clientRequestId}) async {
    if (_client == null || events.isEmpty) return;
    await _client.functions.invoke(
      'events-ingest',
      headers:
          clientRequestId == null ? null : {'Idempotency-Key': clientRequestId},
      body: {
        if (clientRequestId != null) 'client_request_id': clientRequestId,
        'events': events,
      },
    );
  }
}
