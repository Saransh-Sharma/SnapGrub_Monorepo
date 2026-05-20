import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/events_remote_service.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(eventsRemoteServiceProvider));
});

class AnalyticsRepository {
  const AnalyticsRepository(this._remote);

  final EventsRemoteService _remote;

  Future<void> track(String eventName, {Map<String, Object?> properties = const {}}) async {
    await _remote.ingest([
      {
        'event_name': eventName,
        'properties': properties,
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
      },
    ]);
  }
}
