import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabaseConfig) return null;
  return Supabase.instance.client;
});
