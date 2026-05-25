import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_function_client.dart';

final eventsRemoteServiceProvider = Provider<EventsRemoteService>((ref) {
  return EventsRemoteService(ref.watch(supabaseFunctionClientProvider));
});

class EventsRemoteService {
  const EventsRemoteService(this._functions);

  final SnapGrubFunctionClient _functions;

  bool get isConfigured => _functions.isConfigured;

  Future<void> ingest(List<Map<String, Object?>> events,
      {String? clientRequestId}) async {
    if (!_functions.isConfigured || events.isEmpty) return;
    await _functions.invokeJson(
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
