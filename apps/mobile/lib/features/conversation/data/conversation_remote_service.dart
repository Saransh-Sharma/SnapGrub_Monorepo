import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final conversationRemoteServiceProvider =
    Provider<ConversationRemoteService>((ref) {
  final config = ref.watch(appConfigProvider);
  return ConversationRemoteService(
    client: ref.watch(supabaseClientProvider),
    anonKey: config.supabaseAnonKey,
    supabaseUrl: config.supabaseUrl,
    e2eMock: config.isE2eMock,
  );
});

class ConversationRemoteService {
  const ConversationRemoteService({
    required SupabaseClient? client,
    required String anonKey,
    required String supabaseUrl,
    required this.e2eMock,
  })  : _client = client,
        _anonKey = anonKey,
        _supabaseUrl = supabaseUrl;

  final SupabaseClient? _client;
  final String _anonKey;
  final String _supabaseUrl;
  final bool e2eMock;

  bool get isConfigured =>
      _client != null && _anonKey.isNotEmpty && _supabaseUrl.startsWith('http');

  Stream<AgentStreamEvent> run({
    required DailyThread thread,
    required String clientRequestId,
    required String message,
    required String locale,
    required List<String> cuisineHints,
  }) async* {
    final client = _client;
    final token = client?.auth.currentSession?.accessToken;
    if (client == null || token == null || _anonKey.isEmpty) {
      throw StateError('The assistant isn’t available right now.');
    }
    final request = http.Request(
      'POST',
      Uri.parse('$_supabaseUrl/functions/v1/agent-runs'),
    )
      ..headers.addAll({
        'authorization': 'Bearer $token',
        'apikey': _anonKey,
        'content-type': 'application/json',
        'accept': 'text/event-stream',
      })
      ..body = jsonEncode({
        'client_request_id': clientRequestId,
        'thread_id': thread.id,
        'day': _dateOnly(thread.day),
        'timezone': thread.timezone,
        'locale': locale,
        'cuisine_hints': cuisineHints,
        'message': message,
      });

    final response = await http.Client().send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw StateError(_friendlyError(body));
    }
    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      yield AgentStreamEvent.fromJson(
        Map<String, dynamic>.from(jsonDecode(payload) as Map),
      );
    }
  }

  Future<void> acknowledge({
    required String proposalId,
    required ProposalStatus status,
    required String clientRequestId,
  }) async {
    final client = _client;
    final token = client?.auth.currentSession?.accessToken;
    if (client == null || token == null || _anonKey.isEmpty) {
      throw StateError('The assistant isn’t available right now.');
    }
    final response = await http.post(
      Uri.parse(
        '$_supabaseUrl/functions/v1/agent-proposals/$proposalId/acknowledge',
      ),
      headers: {
        'authorization': 'Bearer $token',
        'apikey': _anonKey,
        'content-type': 'application/json',
        'idempotency-key': clientRequestId,
      },
      body: jsonEncode({
        'action': switch (status) {
          ProposalStatus.confirmed => 'confirm',
          ProposalStatus.edited => 'edit',
          ProposalStatus.rejected => 'reject',
          ProposalStatus.undone => 'undo',
          _ => status.name,
        },
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_friendlyError(response.body));
    }
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _friendlyError(String body) {
    try {
      final json = jsonDecode(body) as Map;
      return json['user_message'] as String? ??
          'Couldn’t finish that. Your message is still here.';
    } catch (_) {
      return 'Couldn’t finish that. Your message is still here.';
    }
  }
}
